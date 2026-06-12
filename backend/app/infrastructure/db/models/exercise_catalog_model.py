# ── exercise_catalog_model.py (v5) ──
# AI grounding için kanonik egzersiz kataloğu.
# SORUN: workout_generator serbest metin egzersiz adı üretiyordu —
#   aynı hareket "Şınav", "Push-up", "Push Up" diye üç farklı isimle
#   gelebiliyor, kas grubu yazımı tutarsızlaşıyor, ilerleme takibi
#   isim bazında kırılıyordu.
# ÇÖZÜM: Seed'li katalog. AI prompt'una lokasyona uygun isim listesi
#   verilir, çıktı katalogla eşlenir (fuzzy match), kanonik ad ve
#   kas grupları katalogdan basılır.
import uuid
from sqlalchemy import String, JSON
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class ExerciseCatalogModel(Base):
    __tablename__ = "exercise_catalog"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    name: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    muscle_groups: Mapped[list] = mapped_column(JSON, nullable=False, default=list)
    # 'home' | 'gym' | 'outdoor' | 'any' — ekipman ihtiyacına göre
    location: Mapped[str] = mapped_column(String, nullable=False, default="any")
    equipment: Mapped[str] = mapped_column(String, nullable=True)
