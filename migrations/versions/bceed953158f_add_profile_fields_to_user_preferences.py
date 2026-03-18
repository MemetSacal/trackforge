"""add_profile_fields_to_user_preferences

Revision ID: bceed953158f
Revises: 9aaa6b49d7db
Create Date: 2026-03-18 14:43:49.044254

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'bceed953158f'
down_revision: Union[str, Sequence[str], None] = '9aaa6b49d7db'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('user_preferences', sa.Column('height_cm', sa.Float(), nullable=True))
    op.add_column('user_preferences', sa.Column('age', sa.Integer(), nullable=True))
    op.add_column('user_preferences', sa.Column('gender', sa.String(), nullable=True))
    op.add_column('user_preferences', sa.Column('activity_level', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('user_preferences', 'activity_level')
    op.drop_column('user_preferences', 'gender')
    op.drop_column('user_preferences', 'age')
    op.drop_column('user_preferences', 'height_cm')