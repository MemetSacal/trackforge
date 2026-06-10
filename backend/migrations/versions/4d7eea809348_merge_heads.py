"""merge_heads

Revision ID: 4d7eea809348
Revises: 743e64354607, f1a2b3c4d5e6
Create Date: 2026-06-10 16:19:55.169277

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4d7eea809348'
down_revision: Union[str, Sequence[str], None] = ('743e64354607', 'f1a2b3c4d5e6')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
