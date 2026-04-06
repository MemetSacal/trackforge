# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v4.1 — Güncel & Genişletilmiş  
**Tarih:** Nisan 2026  
**Mimari:** Clean Architecture + Repository Pattern  
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First

---

## 1. Proje Kimliği

| Alan | Detay |
|------|-------|
| **Ad** | TrackForge — AI-Powered Personal Health & Fitness System |
| **Amaç** | Diyet, ölçüm, fotoğraf, egzersiz, uyku, su takibi ve notları haftalık bazda takip eden; kan değerleri, hastalık geçmişi ve kişisel tercihler doğrultusunda AI destekli kişiselleştirilmiş sağlık, beslenme ve antrenman tavsiyesi sunan platform. |
| **Mimari** | Clean Architecture + Repository Pattern |
| **Zaman Ref.** | DATE_BASED (hafta hesaplanan, saklanmayan) |
| **AI Hazır** | Evet (pluggable AI layer — Claude API entegre) |
| **GitHub** | https://github.com/MemetSacal/trackforge |

---

## 2. Teknoloji Stack'i

| Katman | Teknoloji | Versiyon | Neden |
|--------|-----------|----------|-------|
| Backend | FastAPI | 0.115+ | Async, otomatik OpenAPI, production-ready |
| Veritabanı | PostgreSQL | 16+ | ACID, JSON desteği, güçlü indexing |
| ORM | SQLAlchemy | 2.0+ | Async destekli, type-safe |
| Migration | Alembic | latest | Schema versiyon yönetimi |
| Auth | JWT (python-jose) | latest | Stateless, mobil uyumlu |
| Validation | Pydantic v2 | 2.0+ | FastAPI ile native entegrasyon |
| Dosya Depolama | Filesystem → AWS S3 | — | Başlangıç local, production S3 |
| Loglama | structlog | latest | Structured JSON logging |
| Test | pytest + httpx | latest | Async test desteği |
| Container | Docker + Compose | latest | Reproducible environment |
| CI/CD | GitHub Actions | — | Otomatik lint pipeline |
| Mobil | Flutter | 3.x | iOS + Android tek codebase |
| HTTP Client | Dio | latest | Interceptor, retry, token refresh |
| State Mgmt | Riverpod | 2.x | Test edilebilir, compile-safe |
| Grafik | fl_chart | latest | Native Flutter charts |
| AI — Analiz | Claude API (Anthropic) | — | Haftalık özet, trend analizi, tavsiye |
| AI — Vision | Claude Vision | — | Fotoğraftan kalori hesaplama |
| AI — Görsel | DALL-E 3 / Stable Diffusion | — | Hedef vücut görselleştirme (beklemede) |
| Barkod | Open Food Facts API | — | Ücretsiz, geniş besin veritabanı |
| Adım Sayar | pedometer (Flutter) | latest | Telefon sensörü ile native adım takibi |

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
│           domain/interfaces/                │
├─────────────────────────────────────────────┤
│         INFRASTRUCTURE LAYER                │  ← DB, dosya, dış servisler
│   repositories/ + storage/ + logging/       │
├─────────────────────────────────────────────┤
│              AI LAYER                       │  ← Pluggable analiz modülü
│               ai/                           │
└─────────────────────────────────────────────┘

