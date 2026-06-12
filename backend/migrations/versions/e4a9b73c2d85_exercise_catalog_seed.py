"""exercise_catalog tablosu + seed — AI grounding için kanonik egzersiz listesi

Revision ID: e4a9b73c2d85
Revises: d3f7a82b1c64
"""
from typing import Sequence, Union
import uuid

import sqlalchemy as sa
from alembic import op

revision: str = "e4a9b73c2d85"
down_revision: Union[str, None] = "d3f7a82b1c64"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (ad, kas grupları, lokasyon, ekipman)
SEED = [
    # ── EV (ekipmansız) ──
    ("Şınav", ["Göğüs", "Triceps", "Omuz"], "home", None),
    ("Diz Üstü Şınav", ["Göğüs", "Triceps"], "home", None),
    ("Squat", ["Bacak", "Kalça"], "any", None),
    ("Lunge", ["Bacak", "Kalça"], "any", None),
    ("Bulgarian Split Squat", ["Bacak", "Kalça"], "home", "Sandalye"),
    ("Glute Bridge", ["Kalça", "Core"], "home", None),
    ("Plank", ["Core"], "any", None),
    ("Side Plank", ["Core", "Oblik"], "home", None),
    ("Mountain Climber", ["Core", "Kardiyo"], "home", None),
    ("Burpee", ["Tüm Vücut", "Kardiyo"], "any", None),
    ("Jumping Jack", ["Kardiyo"], "any", None),
    ("High Knees", ["Kardiyo", "Bacak"], "any", None),
    ("Crunch", ["Karın"], "home", None),
    ("Bisiklet Crunch", ["Karın", "Oblik"], "home", None),
    ("Leg Raise", ["Karın"], "home", None),
    ("Russian Twist", ["Oblik", "Core"], "home", None),
    ("Superman", ["Sırt", "Core"], "home", None),
    ("Wall Sit", ["Bacak"], "home", None),
    ("Calf Raise", ["Baldır"], "any", None),
    ("Triceps Dips", ["Triceps"], "home", "Sandalye"),
    ("Pike Push-up", ["Omuz", "Triceps"], "home", None),
    ("Bird Dog", ["Core", "Sırt"], "home", None),
    ("Dead Bug", ["Core"], "home", None),
    ("Step-up", ["Bacak", "Kalça"], "home", "Basamak"),
    # ── SALON (ekipmanlı) ──
    ("Bench Press", ["Göğüs", "Triceps", "Omuz"], "gym", "Bar"),
    ("Incline Bench Press", ["Üst Göğüs", "Omuz"], "gym", "Bar"),
    ("Dumbbell Press", ["Göğüs", "Triceps"], "gym", "Dambıl"),
    ("Dumbbell Fly", ["Göğüs"], "gym", "Dambıl"),
    ("Cable Crossover", ["Göğüs"], "gym", "Kablo"),
    ("Lat Pulldown", ["Sırt", "Biceps"], "gym", "Makine"),
    ("Barbell Row", ["Sırt", "Biceps"], "gym", "Bar"),
    ("Dumbbell Row", ["Sırt", "Biceps"], "gym", "Dambıl"),
    ("Seated Cable Row", ["Sırt"], "gym", "Kablo"),
    ("Pull-up", ["Sırt", "Biceps"], "any", "Bar"),
    ("Deadlift", ["Sırt", "Bacak", "Kalça"], "gym", "Bar"),
    ("Romanian Deadlift", ["Hamstring", "Kalça"], "gym", "Bar"),
    ("Overhead Press", ["Omuz", "Triceps"], "gym", "Bar"),
    ("Lateral Raise", ["Omuz"], "gym", "Dambıl"),
    ("Front Raise", ["Omuz"], "gym", "Dambıl"),
    ("Face Pull", ["Arka Omuz", "Sırt"], "gym", "Kablo"),
    ("Biceps Curl", ["Biceps"], "gym", "Dambıl"),
    ("Hammer Curl", ["Biceps", "Önkol"], "gym", "Dambıl"),
    ("Cable Curl", ["Biceps"], "gym", "Kablo"),
    ("Triceps Pushdown", ["Triceps"], "gym", "Kablo"),
    ("Skull Crusher", ["Triceps"], "gym", "Bar"),
    ("Leg Press", ["Bacak", "Kalça"], "gym", "Makine"),
    ("Leg Extension", ["Quadriceps"], "gym", "Makine"),
    ("Leg Curl", ["Hamstring"], "gym", "Makine"),
    ("Hip Thrust", ["Kalça"], "gym", "Bar"),
    ("Goblet Squat", ["Bacak", "Kalça"], "gym", "Dambıl"),
    ("Barbell Squat", ["Bacak", "Kalça", "Core"], "gym", "Bar"),
    ("Hack Squat", ["Bacak"], "gym", "Makine"),
    ("Cable Crunch", ["Karın"], "gym", "Kablo"),
    ("Hanging Leg Raise", ["Karın"], "gym", "Bar"),
    ("Treadmill Koşu", ["Kardiyo"], "gym", "Koşu Bandı"),
    ("Eliptik", ["Kardiyo"], "gym", "Makine"),
    ("Kürek Ergometresi", ["Kardiyo", "Sırt"], "gym", "Makine"),
    ("Sabit Bisiklet", ["Kardiyo", "Bacak"], "gym", "Makine"),
    # ── DIŞARI ──
    ("Koşu", ["Kardiyo", "Bacak"], "outdoor", None),
    ("Tempolu Yürüyüş", ["Kardiyo"], "outdoor", None),
    ("Bisiklet", ["Kardiyo", "Bacak"], "outdoor", "Bisiklet"),
    ("Merdiven Koşusu", ["Kardiyo", "Bacak"], "outdoor", None),
    ("Sprint", ["Kardiyo", "Bacak"], "outdoor", None),
    ("Yüzme", ["Tüm Vücut", "Kardiyo"], "outdoor", "Havuz"),
    ("İp Atlama", ["Kardiyo", "Baldır"], "any", "İp"),
    ("Park Barı Dips", ["Triceps", "Göğüs"], "outdoor", "Paralel Bar"),
]


def upgrade() -> None:
    table = op.create_table(
        "exercise_catalog",
        sa.Column("id", sa.String(), primary_key=True),
        sa.Column("name", sa.String(), nullable=False, unique=True),
        sa.Column("muscle_groups", sa.JSON(), nullable=False),
        sa.Column("location", sa.String(), nullable=False, server_default="any"),
        sa.Column("equipment", sa.String(), nullable=True),
    )
    op.bulk_insert(table, [
        {
            "id": str(uuid.uuid4()),
            "name": name,
            "muscle_groups": muscles,
            "location": loc,
            "equipment": eq,
        }
        for (name, muscles, loc, eq) in SEED
    ])


def downgrade() -> None:
    op.drop_table("exercise_catalog")
