"""exercise_sessions.source — AI planı seansı vs serbest seans ayrımı

Revision ID: d3f7a82b1c64
Revises: c8d5e03f9a42
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "d3f7a82b1c64"
down_revision: Union[str, None] = "c8d5e03f9a42"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "exercise_sessions",
        sa.Column("source", sa.String(), nullable=False, server_default="manual"),
    )


def downgrade() -> None:
    op.drop_column("exercise_sessions", "source")
