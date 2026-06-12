"""merge heads v2 — b20968ed0b29 (ai_usage_logs) + 743e64354607 (is_premium)

Çoklu head sorununu kapatır. Bu migration'dan sonra Render start
komutu 'alembic upgrade heads' yerine 'alembic upgrade head' (TEKİL)
olarak güncellenebilir.

Revision ID: a9f3e21c7d10
"""
from typing import Sequence, Union

revision: str = "a9f3e21c7d10"
down_revision: Union[str, Sequence[str], None] = ("b20968ed0b29", "743e64354607")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass  # Sadece iki dalı birleştirir, şema değişikliği yok


def downgrade() -> None:
    pass
