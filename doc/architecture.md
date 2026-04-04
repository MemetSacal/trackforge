# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v4.0 — Güncel & Genişletilmiş  
**Tarih:** Nisan 2026  
**Mimari:** Clean Architecture + Repository Pattern  
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First

---

## 1. Proje Kimliği

| Alan | Detay |
|---|---|
| **Ad** | TrackForge — AI-Powered Personal Health & Fitness System |
| **Amaç** | Diyet, ölçüm, fotoğraf, egzersiz, uyku, su takibi ve notları haftalık bazda takip eden; kan değerleri, hastalık geçmişi ve kişisel tercihler doğrultusunda AI destekli kişiselleştirilmiş sağlık, beslenme ve antrenman tavsiyesi sunan platform. |
| **Mimari** | Clean Architecture + Repository Pattern |
| **Zaman Ref.** | DATE_BASED (hafta hesaplanan, saklanmayan) |
| **AI Hazır** | Evet (pluggable AI layer — Claude API entegre) |
| **GitHub** | https://github.com/MemetSacal/trackforge |

---

## 2. Teknoloji Stack'i

| Katman | Teknoloji | Versiyon | Neden |
|---|---|---|---|
| **Backend** | FastAPI | 0.115+ | Async, otomatik OpenAPI, production-ready |
| **Veritabanı** | PostgreSQL | 16+ | ACID, JSON desteği, güçlü indexing |
| **ORM** | SQLAlchemy | 2.0+ | Async destekli, type-safe |
| **Migration** | Alembic | latest | Schema versiyon yönetimi |
| **Auth** | JWT (python-jose) | latest | Stateless, mobil uyumlu |
| **Validation** | Pydantic v2 | 2.0+ | FastAPI ile native entegrasyon |
| **Dosya Depolama** | Filesystem → AWS S3 | — | Başlangıç local, production S3 |
| **Loglama** | structlog | latest | Structured JSON logging |
| **Test** | pytest + httpx | latest | Async test desteği |
| **Container** | Docker + Compose | latest | Reproducible environment |
| **CI/CD** | GitHub Actions | — | Otomatik lint pipeline |
| **Mobil** | Flutter | 3.x | iOS + Android tek codebase |
| **HTTP Client** | Dio | latest | Interceptor, retry, token refresh |
| **State Mgmt** | Riverpod | 2.x | Test edilebilir, compile-safe |
| **Grafik** | fl_chart | latest | Native Flutter charts |
| **AI — Analiz** | Claude API (Anthropic) | — | Haftalık özet, trend analizi, tavsiye |
| **AI — Vision** | Claude Vision | — | Fotoğraftan kalori hesaplama |
| **AI — Görsel** | DALL-E 3 / Stable Diffusion | — | Hedef vücut görselleştirme (beklemede) |
| **Barkod** | Open Food Facts API | — | Ücretsiz, geniş besin veritabanı |

---

## 3. Sistem Mimarisi — Kuş Bakışı

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                         │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │           Flutter App (iOS + Android)           │   │
│   │                                                 │   │
│   │  Screens → Providers (Riverpod) → Repositories  │   │
│   │              ↓                                  │   │
│   │         Dio HTTP Client                         │   │
│   └─────────────────┬───────────────────────────────┘   │
└─────────────────────┼───────────────────────────────────┘
                      │ HTTPS / REST / JSON
                      │ Authorization: Bearer <JWT>
┌─────────────────────▼───────────────────────────────────┐
│                    API GATEWAY                          │
│              FastAPI (Uvicorn/Gunicorn)                 │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐    │
│  │  Router  │  │   Auth   │  │   Middleware        │    │
│  │  /api/v1 │  │  JWT     │  │  logging, CORS,     │    │
│  │          │  │  OAuth2  │  │  rate limiting      │    │
│  └──────────┘  └──────────┘  └────────────────────┘    │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │              CLEAN ARCHITECTURE CORE             │   │
│  │                                                  │   │
│  │  Presentation → Application → Domain             │   │
│  │                    ↓                             │   │
│  │              Infrastructure                      │   │
│  │                    ↓                             │   │
│  │               AI Layer (pluggable)               │   │
│  └──────────────────────────────────────────────────┘   │
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
  ┌────────▼──────┐          ┌────────▼──────┐
  │  PostgreSQL   │          │  File Storage  │
  │  Database     │          │  (Local / S3)  │
  │               │          │  PDF, IMG      │
  └───────────────┘          └───────────────┘
