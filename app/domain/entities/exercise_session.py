from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Optional


@dataclass
class ExerciseSession:
    """
    Domain entity — egzersiz seansı ana kaydı
    Bir seans birden fazla egzersiz içerir (session_exercises)
    Teknik olarak exercise_session ile session_exercise aynı dosyaya yazılabilir, ama biz ayırdık çünkü:
    1. Single Responsibility
    Her dosya tek bir şeyden sorumlu. exercise_session.py sadece seansı tanımlar, session_exercise.py sadece egzersizi. Biri değişince diğerine dokunmak gerekmez.
    2. Büyüdükçe karmaşıklaşır
    Şu an 2 class küçük görünüyor, ama ileride her birine method, property eklenebilir. Ayrı dosyalarda olunca bulmak ve düzenlemek kolay.
    3. Import okunabilirliği
    4. Spring Boot analogisi
    Java'da ExerciseSession.java ve SessionExercise.java diye ayrı dosyalar açardın — aynı mantık.

    exercise_sessions → Ana seans kaydı
    id, user_id, date, duration_minutes, notes, calories_burned
    session_exercises → Seans içindeki her egzersiz
    id, session_id (FK), exercise_name, sets, reps, weight_kg, notes
    Yani bir seans birden fazla egzersiz içerir — Spring'deki @OneToMany ilişkisi gibi düşün.
    """

    id: str
    user_id: str                            # FK — hangi kullanıcıya ait
    date: date                              # DATE_BASED zaman referansı
    duration_minutes: Optional[int]         # Seansın süresi dakika cinsinden
    calories_burned: Optional[float]        # Yakılan kalori — opsiyonel
    notes: Optional[str]                    # Seans notu — "Çok yoruldum" gibi
    created_at: datetime
