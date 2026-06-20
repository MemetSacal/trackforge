"""add is_completed to exercise_sessions

#19: Seans tamamlanma durumu için is_completed alanı eklendi.
Mevcut satırlar NULL-safe: server_default='false' ile başlar,
yani eski seanslar otomatik is_completed=False olur.

Revision ID: 0002_add_is_completed
Revises: 0001_baseline
Create Date: 2026-06-19
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0002_add_is_completed"
down_revision: Union[str, None] = "0001_baseline"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ADD COLUMN IF NOT EXISTS — idempotent: sütun varsa atla
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    cols = [c["name"] for c in inspector.get_columns("exercise_sessions")]
    if "is_completed" not in cols:
        op.add_column(
            "exercise_sessions",
            sa.Column(
                "is_completed",
                sa.Boolean(),
                nullable=False,
                server_default=sa.text("false"),   # PostgreSQL false literal
            ),
        )


def downgrade() -> None:
    op.drop_column("exercise_sessions", "is_completed")
