"""duels tablosu — arkadaşla 7 günlük adım düellosu

Revision ID: f5b08c41d9e7
Revises: e4a9b73c2d85
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f5b08c41d9e7"
down_revision: Union[str, None] = "e4a9b73c2d85"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "duels",
        sa.Column("id", sa.String(), primary_key=True),
        sa.Column("challenger_id", sa.String(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("opponent_id", sa.String(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="pending"),
        sa.Column("winner_id", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_duels_challenger", "duels", ["challenger_id"])
    op.create_index("ix_duels_opponent", "duels", ["opponent_id"])


def downgrade() -> None:
    op.drop_index("ix_duels_opponent", table_name="duels")
    op.drop_index("ix_duels_challenger", table_name="duels")
    op.drop_table("duels")
