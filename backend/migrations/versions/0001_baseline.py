"""baseline — tüm şema tek migration (temiz kurulum)

Bu migration, TrackForge'un TÜM tablolarını (26 tablo) tek seferde oluşturur.
Eski 37 dağınık migration'ın yerine geçer — tek head, tek kök, tertemiz.

Yöntem: modellerin Base.metadata'sından create_all/drop_all.
Modeller tek doğruluk kaynağı olduğu için elle tablo yazma hatası olmaz;
şema her zaman koddaki modellerle birebir tutar.

Revision ID: 0001_baseline
Revises:
Create Date: 2026-06-14
"""
from typing import Sequence, Union

from alembic import op

# revision identifiers
revision: str = "0001_baseline"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _load_metadata():
    """Tüm model modüllerini import edip Base.metadata'yı döndürür."""
    import importlib
    import pkgutil
    from backend.app.infrastructure.db.base import Base
    import backend.app.infrastructure.db.models as models_pkg

    for mod in pkgutil.iter_modules(models_pkg.__path__):
        importlib.import_module(
            f"backend.app.infrastructure.db.models.{mod.name}"
        )
    return Base.metadata


def upgrade() -> None:
    metadata = _load_metadata()
    bind = op.get_bind()
    # checkfirst=True → tablo zaten varsa atlar (idempotent güvenlik).
    # Temiz kurulumda boş DB'ye hepsini kurar; FK sırasını SQLAlchemy çözer.
    metadata.create_all(bind=bind, checkfirst=True)


def downgrade() -> None:
    metadata = _load_metadata()
    bind = op.get_bind()
    metadata.drop_all(bind=bind)
