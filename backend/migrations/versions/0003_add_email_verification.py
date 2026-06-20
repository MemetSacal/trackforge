"""add email verification fields to users

#2: email_verified, email_token, email_token_expires kolonları eklendi.
Mevcut kullanıcılar email_verified=true olarak başlar
(eskiden doğrulama yoktu, kilitlenmelerini istemiyoruz).

Revision ID: 0003_add_email_verification
Revises: 0001_baseline
Create Date: 2026-06-19
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0003_add_email_verification"
down_revision: Union[str, None] = "0002_add_is_completed"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    cols = {c["name"] for c in inspector.get_columns("users")}

    if "email_verified" not in cols:
        op.add_column(
            "users",
            sa.Column(
                "email_verified",
                sa.Boolean(),
                nullable=False,
                # Mevcut kullanıcılar doğrulanmış sayılır — kilitlenmesinler.
                server_default=sa.text("true"),
            ),
        )

    if "email_token" not in cols:
        op.add_column(
            "users",
            sa.Column("email_token", sa.String(128), nullable=True),
        )

    if "email_token_expires" not in cols:
        op.add_column(
            "users",
            sa.Column(
                "email_token_expires",
                sa.DateTime(timezone=True),
                nullable=True,
            ),
        )


def downgrade() -> None:
    op.drop_column("users", "email_token_expires")
    op.drop_column("users", "email_token")
    op.drop_column("users", "email_verified")
