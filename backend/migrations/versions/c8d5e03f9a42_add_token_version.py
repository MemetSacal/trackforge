"""users.token_version — sunucu tarafı logout / oturum geçersizleştirme

Revision ID: c8d5e03f9a42
Revises: b7c4d92e8f31
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c8d5e03f9a42"
down_revision: Union[str, None] = "b7c4d92e8f31"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("token_version", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("users", "token_version")