Bağımlılık kuralı: Oklar sadece içe doğru akar.
Domain hiçbir şeye bağımlı değil.
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
│   │           ├── onboarding.py          ← Faz 9 ✅
│   │           ├── barcode.py             ← Faz 9 ✅
│   │           ├── gamification.py        ← Faz 9 ✅
│   │           ├── social.py              ← Faz 9 ⏳
│   │           ├── steps.py               ← Faz 9 ⏳
│   │           └── cycle.py               ← Faz 9 ⏳
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
│   │   │   ├── water_log.py
│   │   │   ├── sleep_log.py
│   │   │   ├── user_preference.py
│   │   │   ├── onboarding_profile.py      ← Faz 9 ✅
│   │   │   ├── friendship.py              ← Faz 9 ⏳
│   │   │   ├── streak.py                  ← Faz 9 ✅
│   │   │   ├── badge.py                   ← Faz 9 ✅
│   │   │   ├── user_level.py              ← Faz 9 ✅
│   │   │   ├── step_log.py                ← Faz 9 ⏳
│   │   │   └── menstrual_cycle.py         ← Faz 9 ⏳
│   │   │
│   │   └── interfaces/
│   │       ├── i_user_repository.py
│   │       ├── i_measurement_repository.py
│   │       ├── i_note_repository.py
│   │       ├── i_meal_compliance_repository.py
│   │       ├── i_file_upload_repository.py
│   │       ├── i_exercise_session_repository.py
│   │       ├── i_session_exercise_repository.py
│   │       ├── i_water_log_repository.py
│   │       ├── i_sleep_log_repository.py
│   │       ├── i_user_preference_repository.py
│   │       ├── i_onboarding_repository.py ← Faz 9 ✅
│   │       ├── i_social_repository.py     ← Faz 9 ⏳
│   │       ├── i_gamification_repository.py ← Faz 9 ✅
│   │       ├── i_step_log_repository.py   ← Faz 9 ⏳
│   │       └── i_menstrual_cycle_repository.py ← Faz 9 ⏳
│   │
│   ├── application/
│   │   ├── services/
│   │   │   ├── auth_service.py
│   │   │   ├── measurement_service.py
│   │   │   ├── note_service.py
│   │   │   ├── meal_compliance_service.py
│   │   │   ├── file_upload_service.py
│   │   │   ├── exercise_service.py
│   │   │   ├── water_service.py
│   │   │   ├── sleep_service.py
│   │   │   ├── preference_service.py
│   │   │   ├── shopping_service.py
│   │   │   ├── report_service.py
│   │   │   ├── onboarding_service.py      ← Faz 9 ✅
│   │   │   ├── social_service.py          ← Faz 9 ⏳
│   │   │   ├── gamification_service.py    ← Faz 9 ✅
│   │   │   ├── step_service.py            ← Faz 9 ⏳
│   │   │   └── cycle_service.py           ← Faz 9 ⏳
│   │   │
│   │   └── schemas/
│   │       ├── auth.py
│   │       ├── measurement.py
│   │       ├── note.py
│   │       ├── meal_compliance.py
│   │       ├── file_upload.py
│   │       ├── exercise.py
│   │       ├── water.py
│   │       ├── sleep.py
│   │       ├── preference.py
│   │       ├── shopping.py
│   │       ├── report.py
│   │       ├── ai.py
│   │       ├── onboarding.py              ← Faz 9 ✅
│   │       ├── barcode.py                 ← Faz 9 ✅
│   │       ├── social.py                  ← Faz 9 ⏳
│   │       ├── gamification.py            ← Faz 9 ✅
│   │       ├── steps.py                   ← Faz 9 ⏳
│   │       └── cycle.py                   ← Faz 9 ⏳
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
│   │   │       ├── water_log_model.py
│   │   │       ├── sleep_log_model.py
│   │   │       ├── user_preference_model.py
│   │   │       ├── onboarding_profile_model.py ← Faz 9 ✅
│   │   │       ├── friendship_model.py    ← Faz 9 ⏳
│   │   │       ├── streak_model.py        ← Faz 9 ✅
│   │   │       ├── badge_model.py         ← Faz 9 ✅
│   │   │       ├── user_level_model.py    ← Faz 9 ✅
│   │   │       ├── step_log_model.py      ← Faz 9 ⏳
│   │   │       └── menstrual_cycle_model.py ← Faz 9 ⏳
│   │   │
│   │   ├── repositories/
│   │   │   ├── user_repository.py
│   │   │   ├── measurement_repository.py
│   │   │   ├── note_repository.py
│   │   │   ├── meal_compliance_repository.py
│   │   │   ├── file_upload_repository.py
│   │   │   ├── exercise_session_repository.py
│   │   │   ├── session_exercise_repository.py
│   │   │   ├── water_log_repository.py
│   │   │   ├── sleep_log_repository.py
│   │   │   ├── user_preference_repository.py
│   │   │   ├── onboarding_repository.py   ← Faz 9 ✅
│   │   │   ├── social_repository.py       ← Faz 9 ⏳
│   │   │   ├── gamification_repository.py ← Faz 9 ✅
│   │   │   ├── step_log_repository.py     ← Faz 9 ⏳
│   │   │   └── menstrual_cycle_repository.py ← Faz 9 ⏳
│   │   │
│   │   ├── storage/
│   │   │   └── file_storage_service.py
│   │   │
│   │   └── logging/
│   │       └── logger.py
│   │
│   ├── ai/
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
├── uploads/
├── doc/
├── .github/workflows/ci.yml
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
├── calories_consumed   FLOAT
├── calories_target     FLOAT
├── calorie_balance     FLOAT
├── weekly_bank_balance FLOAT
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
├── muscle_groups   JSON                    ← Faz 9 ⏳ (kas grubu anatomisi)
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
├── height_cm       FLOAT
├── age             INT
├── gender          VARCHAR
├── activity_level  VARCHAR
├── liked_foods     JSON
├── disliked_foods  JSON
├── allergies       JSON
├── diseases        JSON
├── blood_type      VARCHAR
├── blood_values    JSON
├── workout_location VARCHAR
├── fitness_goal    VARCHAR
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