```

---

## 4. Clean Architecture Katmanları

```
┌─────────────────────────────────────────────┐
│           PRESENTATION LAYER                │  ← HTTP, routing, validation
│         api/v1/endpoints/                   │
├─────────────────────────────────────────────┤
│           APPLICATION LAYER                 │  ← Use cases, iş mantığı
│              services/                      │
├─────────────────────────────────────────────┤
│             DOMAIN LAYER                    │  ← Entity'ler, saf Python
│           domain/entities/                  │
│           domain/interfaces/                │  ← Repository abstract'ları
├─────────────────────────────────────────────┤
│         INFRASTRUCTURE LAYER                │  ← DB, dosya, dış servisler
│   repositories/ + storage/ + logging/       │
├─────────────────────────────────────────────┤
│              AI LAYER                       │  ← Pluggable analiz modülü
│               ai/                           │
└─────────────────────────────────────────────┘

Bağımlılık kuralı: Oklar sadece içe doğru akar.
Domain hiçbir şeye bağımlı değil.
Infrastructure, Domain interface'lerini implement eder.
```

---

## 5. Backend Klasör Yapısı

```
trackforge/
│
├── app/
│   ├── main.py
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── router.py
│   │       └── endpoints/
│   │           ├── auth.py
│   │           ├── measurements.py
│   │           ├── notes.py
│   │           ├── meal_compliance.py
│   │           ├── files.py
│   │           ├── exercises.py
│   │           ├── water.py               ← Faz 5
│   │           ├── sleep.py               ← Faz 5
│   │           ├── preferences.py         ← Faz 5
│   │           ├── shopping.py            ← Faz 5
│   │           ├── reports.py             ← Faz 6
│   │           ├── ai.py                  ← Faz 8
│   │           ├── onboarding.py          ← Faz 10
│   │           ├── barcode.py             ← Faz 10
│   │           ├── social.py              ← Faz 10
│   │           └── gamification.py        ← Faz 10
│   │
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── user.py
│   │   │   ├── body_measurement.py
│   │   │   ├── weekly_note.py
│   │   │   ├── meal_compliance.py
│   │   │   ├── file_upload.py
│   │   │   ├── exercise_session.py
│   │   │   ├── session_exercise.py
│   │   │   ├── water_log.py               ← Faz 5
│   │   │   ├── sleep_log.py               ← Faz 5
│   │   │   ├── user_preference.py         ← Faz 5
│   │   │   ├── onboarding_profile.py      ← Faz 10
│   │   │   ├── friendship.py              ← Faz 10
│   │   │   ├── streak.py                  ← Faz 10
│   │   │   ├── badge.py                   ← Faz 10
│   │   │   └── user_level.py              ← Faz 10
│   │   │
│   │   └── interfaces/
│   │       ├── i_user_repository.py
│   │       ├── i_measurement_repository.py
│   │       ├── i_note_repository.py
│   │       ├── i_meal_compliance_repository.py
│   │       ├── i_file_upload_repository.py
│   │       ├── i_exercise_session_repository.py
│   │       ├── i_session_exercise_repository.py
│   │       ├── i_water_log_repository.py        ← Faz 5
│   │       ├── i_sleep_log_repository.py        ← Faz 5
│   │       ├── i_user_preference_repository.py  ← Faz 5
│   │       ├── i_onboarding_repository.py       ← Faz 10
│   │       ├── i_social_repository.py           ← Faz 10
│   │       └── i_gamification_repository.py     ← Faz 10
│   │
│   ├── application/
│   │   ├── services/
│   │   │   ├── auth_service.py
│   │   │   ├── measurement_service.py
│   │   │   ├── note_service.py
│   │   │   ├── meal_compliance_service.py
│   │   │   ├── file_upload_service.py
│   │   │   ├── exercise_service.py
│   │   │   ├── water_service.py           ← Faz 5
│   │   │   ├── sleep_service.py           ← Faz 5
│   │   │   ├── preference_service.py      ← Faz 5
│   │   │   ├── shopping_service.py        ← Faz 5
│   │   │   ├── report_service.py          ← Faz 6
│   │   │   ├── onboarding_service.py      ← Faz 10
│   │   │   ├── barcode_service.py         ← Faz 10
│   │   │   ├── social_service.py          ← Faz 10
│   │   │   └── gamification_service.py    ← Faz 10
│   │   │
│   │   └── schemas/
│   │       ├── auth.py
│   │       ├── measurement.py
│   │       ├── note.py
│   │       ├── meal_compliance.py
│   │       ├── file_upload.py
│   │       ├── exercise.py
│   │       ├── water.py                   ← Faz 5
│   │       ├── sleep.py                   ← Faz 5
│   │       ├── preference.py              ← Faz 5
│   │       ├── shopping.py                ← Faz 5
│   │       ├── report.py                  ← Faz 6
│   │       ├── ai.py                      ← Faz 8
│   │       ├── onboarding.py              ← Faz 10
│   │       ├── barcode.py                 ← Faz 10
│   │       ├── social.py                  ← Faz 10
│   │       └── gamification.py            ← Faz 10
│   │
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── models/
│   │   │       ├── user_model.py
│   │   │       ├── measurement_model.py
│   │   │       ├── note_model.py
│   │   │       ├── meal_compliance_model.py
│   │   │       ├── file_upload_model.py
│   │   │       ├── exercise_session_model.py
│   │   │       ├── session_exercise_model.py
│   │   │       ├── water_log_model.py     ← Faz 5
│   │   │       ├── sleep_log_model.py     ← Faz 5
│   │   │       ├── user_preference_model.py ← Faz 5
│   │   │       ├── onboarding_profile_model.py ← Faz 10
│   │   │       ├── friendship_model.py    ← Faz 10
│   │   │       ├── streak_model.py        ← Faz 10
│   │   │       ├── badge_model.py         ← Faz 10
│   │   │       └── user_level_model.py    ← Faz 10
│   │   │
│   │   ├── repositories/
│   │   │   ├── user_repository.py
│   │   │   ├── measurement_repository.py
│   │   │   ├── note_repository.py
│   │   │   ├── meal_compliance_repository.py
│   │   │   ├── file_upload_repository.py
│   │   │   ├── exercise_session_repository.py
│   │   │   ├── session_exercise_repository.py
│   │   │   ├── water_log_repository.py    ← Faz 5
│   │   │   ├── sleep_log_repository.py    ← Faz 5
│   │   │   ├── user_preference_repository.py ← Faz 5
│   │   │   ├── onboarding_repository.py   ← Faz 10
│   │   │   ├── social_repository.py       ← Faz 10
│   │   │   └── gamification_repository.py ← Faz 10
│   │   │
│   │   ├── storage/
│   │   │   └── file_storage_service.py
│   │   │
│   │   └── logging/
│   │       └── logger.py
│   │
│   ├── ai/                                ← Faz 8
│   │   ├── client.py
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py
│   │   │   └── calorie_vision_analyzer.py
│   │   └── generators/
│   │       ├── workout_generator.py
│   │       ├── meal_advisor.py
│   │       ├── recipe_generator.py
│   │       └── calorie_bank_advisor.py    ← ileride
│   │
│   └── core/
│       ├── config.py
│       ├── security.py
│       ├── dependencies.py
│       └── exceptions.py
│
├── migrations/
│   ├── versions/
│   └── env.py
│
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
│
├── uploads/
│   ├── photos/
│   └── diet_plans/
│
├── doc/
│   ├── architecture.md
│   ├── cheatsheet.md
│   └── images/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── .env
├── .env.example
├── requirements.txt
├── docker-compose.yml
└── README.md
```

---

## 6. Veritabanı Şeması

### Mevcut Tablolar — 11 tablo (Faz 1–8)

```sql
-- USERS
users
├── id              VARCHAR     PK (UUID)
├── email           VARCHAR     UNIQUE, NOT NULL
├── password_hash   VARCHAR     NOT NULL
├── full_name       VARCHAR     NOT NULL
├── created_at      TIMESTAMPTZ
└── updated_at      TIMESTAMPTZ

