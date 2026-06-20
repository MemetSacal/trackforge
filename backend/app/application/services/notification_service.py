"""Push notification gönderimi — Firebase Cloud Messaging (FCM) üzerinden.

Firebase kurulumu:
1. console.firebase.google.com'da proje oluştur
2. Project Settings > Service Accounts > Generate new private key
   ile inen JSON dosyasının İÇERİĞİNİ Render > Environment Variables >
   FIREBASE_CREDENTIALS_JSON'a yapıştır (dosya yolu değil, JSON metni)
3. Android app ekle, paket adı: com.memetsacal.trackforge
4. google-services.json'ı Flutter tarafına yerleştir (bu backend'i ilgilendirmez)

FIREBASE_CREDENTIALS_JSON tanımlı değilse FCM gönderimi sessizce atlanır
(geliştirme ortamı için) — ama in-app bildirim kaydı YİNE DE oluşturulur.
Bu sayede local'de Firebase olmadan da bildirim sistemi test edilebilir.
"""
import json
import logging
from typing import Optional, Dict, Any, List

import firebase_admin
from firebase_admin import credentials, messaging

from backend.app.core.config import get_settings
from backend.app.domain.entities.notification import Notification
from backend.app.infrastructure.repositories.device_token_repository import DeviceTokenRepository
from backend.app.infrastructure.repositories.notification_repository import NotificationRepository
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

_firebase_app: Optional[firebase_admin.App] = None
_firebase_init_attempted = False


def _get_firebase_app() -> Optional[firebase_admin.App]:
    """Firebase Admin SDK'yı lazy + tek seferlik initialize eder.

    İlk çağrıda credential'ları okuyup app'i kurar, sonraki çağrılarda
    aynı app örneğini döner (Settings'teki @lru_cache mantığıyla aynı amaç).
    """
    global _firebase_app, _firebase_init_attempted

    if _firebase_app is not None:
        return _firebase_app

    if _firebase_init_attempted:
        # Daha önce denenmiş ve başarısız olmuş (örn. key yok) — tekrar deneme
        return None

    _firebase_init_attempted = True
    cfg = get_settings()

    if not cfg.FIREBASE_CREDENTIALS_JSON:
        logger.warning(
            "FIREBASE_CREDENTIALS_JSON tanımlı değil. Push bildirimleri "
            "gönderilmeyecek (in-app kayıt yine de oluşturulacak)."
        )
        return None

    try:
        cred_dict = json.loads(cfg.FIREBASE_CREDENTIALS_JSON)
        cred = credentials.Certificate(cred_dict)
        _firebase_app = firebase_admin.initialize_app(cred)
        logger.info("Firebase Admin SDK başlatıldı.")
        return _firebase_app
    except Exception as exc:
        logger.exception("Firebase Admin SDK başlatılamadı: %s", exc)
        return None