### Faz 9 Tabloları

```sql
-- ONBOARDING PROFILE ✅
onboarding_profile
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── is_completed    BOOLEAN     default False
├── goals           JSON
├── diet_preference VARCHAR
├── completed_at    TIMESTAMPTZ
└── created_at      TIMESTAMPTZ

-- STREAKS ✅
streaks
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── streak_type     VARCHAR     ← water/exercise/sleep
├── current_streak  INT         default 0
├── longest_streak  INT         default 0
├── last_updated    DATE
└── created_at      TIMESTAMPTZ

-- BADGES ✅
badges
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── badge_key       VARCHAR
├── badge_name      VARCHAR
├── description     TEXT
├── earned_at       TIMESTAMPTZ
└── created_at      TIMESTAMPTZ

-- USER LEVELS ✅
user_levels
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── level           INT         default 1
├── xp              INT         default 0
├── level_title     VARCHAR
└── updated_at      TIMESTAMPTZ

-- FRIENDSHIPS ⏳
friendships
├── id              VARCHAR     PK
├── requester_id    VARCHAR     FK → users
├── addressee_id    VARCHAR     FK → users
├── status          VARCHAR     ← pending/accepted/blocked
├── created_at      TIMESTAMPTZ
└── updated_at      TIMESTAMPTZ

-- STEP LOGS ⏳
step_logs
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── step_count      INT         NOT NULL
├── target_steps    INT         default 10000
├── distance_km     FLOAT
├── calories_burned FLOAT
└── created_at      TIMESTAMPTZ

-- MENSTRUAL CYCLES ⏳
menstrual_cycles
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── cycle_start_date DATE       NOT NULL
├── cycle_length_days INT       default 28
├── period_length_days INT      default 5
├── notes           TEXT
└── created_at      TIMESTAMPTZ
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

── ONBOARDING ──────────────────────────────────── ✅ Faz 9
POST   /onboarding
GET    /onboarding
PUT    /onboarding
POST   /onboarding/complete

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

── BARKOD ──────────────────────────────────────── ✅ Faz 9
GET    /barcode/{barcode}

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
POST   /ai/weekly-summary           ✅
POST   /ai/workout-plan             ✅
POST   /ai/meal-advice              ✅
POST   /ai/recipe                   ✅
POST   /ai/calorie-from-photo       ✅
POST   /ai/body-visualization       ⏳ beklemede

── SOCIAL ──────────────────────────────────────── ⏳ Faz 9
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
GET    /social/leaderboard

── GAMİFİCATİON ──────────────────────────────────  ✅ Faz 9
GET    /gamification/summary
GET    /gamification/streaks
GET    /gamification/badges
GET    /gamification/level

── ADIM SAYAR ──────────────────────────────────── ⏳ Faz 9
POST   /steps
GET    /steps?start_date=&end_date=
GET    /steps/date/{date}

── REGL TAKVİMİ ────────────────────────────────── ⏳ Faz 9
POST   /cycle
GET    /cycle
GET    /cycle/history
PUT    /cycle/{id}
```

---

## 8. Kalori Bankası Sistemi