-- BODY MEASUREMENTS
body_measurements
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── weight_kg       FLOAT
├── body_fat_pct    FLOAT
├── muscle_mass_kg  FLOAT
├── waist_cm        FLOAT
├── chest_cm        FLOAT
├── hip_cm          FLOAT
├── arm_cm          FLOAT
├── leg_cm          FLOAT
└── created_at      TIMESTAMPTZ

-- WEEKLY NOTES
weekly_notes
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── title           VARCHAR
├── content         TEXT        NOT NULL
├── energy_level    INT         (1-10)
├── mood_score      INT         (1-10)
└── created_at      TIMESTAMPTZ

-- MEAL COMPLIANCE (Kalori Bankası dahil)
meal_compliance
├── id                  VARCHAR     PK
├── user_id             VARCHAR     FK → users
├── date                DATE        NOT NULL
├── complied            BOOLEAN     NOT NULL
├── compliance_rate     FLOAT       (0-100)
├── calories_consumed   FLOAT       ← o gün alınan kalori
├── calories_target     FLOAT       ← günlük hedef (TDEE bazlı)
├── calorie_balance     FLOAT       ← consumed - target
├── weekly_bank_balance FLOAT       ← son 7 günün birikimli dengesi
├── notes               TEXT
└── created_at          TIMESTAMPTZ

