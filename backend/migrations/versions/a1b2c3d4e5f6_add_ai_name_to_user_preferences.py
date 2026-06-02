"""add ai_name to user_preferences

Revision ID: a1b2c3d4e5f6
Revises: 873bb037ab61
Create Date: 2026-06-02 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '873bb037ab61'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('user_preferences',
        sa.Column('ai_name', sa.String(100), nullable=False, server_default='TrackForge AI')
    )


def downgrade() -> None:
    op.drop_column('user_preferences', 'ai_name')