```
Temel Mantık:
  TDEE = BMR × aktivite_katsayısı
  BMR  = Mifflin-St Jeor formülü

  Kilo verme : günlük_hedef = TDEE - 700
  Kas yapma  : günlük_hedef = TDEE + 250
  Koruma     : günlük_hedef = TDEE

  calorie_balance     = calories_consumed - calories_target
  weekly_bank_balance = son 7 günün (target - consumed) toplamı

Güvenli Sınırlar:
  Minimum kalori: 1500 kcal
  Maksimum kaçamak: TDEE + weekly_bank_balance

Örnek (kilo verme, hedef 1600 kcal/gün):
  Pazartesi: 1200 aldı → bank: +400 kredi
  Salı:      1400 aldı → bank: +600 kredi
  Çarşamba:  2200 aldı → bank:   0 kredi
  Cuma:      ?    → "400 kredin var, bugün 2000'e kadar yiyebilirsin 🎉"
```

---

## 9. Onboarding Akışı

```
Adım 1 — Hedefler (max 3 seçim)
  Kilo Vermek / Aynı Kiloda Kalmak / Kilo Almak /
  Kas Kazanmak / Diyetimi Değiştir / Öğün Planla /
  Stresi Yönetmek / Aktif Kal

Adım 2 — Temel Bilgiler
  Boy (cm), Kilo (kg), Yaş, Cinsiyet

Adım 3 — Aktivite Seviyesi
  Sedanter / Hafif Aktif / Orta Aktif / Aktif / Çok Aktif

Adım 4 — Diyet Tercihi
  Normal / Vejetaryen / Vegan / Glutensiz

Kurallar:
  - is_completed = false → Flutter her girişte gösterir
  - is_completed = true  → bir daha gösterilmez
  - PUT /onboarding ile sonradan değiştirilebilir
  - Temel bilgiler user_preferences'a da yazılır (BMR/TDEE için)
```

---

## 10. Regl Takvimi Sistemi

```
Döngü Fazları ve AI Kişiselleştirme:

  Faz 1 — Menstrüasyon (Gün 1–5)
    → Hafif antrenman (yürüyüş, yoga)
    → Demir açısından zengin tarifler

  Faz 2 — Foliküler (Gün 6–13)
    → Orta-yoğun antrenman ideal
    → Protein ağırlıklı beslenme

  Faz 3 — Ovülasyon (Gün 14–16)
    → Zirve performans dönemi
    → Yoğun antrenman, HIIT ideal

  Faz 4 — Luteal (Gün 17–28)
    → PMS dönemi, yoğunluğu azalt
    → Magnezyum açısından zengin yiyecekler

Entegrasyon:
  - AI antrenman planı faz bilgisini input alır
  - AI tarif önerici faz bazlı öneri yapar
  - Haftalık AI raporu faz yorumu katar
```

---

## 11. Adım Sayar Sistemi

```
Flutter Tarafı:
  - pedometer paketi telefon sensörünü dinler
  - Gün sonu POST /steps ile gönderilir

Hesaplama:
  distance_km     = step_count × 0.000762
  calories_burned = step_count × 0.04

Gamification:
  - 10.000 adım → günlük rozet
  - Her 1000 adım → +5 XP
```

---

## 12. Gamification Sistemi

### Streak Sistemi

| Streak Türü | Tetikleyici |
|---|---|
| `water` | Günlük su hedefine ulaşıldı |
| `exercise` | O gün antrenman seansı oluşturuldu |
| `sleep` | Uyku logu girildi ve quality_score ≥ 6 |

### Rozet Sistemi

| Badge Key | Açıklama | Tetikleyici |
|---|---|---|
| `first_workout` | İlk Antrenman 💪 | İlk seans |
| `7_day_water` | 7 Gün Su 💧 | Water streak = 7 |
| `30_day_water` | 30 Gün Su 🏆 | Water streak = 30 |
| `weight_loss_5kg` | 5 kg Kayıp ⚡ | Ölçüm farkı ≥ 5 kg |
| `weight_loss_10kg` | 10 kg Kayıp 🔥 | Ölçüm farkı ≥ 10 kg |
| `first_photo` | İlk Fotoğraf 📸 | İlk fotoğraf yüklendi |
| `streak_warrior` | Streak Savaşçısı ⚔️ | Exercise streak = 7 |

### Seviye Sistemi

| Seviye | Başlık | XP |
|---|---|---|
| 1 | Beginner | 0 |
| 2 | Active | 500 |
| 3 | Fit | 1500 |
| 4 | Athlete | 3000 |
| 5 | Champion | 6000 |