-- FILE UPLOADS
file_uploads
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── file_type       VARCHAR     (photo / diet_plan)
├── original_filename VARCHAR
├── stored_filename VARCHAR
├── file_path       VARCHAR
├── mime_type       VARCHAR
├── file_size_bytes INT
├── description     TEXT
└── created_at      TIMESTAMPTZ

-- EXERCISE SESSIONS
exercise_sessions
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── duration_minutes INT
├── calories_burned FLOAT
├── notes           TEXT
└── created_at      TIMESTAMPTZ

-- SESSION EXERCISES
session_exercises
├── id              VARCHAR     PK
├── session_id      VARCHAR     FK → exercise_sessions (CASCADE DELETE)
├── exercise_name   VARCHAR     NOT NULL
├── muscle_groups   JSON                    ← Faz 10 (kas grubu anatomisi)
├── sets            INT
├── reps            INT
├── weight_kg       FLOAT
├── notes           TEXT
└── created_at      TIMESTAMPTZ

-- WATER LOGS
water_logs
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── amount_ml       INT         NOT NULL
├── target_ml       INT
└── created_at      TIMESTAMPTZ

-- SLEEP LOGS
sleep_logs
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── sleep_time      TIME
├── wake_time       TIME
├── duration_hours  FLOAT
├── quality_score   INT         (1-10)
├── notes           TEXT
└── created_at      TIMESTAMPTZ

-- USER PREFERENCES
user_preferences
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── height_cm       FLOAT                   ← BMR için
├── age             INT                     ← BMR için
├── gender          VARCHAR                 ← BMR için
├── activity_level  VARCHAR                 ← sedentary/light/moderate/active/very_active
├── liked_foods     JSON
├── disliked_foods  JSON
├── allergies       JSON
├── diseases        JSON
├── blood_type      VARCHAR
├── blood_values    JSON
├── workout_location VARCHAR
├── fitness_goal    VARCHAR                 ← weight_loss/muscle_gain/maintenance
└── created_at      TIMESTAMPTZ

-- SHOPPING ITEMS
shopping_items
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── name            VARCHAR     NOT NULL
├── quantity        VARCHAR
├── category        VARCHAR
├── is_completed    BOOLEAN     default False
├── price           FLOAT
├── currency        VARCHAR     default "TRY"
├── source          VARCHAR
├── is_recurring    BOOLEAN     default False
├── notes           TEXT
└── created_at      TIMESTAMPTZ
```

### Yeni Tablolar — Faz 10

```sql
-- ONBOARDING PROFILE
onboarding_profile
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── is_completed    BOOLEAN     default False
├── goals           JSON        ← ["weight_loss", "muscle_gain"] max 3 seçim
├── diet_preference VARCHAR     ← normal/vegetarian/vegan/gluten_free
├── completed_at    TIMESTAMPTZ
└── created_at      TIMESTAMPTZ

-- FRIENDSHIPS
friendships
├── id              VARCHAR     PK
├── requester_id    VARCHAR     FK → users
├── addressee_id    VARCHAR     FK → users
├── status          VARCHAR     ← pending/accepted/blocked
├── created_at      TIMESTAMPTZ
└── updated_at      TIMESTAMPTZ

-- STREAKS
streaks
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── streak_type     VARCHAR     ← water/exercise/sleep
├── current_streak  INT         default 0
├── longest_streak  INT         default 0
├── last_updated    DATE
└── created_at      TIMESTAMPTZ

-- BADGES
badges
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── badge_key       VARCHAR     ← "first_workout", "7_day_water" vs.
├── badge_name      VARCHAR
├── description     TEXT
├── earned_at       TIMESTAMPTZ
└── created_at      TIMESTAMPTZ

-- USER LEVELS
user_levels
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── level           INT         default 1
├── xp              INT         default 0
├── level_title     VARCHAR     ← Beginner/Athlete/Champion vs.
└── updated_at      TIMESTAMPTZ
```

---

## 7. API Endpoint Yapısı

```
BASE: /api/v1

── AUTH ──────────────────────────────────────────
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/me

── ONBOARDING ────────────────────────────────────  ← Faz 10
POST   /onboarding
GET    /onboarding
PUT    /onboarding

