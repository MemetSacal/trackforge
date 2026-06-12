"""AI v2 tabloları: ai_feedback + ai_response_cache

Revision ID: b7c4d92e8f31
Revises: a9f3e21c7d10
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b7c4d92e8f31"
down_revision: Union[str, None] = "a9f3e21c7d10"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "ai_feedback",
        sa.Column("id", sa.String(), primary_key=True),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("feature", sa.String(), nullable=False),
        sa.Column("rating", sa.SmallInteger(), nullable=False),
        sa.Column("comment", sa.String(300), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ai_feedback_user_id", "ai_feedback", ["user_id"])

    op.create_table(
        "ai_response_cache",
        sa.Column("id", sa.String(), primary_key=True),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("feature", sa.String(), nullable=False),
        sa.Column("input_hash", sa.String(64), nullable=False),
        sa.Column("response_json", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_ai_cache_lookup", "ai_response_cache", ["user_id", "feature", "input_hash"])


def downgrade() -> None:
    op.drop_index("ix_ai_cache_lookup", table_name="ai_response_cache")
    op.drop_table("ai_response_cache")
    op.drop_index("ix_ai_feedback_user_id", table_name="ai_feedback")
    op.drop_table("ai_feedback")
