"""Onarım: session_exercises.completed kolonu prod'da eksik kalmıştı

KÖK SEBEP: f1a2b3c4d5e6 migration'ı geçmişte alembic_version tablosuna
"uygulandı" olarak işaretlenmiş ama ALTER TABLE hiç çalışmamış (yarım
kalmış önceki bir deploy / iki-head karmaşası). Sonuç: ORM modeli
'completed' kolonunu bekliyor ama DB'de yok → tüm egzersiz/dashboard/AI
sorguları "current transaction is aborted" zincirine giriyordu.

ÇÖZÜM: IF NOT EXISTS ile idempotent — geçmiş ne olursa olsun güvenli.

Revision ID: b3e6f81a9c40
Revises: f5b08c41d9e7
"""
from typing import Sequence, Union

from alembic import op

revision: str = "b3e6f81a9c40"
down_revision: Union[str, None] = "f5b08c41d9e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        "ALTER TABLE session_exercises "
        "ADD COLUMN IF NOT EXISTS completed BOOLEAN NOT NULL DEFAULT false"
    )


def downgrade() -> None:
    op.execute("ALTER TABLE session_exercises DROP COLUMN IF EXISTS completed")