── MEASUREMENTS ──────────────────────────────────
POST   /measurements
GET    /measurements?from=&to=
GET    /measurements/date/{date}
PUT    /measurements/{id}
DELETE /measurements/{id}

── NOTES ─────────────────────────────────────────
POST   /notes
GET    /notes?from=&to=
GET    /notes/date/{date}
PUT    /notes/{id}
DELETE /notes/{id}

── MEAL COMPLIANCE ───────────────────────────────
POST   /meal-compliance
GET    /meal-compliance?from=&to=
GET    /meal-compliance/date/{date}
PUT    /meal-compliance/{id}
DELETE /meal-compliance/{id}

── BARKOD ────────────────────────────────────────  ← Faz 10
GET    /barcode/{barcode}           ← Open Food Facts proxy

── FILES ─────────────────────────────────────────
POST   /files/photos
POST   /files/diet-plans
GET    /files/photos
GET    /files/diet-plans
GET    /files/download/{id}
DELETE /files/{id}

── EXERCISES ─────────────────────────────────────
POST   /exercises/sessions
GET    /exercises/sessions?from=&to=
GET    /exercises/sessions/{id}
PUT    /exercises/sessions/{id}
DELETE /exercises/sessions/{id}
POST   /exercises/sessions/{id}/exercises
GET    /exercises/sessions/{id}/exercises
PUT    /exercises/exercises/{id}
DELETE /exercises/exercises/{id}

── WATER TRACKING ────────────────────────────────
POST   /water
GET    /water?start_date=&end_date=
GET    /water/date/{date}
PUT    /water/{id}
DELETE /water/{id}

── SLEEP TRACKING ────────────────────────────────
POST   /sleep
GET    /sleep?start_date=&end_date=
GET    /sleep/date/{date}
PUT    /sleep/{id}
DELETE /sleep/{id}

── USER PREFERENCES ──────────────────────────────
POST   /preferences
GET    /preferences
PUT    /preferences
DELETE /preferences

── SHOPPING LIST ─────────────────────────────────
POST   /shopping
GET    /shopping
GET    /shopping/recurring
PUT    /shopping/{id}
PATCH  /shopping/{id}/toggle
DELETE /shopping/{id}
DELETE /shopping/completed/clear

── REPORTS ───────────────────────────────────────
GET    /reports/weekly?reference_date=
GET    /reports/monthly?year=&month=

── AI ────────────────────────────────────────────
POST   /ai/weekly-summary           ← Haftalık AI özet raporu ✅
POST   /ai/workout-plan             ← Lokasyon bazlı antrenman planı ✅
POST   /ai/meal-advice              ← BMR/TDEE bazlı diyet tavsiyesi ✅
POST   /ai/recipe                   ← Malzeme bazlı tarif önerisi ✅
POST   /ai/calorie-from-photo       ← Fotoğraftan kalori (Vision) ✅
POST   /ai/body-visualization       ← Hedef vücut görseli (DALL-E) ⏳ beklemede

── SOCIAL ────────────────────────────────────────  ← Faz 10
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
GET    /social/leaderboard          ← Sadece arkadaşlar arası haftalık XP

── GAMİFİCATİON ──────────────────────────────────  ← Faz 10
GET    /gamification/streaks
GET    /gamification/badges
GET    /gamification/level
```

---

## 8. Kalori Bankası Sistemi

```
Temel Mantık:
  TDEE = BMR × aktivite_katsayısı
  BMR  = Mifflin-St Jeor formülü

  Kilo verme hedefi : günlük_hedef = TDEE - 700
  Kas yapma hedefi  : günlük_hedef = TDEE + 250
  Koruma hedefi     : günlük_hedef = TDEE

  calorie_balance      = calories_consumed - calories_target
  weekly_bank_balance  = son 7 günün (target - consumed) toplamı

Güvenli Sınırlar:
  Minimum kalori: 1500 kcal (kas kaybını önler)
  Maksimum kaçamak: TDEE + weekly_bank_balance

Örnek Senaryo (kilo verme, hedef 1600 kcal/gün):
  Pazartesi: 1200 aldı → balance: -400, bank: +400 kredi
  Salı:      1400 aldı → balance: -200, bank: +600 kredi
  Çarşamba:  2200 aldı → balance: +600, bank:   0 kredi
  Perşembe:  1200 aldı → balance: -400, bank: +400 kredi
  Cuma:      ?    → "400 kalori krediniz var, bugün 2000'e kadar yiyebilirsiniz 🎉"
```

---

## 9. Onboarding Akışı

```
Kullanıcı kayıt olduktan sonra ilk girişte 4 adımlı onboarding ile karşılaşır.