**XP Kaynakları:** Antrenman +50 · Su hedefi +20 · Uyku +15 · Rozet +100 · Haftalık rapor +10

---

## 13. Sosyal Sistem

```
Arkadaşlık:
  - Email ile arama
  - İstek gönder → kabul/red
  - Status: pending / accepted / blocked

Liderlik Tablosu:
  - Sadece arkadaşlar arası
  - Haftalık XP'ye göre sıralama
  - Rolling 7 gün
```

---

## 14. AI Layer Detayı

```python
ai/
├── client.py               # Claude API — claude-sonnet-4-5
├── analyzers/
│   ├── weekly_analyzer.py  # Haftalık özet
│   └── calorie_vision_analyzer.py  # Fotoğraftan kalori
└── generators/
    ├── workout_generator.py  # Antrenman planı
    ├── meal_advisor.py       # BMR/TDEE bazlı diyet
    ├── recipe_generator.py   # Malzeme bazlı tarif
    └── calorie_bank_advisor.py  # ileride
```

---

## 15. Güvenlik Mimarisi

```
JWT Flow:
  1. POST /auth/login → access_token (15dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 → POST /auth/refresh
  4. Flutter: flutter_secure_storage

Env:
  DATABASE_URL, SECRET_KEY, ALGORITHM
  ACCESS_TOKEN_EXPIRE_MINUTES=15
  REFRESH_TOKEN_EXPIRE_DAYS=7
  CLAUDE_API_KEY         (aktif)
  OPENAI_API_KEY         (opsiyonel)
  STABILITY_API_KEY      (beklemede)
  OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org
```

---

## 16. Git Stratejisi

```
main       ← production-ready
develop    ← aktif geliştirme
feature/*  ← tek özellik
fix/*      ← bug fix
docs/*     ← dokümantasyon

Commit: feat / fix / refactor / test / docs / chore
```

---

## 17. Geliştirme Fazları (Roadmap)

### ✅ Faz 1 — Auth Sistemi
- Docker Compose, FastAPI iskeleti, Alembic, JWT, structlog, Swagger

### ✅ Faz 2 — Core CRUD
- Body measurements, weekly notes, meal compliance, tarih bazlı sorgulama

### ✅ Faz 3 — Dosya İşlemleri
- Fotoğraf/PDF yükleme, indirme, silme, UUID isimlendirme, async write

### ✅ Faz 4 — Egzersiz Takibi
- Exercise sessions + session exercises, cascade delete, OneToMany

### ✅ Faz 5 — Yeni Backend Özellikleri
- Su, uyku, tercihler (fiziksel profil dahil), alışveriş listesi

### ✅ Faz 6 — Raporlar
- Haftalık + aylık raporlar, özet hesaplamalar

### ✅ Faz 7 — Polish & Deployment
- GitHub Actions, README, requirements.txt, .env.example

### ✅ Faz 8 — AI Entegrasyonu
- Claude API, haftalık özet, antrenman planı, diyet tavsiyesi
- Tarif önerisi, Claude Vision, kalori bankası sistemi

### ⏳ Faz 9 — Yeni Backend Özellikleri
```
✅ Onboarding CRUD (4 adımlı ilk kurulum)
✅ Barkod proxy (Open Food Facts API)
✅ Gamification (streak, rozet, XP, seviye motoru)
⏳ Sosyal sistem (arkadaşlık, liderlik tablosu)
⏳ session_exercises.muscle_groups migration
⏳ Adım sayar CRUD (step_logs)
⏳ Regl takvimi CRUD (menstrual_cycles)
```

### ⏳ Faz 10 — Flutter
```
⏳ Proje kurulumu (Dio + Riverpod + GoRouter)
⏳ flutter_secure_storage + token refresh
⏳ Auth ekranları (login, register)
⏳ Onboarding akışı (4 adım)
⏳ Dashboard (haftalık özet + AI koç kartı)
⏳ Takip ekranları (ölçüm, diyet, su, uyku)
⏳ Egzersiz ekranları + kas grubu SVG anatomisi
⏳ AI ekranları (özet, antrenman, diyet, tarif, fotoğraf kalori)
⏳ Kalori bankası ekranı
⏳ Alışveriş listesi (barkod tarayıcı dahil)
⏳ Raporlar (haftalık + aylık, fl_chart grafikler)
⏳ Sosyal ekranlar (arkadaşlar, liderlik tablosu)
⏳ Gamification ekranları (streak, rozet, seviye, XP)
⏳ Adım sayar ekranı (günlük + haftalık grafik)
⏳ Regl takvimi ekranı (faz bilgisi + AI önerileri)
⏳ Profil ekranı (sağlık bilgileri, tercihler)
⏳ Push notification / hatırlatıcılar
⏳ Dark / Light mode toggle
```

