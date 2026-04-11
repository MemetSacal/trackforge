"""add muscle_groups to session_exercises

Revision ID: 1728a1d7983b
Revises: 0de1b6dbc95a
Create Date: 2026-04-06 17:11:28.399232

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '1728a1d7983b'
down_revision: Union[str, Sequence[str], None] = '0de1b6dbc95a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column('friendships', 'created_at',
               existing_type=postgresql.TIMESTAMP(timezone=True),
               nullable=False)
    op.alter_column('friendships', 'updated_at',
               existing_type=postgresql.TIMESTAMP(timezone=True),
               nullable=False)
    op.add_column('session_exercises',
        sa.Column('muscle_groups', sa.JSON(), nullable=True)
    )


def downgrade() -> None:
    op.drop_column('session_exercises', 'muscle_groups')
    op.alter_column('friendships', 'updated_at',
               existing_type=postgresql.TIMESTAMP(timezone=True),
               nullable=True)
    op.alter_column('friendships', 'created_at',
               existing_type=postgresql.TIMESTAMP(timezone=True),
               nullable=True)