Adım 1 — Hedefler
  Seçenekler: Kilo Vermek / Aynı Kiloda Kalmak / Kilo Almak /
              Kas Kazanmak / Diyetimi Değiştir / Öğün Planla /
              Stresi Yönetmek / Aktif Kal
  Kural: Max 3 seçim

Adım 2 — Temel Bilgiler
  Boy (cm), Kilo (kg), Yaş, Cinsiyet

Adım 3 — Aktivite Seviyesi
  Sedanter / Hafif Aktif / Orta Aktif / Aktif / Çok Aktif

Adım 4 — Diyet Tercihi
  Normal / Vejetaryen / Vegan / Glutensiz

Kurallar:
  - is_completed = false → Flutter her girişte onboarding gösterir
  - Tamamlandığında is_completed = true → bir daha gösterilmez
  - Sonradan Profil Ayarları ekranından değiştirilebilir (PUT /onboarding)
  - Temel bilgiler aynı zamanda user_preferences'a da yazılır (BMR/TDEE için)
```

---

## 10. Gamification Sistemi

### Streak Sistemi

| Streak Türü | Tetikleyici |
|---|---|
| `water` | Günlük su hedefine ulaşıldı |
| `exercise` | O gün antrenman seansı oluşturuldu |
| `sleep` | Uyku logu girildi ve kalite skoru ≥ 6 |

### Rozet Sistemi

| Badge Key | Açıklama | Tetikleyici |
|---|---|---|
| `first_workout` | İlk Antrenman | İlk seans oluşturuldu |
| `7_day_water` | 7 Gün Su Hedefi | Water streak = 7 |
| `30_day_water` | 30 Gün Su Hedefi | Water streak = 30 |
| `weight_loss_5kg` | 5 kg Kayıp | Ölçüm farkı ≥ 5 kg |
| `weight_loss_10kg` | 10 kg Kayıp | Ölçüm farkı ≥ 10 kg |
| `first_photo` | İlk Fotoğraf | İlk fotoğraf yüklendi |
| `streak_warrior` | 7 Gün Egzersiz | Exercise streak = 7 |

### Seviye Sistemi

| Seviye | Başlık | XP Gereksinimi |
|---|---|---|
| 1 | Beginner | 0 |
| 2 | Active | 500 |
| 3 | Fit | 1500 |
| 4 | Athlete | 3000 |
| 5 | Champion | 6000 |

**XP Kazanma Kuralları:**
- Antrenman seansı oluştur: +50 XP
- Günlük su hedefi tut: +20 XP
- Uyku logu gir: +15 XP
- Rozet kazan: +100 XP
- Haftalık rapor görüntüle: +10 XP

---

## 11. Sosyal Sistem

```
Arkadaşlık:
  - Email ile arkadaş arama
  - İstek gönder → kabul/red
  - Status: pending / accepted / blocked

Liderlik Tablosu:
  - Sadece arkadaşlar arası — gizlilik öncelikli
  - Haftalık XP kazanımına göre sıralama
  - Rolling 7 gün (haftalık sıfırlanır)
```

---

## 12. AI Layer Detayı

```python
ai/
├── client.py
│   # Claude API bağlantısı — Model: claude-sonnet-4-5
│
├── analyzers/
│   ├── weekly_analyzer.py
│   │   # Input:  WeeklyReportResponse
│   │   # Output: Türkçe kişiselleştirilmiş özet
│   │
│   └── calorie_vision_analyzer.py
│       # Input:  yemek fotoğrafı (base64)
│       # Output: kalori + makro değerler
│       # API:    Claude Vision
│
└── generators/
    ├── workout_generator.py
    │   # Input:  lokasyon + hedef + seviye + gün
    │   # Output: JSON haftalık antrenman planı
    │
    ├── meal_advisor.py
    │   # Input:  tercihler + kan değerleri + BMR/TDEE
    │   # Output: JSON diyet tavsiyesi
    │
    ├── recipe_generator.py
    │   # Input:  malzemeler + tercihler + alerjiler
    │   # Output: JSON tarif + besin değerleri
    │
    └── calorie_bank_advisor.py
        # Input:  haftalık kalori banka durumu
        # Output: kişiselleştirilmiş kaçamak önerisi (ileride)