---

## 18. Flutter Uygulama Mimarisi

```
trackforge-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # GoRouter + tema
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart     # Dio instance + interceptors
│   │   │   ├── endpoints.dart      # URL sabitleri
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   ├── token_manager.dart  # flutter_secure_storage
│   │   │   └── auth_interceptor.dart # Token refresh
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart     # Dark + Light tema renkleri
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── file_picker_helper.dart
│   │
│   ├── data/
│   │   ├── models/                 # JSON ↔ Dart modeller
│   │   └── repositories/          # API çağrıları
│   │
│   ├── providers/                  # Riverpod state yönetimi
│   │
│   ├── screens/
│   │   ├── auth/                   # login, register
│   │   ├── onboarding/             # 4 adımlı ilk kurulum
│   │   ├── home/                   # dashboard (AI koç kartı, seriler, stats)
│   │   ├── takip/                  # ölçümler, diyet, su, uyku
│   │   ├── egzersiz/               # seanslar, kas grubu anatomisi
│   │   ├── ai/                     # haftalık özet, antrenman, diyet, tarif, vision
│   │   ├── raporlar/               # haftalık + aylık, fl_chart
│   │   ├── sosyal/                 # arkadaşlar, liderlik tablosu
│   │   ├── gamification/           # streak, rozet, seviye
│   │   ├── alisveris/              # liste + barkod tarayıcı
│   │   ├── steps/                  # adım sayar
│   │   ├── cycle/                  # regl takvimi
│   │   └── profil/                 # sağlık bilgileri, tercihler, ayarlar
│   │
│   └── widgets/
│       ├── body_map/               # SVG kas grubu anatomisi
│       ├── water_progress_bar.dart
│       ├── sleep_quality_card.dart
│       ├── streak_card.dart
│       ├── calorie_bank_card.dart
│       └── ai_coach_card.dart      # Dashboard AI koç kartı
│
└── pubspec.yaml
```

### Tema Sistemi

```dart
// Dark Mode
bg: '#0C0D10'
bgCard: '#141620'
accent: '#FFB020'     // altın sarısı
positive: '#34D399'
danger: '#FF5555'

// Light Mode  
bg: '#F0F2F6'
bgCard: '#FFFFFF'
accent: '#FF6B2B'     // turuncu
positive: '#059669'
danger: '#DC2626'
```

### Bottom Navigation

```
Ana Sayfa | Takip | Egzersiz | AI | Daha Fazla ▾
                                    └── Raporlar
                                    └── Sosyal
                                    └── Alışveriş
                                    └── Profil
```

---

## 19. Teknoloji Kararları — Gerekçeler

| Karar | Alternatif | Neden bu? |
|-------|------------|-----------|
| FastAPI > Flask | Flask | Async native, Pydantic v2, otomatik OpenAPI |
| PostgreSQL > SQLite | SQLite | Production-ready, indexing, JSON desteği |
| SQLAlchemy 2.0 async | Tortoise ORM | FastAPI native uyum |
| Alembic | Manuel migration | Schema versiyon kontrolü |
| Riverpod > Bloc | Bloc | Compile-safe, az boilerplate |
| flutter_secure_storage | SharedPreferences | JWT güvenli saklama |
| Claude API > OpenAI | OpenAI | Daha uzun context, daha iyi analiz |
| Kalori bankası | Günlük sabit hedef | Motivasyon + bilimsel esneklik |
| Open Food Facts | Manuel besin DB | Ücretsiz, 3M+ ürün |
| Arkadaşlar leaderboard | Global leaderboard | Gizlilik öncelikli |
| pedometer (Flutter) | Manuel giriş | Telefon sensörü, otomatik |
| Faz bazlı regl | Genel öneri | Bilimsel, kadın kullanıcıya özel |

---

*Bu doküman projenin yaşayan anayasası.*  
*Son güncelleme: Nisan 2026 — v4.1*