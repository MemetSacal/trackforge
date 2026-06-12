from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.domain.entities.user import User
from backend.app.domain.interfaces.i_user_repository import IUserRepository
from backend.app.infrastructure.db.models.user_model import UserModel


class UserRepository(IUserRepository):
    # IUserRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu
    # Spring'deki @Repository ile aynı mantık

    def __init__(self, session: AsyncSession):
        # SQLAlchemy session dışarıdan inject edilir — dependency injection
        self.session = session

    async def create(self, user: User) -> User:
        db_user = UserModel(
            id=user.id,
            email=user.email,
            password_hash=user.password_hash,
            full_name=user.full_name,
            created_at=user.created_at,
            updated_at=user.updated_at,
        )
        self.session.add(db_user)
        await self.session.flush()  # flush DB'ye yazar ama commit etmez
        return self._to_entity(db_user)

    async def get_by_id(self, user_id: str) -> User | None:
        # SELECT * FROM users WHERE id = ?
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        db_user = result.scalar_one_or_none()
        return self._to_entity(db_user) if db_user else None

    async def get_by_email(self, email: str) -> User | None:
        # SELECT * FROM users WHERE email = ?
        result = await self.session.execute(
            select(UserModel).where(UserModel.email == email)
        )
        db_user = result.scalar_one_or_none()
        return self._to_entity(db_user) if db_user else None

    async def update(self, user: User) -> User:
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user.id)
        )
        db_user = result.scalar_one_or_none()
        if not db_user:
            return None
        db_user.email = user.email
        db_user.full_name = user.full_name
        db_user.updated_at = user.updated_at
        await self.session.flush()
        return self._to_entity(db_user)

    async def bump_token_version(self, user_id: str) -> None:
        """v3: Tüm aktif refresh token'ları geçersizleştirir (logout / şifre değişimi).
        Access token zaten 15 dk ömürlü — refresh ölünce oturum biter."""
        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        db_user = result.scalar_one_or_none()
        if db_user:
            db_user.token_version = (db_user.token_version or 0) + 1
            await self.session.flush()

    async def delete(self, user_id: str) -> bool:
        """v3: Hesap silme (Play Store zorunluluğu + KVKK).
        UserModel ilişkileri cascade='all, delete-orphan' — ORM bağlı kayıtları
        otomatik siler. İlişki olarak tanımlanmamış AI tabloları (ai_usage_logs,
        ai_feedback, ai_response_cache) açıkça temizlenir."""
        from sqlalchemy import delete as sa_delete
        from backend.app.infrastructure.db.models.ai_usage_model import AIUsageModel
        from backend.app.infrastructure.db.models.ai_feedback_model import AIFeedbackModel
        from backend.app.infrastructure.db.models.ai_cache_model import AIResponseCacheModel

        result = await self.session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        db_user = result.scalar_one_or_none()
        if not db_user:
            return False

        for model in (AIUsageModel, AIFeedbackModel, AIResponseCacheModel):
            await self.session.execute(
                sa_delete(model).where(model.user_id == user_id)
            )

        await self.session.delete(db_user)  # cascade ilişkili tüm verileri götürür
        await self.session.flush()
        return True

    def _to_entity(self, db_user: UserModel) -> User:
        # UserModel (SQLAlchemy) → User (domain entity) dönüşümü
        # Servis katmanı SQLAlchemy'yi hiç görmez, sadece User entity'si görür
        return User(
            id=db_user.id,
            email=db_user.email,
            password_hash=db_user.password_hash,
            full_name=db_user.full_name,
            created_at=db_user.created_at,
            updated_at=db_user.updated_at,
            token_version=getattr(db_user, 'token_version', 0),
        )

"""
_to_entity methodu kodun en kritik kısmı çünkü mappingi burada yapıyoruz
`UserModel` SQLAlchemy'ye bağlı, `User` ise saf Python.
Bu method ikisi arasında köprü kuruyor. 
Servis katmanı hiçbir zaman `UserModel` görmeyecek, sadece `User` görecek. Clean Architecture'ın kalbi burası.
---

**Özet akış:**

DB → UserModel → _to_entity() → User → Servis katmanı
Servis katmanı → User → create() → UserModel → DB
"""