Not: body_trend_analyzer.py, compliance_analyzer.py ve report_generator.py
mimaride planlanmıştı ancak report_service.py ve weekly_analyzer.py
tarafından karşılandığı için ayrıca implement edilmedi.
```

---

## 13. Güvenlik Mimarisi

```
JWT Flow:
  1. POST /auth/login → access_token (15dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 gelince: POST /auth/refresh → yeni access_token
  4. Flutter: flutter_secure_storage ile token saklama
  5. Python: python-jose ile imzalama, passlib ile şifre hash

Hassas Veri Yönetimi:
  - Kan değerleri, hastalık bilgisi → user_preferences tablosunda JSON
  - Medikal tavsiye değil, kişisel takip amacı belirtilmeli
  - Kullanıcı verileri 3. taraflarla paylaşılmaz
  - Sosyal: Liderlik tablosu sadece arkadaşlar arası görünür

Env Değişkenleri (.env):
  DATABASE_URL=postgresql+asyncpg://...
  SECRET_KEY=<güçlü random key>
  ALGORITHM=HS256
  ACCESS_TOKEN_EXPIRE_MINUTES=15
  REFRESH_TOKEN_EXPIRE_DAYS=7
  STORAGE_TYPE=local
  CLAUDE_API_KEY=...         (Faz 8 — aktif)
  OPENAI_API_KEY=...         (opsiyonel)
  STABILITY_API_KEY=...      (DALL-E alternatifi, beklemede)
  OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org  (Faz 10)
```

---

## 14. Loglama Stratejisi

```python
{
  "timestamp": "2026-04-01T10:00:00Z",
  "level": "INFO",
  "event": "measurement_created",
  "user_id": "uuid...",
  "endpoint": "POST /measurements",
  "duration_ms": 42,
  "request_id": "uuid..."
}
```

---

## 15. Git Stratejisi

```
Branch yapısı:
  main       ← her zaman production-ready
  develop    ← aktif geliştirme branch'i
  feature/*  ← tek özellik geliştirme
  fix/*      ← bug fix
  docs/*     ← sadece dokümantasyon

Commit formatı (Conventional Commits):
  feat:     yeni özellik
  fix:      hata düzeltme
  refactor: yeniden yazım
  test:     test ekleme
  docs:     dokümantasyon
  chore:    build, config
```

---

## 16. Geliştirme Fazları (Roadmap)

### ✅ Faz 1 — Auth Sistemi
```
✅ Docker Compose (PostgreSQL + pgAdmin)
✅ FastAPI Clean Architecture iskeleti
✅ Alembic + ilk migration
✅ JWT auth (register, login, refresh, me)
✅ structlog entegrasyonu
✅ Swagger Bearer token desteği
```

### ✅ Faz 2 — Core CRUD
```
✅ Body measurements CRUD
✅ Weekly notes CRUD
✅ Meal compliance CRUD
✅ Tarih bazlı sorgulama (from/to)
```

### ✅ Faz 3 — Dosya İşlemleri
```
✅ Fotoğraf yükleme (JPEG, PNG, WebP)
✅ PDF diyet planı yükleme
✅ Dosya indirme endpoint'i
✅ Dosya silme (DB + disk)
✅ UUID bazlı güvenli isimlendirme
✅ MIME type + boyut validasyonu
✅ aiofiles ile async chunked write
```

### ✅ Faz 4 — Egzersiz Takibi
```
✅ Exercise sessions CRUD
✅ Session exercises CRUD
✅ Cascade deletion (seans silinince egzersizler de silinir)
✅ İki entity arası OneToMany ilişkisi
```

### ✅ Faz 5 — Yeni Backend Özellikleri
```
✅ Su takibi CRUD (water_logs)
✅ Uyku takibi CRUD (sleep_logs)
✅ Kullanıcı tercihleri (yemek tercihleri, hastalıklar, kan değerleri, hedef)
✅ Fiziksel profil (height_cm, age, gender, activity_level) — BMR/TDEE için
✅ Alışveriş listesi (fiyat, kaynak, tekrar eden ürünler, sepet özeti)
```

### ✅ Faz 6 — Raporlar
```
✅ /reports/weekly endpoint
✅ /reports/monthly endpoint
✅ Su, uyku, egzersiz, diyet uyum özetleri
✅ Kilo değişim hesaplama
```

### ✅ Faz 7 — Polish & Deployment
```
✅ GitHub Actions (lint pipeline)
✅ README.md (profesyonel, İngilizce, badge'li, UI görselleri)
✅ requirements.txt + .env.example
⏳ Docker production config (ileriye bırakıldı)
⏳ pytest unit + integration testler (ileriye bırakıldı)
```

### ✅ Faz 8 — AI Entegrasyonu
```
✅ Claude API entegrasyonu (client.py)
✅ Haftalık AI özet raporu (weekly_analyzer.py)
✅ Lokasyon bazlı antrenman planı (workout_generator.py)
✅ BMR/TDEE bazlı diyet tavsiyesi (meal_advisor.py)
✅ Malzeme bazlı tarif önerisi (recipe_generator.py)
✅ Fotoğraftan kalori hesaplama — Claude Vision (calorie_vision_analyzer.py)
✅ Kalori bankası sistemi (meal_compliance_service.py)
⏳ Hedef vücut görselleştirme — DALL-E 3 (beklemede, OpenAI key gerekli)

Not: body_trend_analyzer.py, compliance_analyzer.py ve report_generator.py
mimaride planlanmıştı ancak report_service.py ve weekly_analyzer.py
tarafından karşılandığı için ayrıca implement edilmedi.
```

### ⏳ Faz 9 — Yeni Backend Özellikleri
```
⏳ Onboarding profil CRUD (4 adımlı ilk kurulum akışı)
⏳ Barkod proxy endpoint (Open Food Facts API entegrasyonu)
⏳ Sosyal sistem (arkadaşlık istekleri, liderlik tablosu)
⏳ Gamification sistemi (streak, rozet, seviye — XP motoru)
⏳ session_exercises tablosuna muscle_groups alanı (migration)
```

### ⏳ Faz 10 — Flutter
```
⏳ Flutter proje kurulumu (Dio + Riverpod + GoRouter)
⏳ flutter_secure_storage + token refresh
⏳ Auth ekranları (login, register)
⏳ Onboarding akışı (4 adım)
⏳ Dashboard (haftalık özet)
⏳ Tüm backend özelliklerinin ekranları
⏳ fl_chart ile grafikler
⏳ AI özellik ekranları
⏳ Kalori bankası ekranı
⏳ Barkod tarayıcı entegrasyonu
⏳ Kas grubu SVG anatomisi
⏳ Gamification ekranları (streak, rozet, seviye)
⏳ Sosyal ekranlar (arkadaşlar, liderlik tablosu)
⏳ Push notification / hatırlatıcılar
⏳ Dark / Light mode toggle
```

---

## 17. Flutter Uygulama Mimarisi

```
trackforge-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── endpoints.dart
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   ├── token_manager.dart
│   │   │   └── auth_interceptor.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── file_picker_helper.dart
│   ├── data/
│   │   ├── models/
│   │   └── repositories/
│   ├── providers/
│   ├── screens/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── measurements/
│   │   ├── notes/
│   │   ├── diet/
│   │   ├── exercises/
│   │   ├── water/
│   │   ├── sleep/
│   │   ├── preferences/
│   │   ├── reports/
│   │   ├── ai/
│   │   ├── social/
│   │   └── gamification/
│   └── widgets/
│       └── body_map/              ← SVG kas grubu anatomisi
└── pubspec.yaml
```

---

## 18. Teknoloji Kararları — Gerekçeler

| Karar | Alternatif | Neden bu? |
|---|---|---|
| FastAPI > Flask | Flask | Async native, Pydantic v2, otomatik OpenAPI |
| PostgreSQL > SQLite | SQLite | Production-ready, indexing, JSON desteği |
| SQLAlchemy 2.0 async | Tortoise ORM | FastAPI native uyum, tam async destek |
| Alembic | Manuel migration | Schema versiyon kontrolü şart |
| structlog | stdlib logging | JSON output, bağlam ekleme, test edilebilir |
| Riverpod > Bloc | Bloc | Compile-safe, az boilerplate, test kolay |
| flutter_secure_storage | SharedPreferences | JWT güvenli saklama için şart |
| DATE_BASED > week_id FK | weeks tablosu | Esneklik, sorgu kolaylığı |
| Repository pattern | Direkt ORM | Test edilebilirlik, soyutlama |
| Claude API > OpenAI | OpenAI | Daha uzun context, daha iyi analiz |
| Kalori bankası sistemi | Günlük sabit hedef | Motivasyon + bilimsel esneklik |
| onboarding_profile ayrı tablo | user_preferences'a ekle | Semantik ayrım, temiz Flutter akışı |
| Open Food Facts API | Manuel besin DB | Ücretsiz, 3M+ ürün, açık kaynak |
| Sadece arkadaşlar leaderboard | Global leaderboard | Gizlilik öncelikli tasarım |

---

*Bu doküman projenin yaşayan anayasası — her fazda ilgili bölümler güncellenecek.*  
*Son güncelleme: Nisan 2026 — v4.0*