class NotificationService:
    """Bildirim gönderiminin tek giriş noktası.

    Route'lar doğrudan firebase_admin çağırmaz — hepsi bu servisten geçer.
    Her gönderim HEM FCM push'u dener HEM DE in-app geçmiş tablosuna
    (notifications) bir satır ekler. Push başarısız olsa bile (kullanıcının
    aktif cihazı yoksa, Firebase kurulu değilse vb.) in-app kayıt oluşur —
    kullanıcı bildirimi en azından uygulama içinde görür.

    TODO (v1 sonrası): Rate limiting. Aynı kullanıcıya kısa sürede çok
    sayıda bildirim gitmesini engellemek için burada (ai_rate_limiter.py
    pattern'ine benzer şekilde) bir limiter eklenebilir. Şu an yok —
    çağıran kod (örn. friend request route'u) zaten doğal olarak
    sık tetiklenmiyor, ama AI/streak gibi otomatik tetiklenen akışlar
    büyüdükçe bu önem kazanacak.
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.token_repo = DeviceTokenRepository(db)
        self.notif_repo = NotificationRepository(db)

    # ── Tek kullanıcıya gönder ──
    async def send_to_user(
        self,
        user_id: str,
        title: str,
        body: str,
        type: str = "system",
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        # 1) In-app geçmiş kaydı — HER ZAMAN oluşturulur (push başarısız olsa bile)
        notification = await self.notif_repo.create(
            user_id=user_id, title=title, body=body, type=type, data=data
        )

        # 2) FCM push dene
        tokens = await self.token_repo.get_active_tokens(user_id)
        if tokens:
            await self._send_fcm(tokens, title, body, type, data)

        await self.db.commit()
        return notification

    # ── Birden çok kullanıcıya gönder ──
    async def send_to_users(
        self,
        user_ids: List[str],
        title: str,
        body: str,
        type: str = "system",
        data: Optional[Dict[str, Any]] = None,
    ) -> List[Notification]:
        notifications = []
        for uid in user_ids:
            notif = await self.notif_repo.create(
                user_id=uid, title=title, body=body, type=type, data=data
            )
            notifications.append(notif)

        tokens = await self.token_repo.get_active_tokens_for_users(user_ids)
        if tokens:
            await self._send_fcm(tokens, title, body, type, data)

        await self.db.commit()
        return notifications

    # ── Topic'e gönder (v1'de KULLANILMIYOR — iskelet olarak duruyor) ──
    async def send_to_topic(
        self,
        topic: str,
        title: str,
        body: str,
        type: str = "system",
        data: Optional[Dict[str, Any]] = None,
    ) -> bool:
        """İleride premium/free/beta gibi segmentlere toplu duyuru için.

        v1 kapsamında kullanılmıyor (kullanıcı sayısı henüz topic
        segmentasyonunu gerektirmiyor). Subscribe/unsubscribe akışı
        eklenmeden bu metodun pratik bir karşılığı olmaz.
        """
        app = _get_firebase_app()
        if not app:
            logger.warning("Firebase kurulu değil, topic mesajı atlandı.")
            return False

        payload = {"type": type, **{k: str(v) for k, v in (data or {}).items()}}
        try:
            message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                data=payload,
                topic=topic,
            )
            messaging.send(message, app=app)
            return True
        except Exception as exc:
            logger.exception("Topic mesajı gönderilemedi: %s", exc)
            return False

    # ── Dahili: FCM gönderimi (çoklu token, hatalı token temizliği) ──
    async def _send_fcm(
        self,
        tokens,
        title: str,
        body: str,
        type: str,
        data: Optional[Dict[str, Any]],
    ) -> None:
        app = _get_firebase_app()
        if not app:
            return  # Firebase kurulu değil — sessizce atla, in-app kayıt zaten oluştu

        # Data payload'daki tüm değerler FCM gereği STRING olmalı
        payload = {"type": type}
        if data:
            payload.update({k: str(v) for k, v in data.items()})

        for dt in tokens:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(title=title, body=body),
                    data=payload,
                    token=dt.fcm_token,
                )
                messaging.send(message, app=app)
            except messaging.UnregisteredError:
                # Token artık geçersiz (uygulama silinmiş vb.) — deaktive et
                await self.token_repo.deactivate_by_token_value(dt.fcm_token)
            except Exception as exc:
                # Tek bir token'ın başarısız olması diğerlerini engellemez
                logger.warning("FCM gönderimi başarısız (token=%s...): %s", dt.fcm_token[:12], exc)


"""
DOSYA AKIŞI:
NotificationService bildirim göndermenin TEK giriş noktasıdır.
Route'lar (örn. social.py'deki arkadaşlık isteği endpoint'i) doğrudan
firebase_admin çağırmaz, bu servisi çağırır:

    notif_service = NotificationService(db)
    await notif_service.send_to_user(
        user_id=addressee_id,
        title="Yeni arkadaşlık isteği",
        body=f"{requester_name} sana arkadaşlık isteği gönderdi",
        type="friend_request",
        data={"request_id": friendship.id, "requester_id": requester_id},
    )

_get_firebase_app(): modül seviyesinde tek bir Firebase App örneği tutar
(global + lazy init). FastAPI'de her request yeni bir NotificationService
örneği oluşturuyor ama Firebase SDK'yı her seferinde yeniden initialize
etmek hem gereksiz hem de firebase_admin zaten "zaten initialize edilmiş"
hatası fırlatır — bu yüzden modül seviyesinde cache'leniyor.

Spring Boot karşılığı: @Service sınıfı + harici bir SDK client'ının
@PostConstruct ile bir kere initialize edilip singleton olarak tutulması.
"""
