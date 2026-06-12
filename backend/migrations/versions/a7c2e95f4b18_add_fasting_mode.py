"""user_preferences.fasting_mode — 🌙 Ramazan/oruç modu

Revision ID: a7c2e95f4b18
Revises: f5b08c41d9e7
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a7c2e95f4b18"
down_revision: Union[str, None] = "f5b08c41d9e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_preferences",
        sa.Column("fasting_mode", sa.Boolean(), nullable=False, server_default="false"),
    )


def downgrade() -> None:
    op.drop_column("user_preferences", "fasting_mode")
