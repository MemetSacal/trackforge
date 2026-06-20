"""add device_tokens and notifications tables (FCM push notification altyapısı)

#4: FCM push notification sistemi için iki yeni tablo.

device_tokens   → kullanıcıların FCM push token'larını tutar (çoklu cihaz destekli)
notifications   → in-app bildirim geçmişi (eskiden Flutter'da SharedPreferences'ta
                  tutuluyordu, artık backend'de kalıcı)

Revision ID: 0004_add_notification_tables
Revises: 0003_add_email_verification
Create Date: 2026-06-20
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0004_add_notification_tables"
down_revision: Union[str, None] = "0003_add_email_verification"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing_tables = set(inspector.get_table_names())

    # ── device_tokens ──
    if "device_tokens" not in existing_tables:
        op.create_table(
            "device_tokens",
            sa.Column("id", sa.String(), primary_key=True),
            sa.Column(
                "user_id",
                sa.String(),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("fcm_token", sa.String(), nullable=False),
            sa.Column("device_type", sa.String(), nullable=False),
            sa.Column("device_name", sa.String(), nullable=True),
            sa.Column("app_version", sa.String(), nullable=True),
            sa.Column(
                "is_active",
                sa.Boolean(),
                nullable=False,
                server_default=sa.text("true"),
            ),
            sa.Column("last_seen", sa.DateTime(timezone=True), nullable=True),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.text("now()"),
            ),
            sa.Column(
                "updated_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.text("now()"),
            ),
        )
        # user_id üzerinde index — bir kullanıcının aktif token'larını
        # çekmek sık çağrılan bir sorgu (her bildirim gönderiminde)
        op.create_index(
            "ix_device_tokens_user_id", "device_tokens", ["user_id"]
        )
        # Aynı (user_id, fcm_token) ikilisinin tekrar etmemesi için unique constraint
        # (upsert mantığı zaten bunu varsayıyor — DB seviyesinde de garanti altına alalım)
        op.create_unique_constraint(
            "uq_device_tokens_user_token", "device_tokens", ["user_id", "fcm_token"]
        )

    # ── notifications ──
    if "notifications" not in existing_tables:
        op.create_table(
            "notifications",
            sa.Column("id", sa.String(), primary_key=True),
            sa.Column(
                "user_id",
                sa.String(),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("title", sa.String(), nullable=False),
            sa.Column("body", sa.String(), nullable=False),
            sa.Column(
                "type",
                sa.String(),
                nullable=False,
                server_default=sa.text("'system'"),
            ),
            sa.Column("data", sa.JSON(), nullable=True),
            sa.Column(
                "is_read",
                sa.Boolean(),
                nullable=False,
                server_default=sa.text("false"),
            ),
            sa.Column(
                "created_at",
                sa.DateTime(timezone=True),
                nullable=False,
                server_default=sa.text("now()"),
            ),
        )
        # Bildirim geçmişi sorgusu user_id + created_at DESC ile çalışıyor
        op.create_index(
            "ix_notifications_user_id_created_at",
            "notifications",
            ["user_id", "created_at"],
        )


def downgrade() -> None:
    op.drop_table("notifications")
    op.drop_table("device_tokens")
