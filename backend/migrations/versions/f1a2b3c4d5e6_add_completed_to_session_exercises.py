"""add completed to session_exercises

Revision ID: f1a2b3c4d5e6
Revises: e6c55c10c52b
Create Date: 2026-06-09

"""
from alembic import op
import sqlalchemy as sa

revision = 'f1a2b3c4d5e6'
down_revision = 'e6c55c10c52b'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('session_exercises',
        sa.Column('completed', sa.Boolean(), nullable=False, server_default='false')
    )


def downgrade() -> None:
    op.drop_column('session_exercises', 'completed')