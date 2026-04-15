# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v5.1 — Tam Güncel  
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
| Lokalizasyon | flutter_localizations + intl | latest | TR + EN çoklu dil desteği |
| AI — Analiz | Claude API (Anthropic) | claude-sonnet-4-5 | Haftalık özet, trend analizi, tavsiye |
| AI — Vision | Claude Vision | — | Fotoğraftan kalori hesaplama |
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
│   │  Screens → Providers (Riverpod) → ApiClient     │   │
│   │              ↓                                  │   │
│   │         Dio HTTP Client + AuthInterceptor        │   │
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
│   │           ├── water.py
│   │           ├── sleep.py
│   │           ├── preferences.py
│   │           ├── shopping.py
│   │           ├── reports.py
│   │           ├── ai.py
│   │           ├── onboarding.py          ← Faz 9 ✅
│   │           ├── barcode.py             ← Faz 9 ✅
│   │           ├── gamification.py        ← Faz 9 ✅
│   │           ├── social.py              ← Faz 9 ✅
│   │           ├── steps.py               ← Faz 9 ✅
│   │           └── cycle.py               ← Faz 9 ✅
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
│   │   │   ├── friendship.py              ← Faz 9 ✅
│   │   │   ├── streak.py                  ← Faz 9 ✅
│   │   │   ├── badge.py                   ← Faz 9 ✅
│   │   │   ├── user_level.py              ← Faz 9 ✅
│   │   │   ├── step_log.py                ← Faz 9 ✅
│   │   │   └── menstrual_cycle.py         ← Faz 9 ✅
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
│   │       ├── i_social_repository.py     ← Faz 9 ✅
│   │       ├── i_gamification_repository.py ← Faz 9 ✅
│   │       ├── i_step_log_repository.py   ← Faz 9 ✅
│   │       └── i_menstrual_cycle_repository.py ← Faz 9 ✅
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
│   │   │   ├── social_service.py          ← Faz 9 ✅
│   │   │   ├── gamification_service.py    ← Faz 9 ✅
│   │   │   ├── step_service.py            ← Faz 9 ✅
│   │   │   └── cycle_service.py           ← Faz 9 ✅
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
│   │       ├── social.py                  ← Faz 9 ✅
│   │       ├── gamification.py            ← Faz 9 ✅
│   │       ├── steps.py                   ← Faz 9 ✅
│   │       └── cycle.py                   ← Faz 9 ✅
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
│   │   │       ├── friendship_model.py    ← Faz 9 ✅
│   │   │       ├── streak_model.py        ← Faz 9 ✅
│   │   │       ├── badge_model.py         ← Faz 9 ✅
│   │   │       ├── user_level_model.py    ← Faz 9 ✅
│   │   │       ├── step_log_model.py      ← Faz 9 ✅
│   │   │       └── menstrual_cycle_model.py ← Faz 9 ✅
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
│   │   │   ├── social_repository.py       ← Faz 9 ✅
│   │   │   ├── gamification_repository.py ← Faz 9 ✅
│   │   │   ├── step_log_repository.py     ← Faz 9 ✅
│   │   │   └── menstrual_cycle_repository.py ← Faz 9 ✅
│   │   │
│   │   ├── storage/
│   │   │   └── file_storage_service.py
│   │   │
│   │   └── logging/
│   │       └── logger.py
│   │
│   ├── ai/
│   │   ├── client.py                      # claude-sonnet-4-5
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py
│   │   │   └── calorie_vision_analyzer.py
│   │   └── generators/
│   │       ├── workout_generator.py
│   │       ├── meal_advisor.py
│   │       ├── recipe_generator.py
│   │       └── calorie_bank_advisor.py
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

## 6. Veritabanı Şeması — 17 Tablo (Faz 1–9, Tümü ✅)

```sql
-- USERS
users: id, email, password_hash, full_name, created_at, updated_at

-- BODY MEASUREMENTS
body_measurements: id, user_id, date, weight_kg, body_fat_pct,
  muscle_mass_kg, waist_cm, chest_cm, hip_cm, arm_cm, leg_cm, created_at

-- WEEKLY NOTES
weekly_notes: id, user_id, date, title, content, energy_level, mood_score, created_at

-- MEAL COMPLIANCE (Kalori Bankası dahil)
meal_compliance: id, user_id, date, complied, compliance_rate,
  calories_consumed, calories_target, calorie_balance, weekly_bank_balance,
  notes, created_at

-- FILE UPLOADS
file_uploads: id, user_id, file_type, original_filename, stored_filename,
  file_path, mime_type, file_size_bytes, description, created_at

-- EXERCISE SESSIONS
exercise_sessions: id, user_id, date, duration_minutes, calories_burned,
  notes, created_at

-- SESSION EXERCISES
session_exercises: id, session_id→CASCADE, exercise_name, muscle_groups(JSON),
  sets, reps, weight_kg, notes, created_at

-- WATER LOGS
water_logs: id, user_id, date, amount_ml, target_ml, created_at, updated_at

-- SLEEP LOGS
sleep_logs: id, user_id, date, sleep_time, wake_time, duration_hours,
  quality_score, notes, created_at, updated_at

-- USER PREFERENCES
user_preferences: id, user_id(UNIQUE), height_cm, age, gender,
  activity_level, liked_foods(JSON), disliked_foods(JSON), allergies(JSON),
  diseases(JSON), blood_type, blood_values(JSON), workout_location,
  fitness_goal, created_at

-- SHOPPING ITEMS
shopping_items: id, user_id, name, quantity(VARCHAR), category,
  is_completed, price, currency, source, is_recurring, notes, created_at

-- ONBOARDING PROFILE ✅
onboarding_profile: id, user_id(UNIQUE), is_completed, goals(JSON),
  diet_preference, completed_at, created_at

-- STREAKS ✅
streaks: id, user_id, streak_type(water/exercise/sleep),
  current_streak, longest_streak, last_updated, created_at

-- BADGES ✅
badges: id, user_id, badge_key, badge_name, description, earned_at, created_at

-- USER LEVELS ✅
user_levels: id, user_id(UNIQUE), level, xp, level_title, updated_at

-- FRIENDSHIPS ✅
friendships: id, requester_id, addressee_id,
  status(pending/accepted/blocked), created_at, updated_at

-- STEP LOGS ✅
step_logs: id, user_id, date, step_count, target_steps(default 10000),
  distance_km, calories_burned, created_at

-- MENSTRUAL CYCLES ✅
menstrual_cycles: id, user_id, cycle_start_date, cycle_length_days(28),
  period_length_days(5), notes, created_at
```

---

## 7. Input Validasyon Kuralları

Backend (Pydantic Field validators) ve Flutter (form validation) her iki tarafta da uygulanır.

```
── ONBOARDING / USER PREFERENCES ────────────────
  height_cm      : 100 – 250 cm   (zorunlu)
  weight_kg      : 30  – 300 kg   (zorunlu)
  age            : 10  – 100      (zorunlu)
  gender         : male / female  (zorunlu, seçim)
  activity_level : enum seçimi    (zorunlu)

── VÜCUT ÖLÇÜMLERİ ──────────────────────────────
  weight_kg      : 30  – 300 kg
  body_fat_pct   : 1   – 60  %
  muscle_mass_kg : 10  – 150 kg
  waist_cm       : 30  – 200 cm
  chest_cm       : 30  – 200 cm
  hip_cm         : 30  – 200 cm
  arm_cm         : 10  – 100 cm
  leg_cm         : 10  – 120 cm

── SU TAKİBİ ────────────────────────────────────
  amount_ml      : 50  – 10000 ml (günlük max 10 litre)
  target_ml      : 500 – 10000 ml

── UYKU TAKİBİ ──────────────────────────────────
  duration_hours : 1   – 16  saat
  quality_score  : 1   – 10

── EGZERSİZ ─────────────────────────────────────
  duration_minutes : 1   – 600 dk
  calories_burned  : 0   – 5000 kcal
  sets             : 1   – 20
  reps             : 1   – 200
  weight_kg        : 0   – 500 kg

── DİYET / KALORİ ───────────────────────────────
  calories_consumed : 0  – 10000 kcal
  calories_target   : 0  – 10000 kcal

── HAFTALIK NOTLAR ──────────────────────────────
  energy_level   : 1   – 10
  mood_score     : 1   – 10

── ADIM SAYAR ───────────────────────────────────
  step_count     : 0   – 100000 adım/gün
  target_steps   : 1000 – 50000

── REGL TAKVİMİ ─────────────────────────────────
  cycle_length_days  : 20 – 45 gün
  period_length_days : 2  – 10 gün
```

---

## 8. API Endpoint Yapısı — Tümü ✅

```
BASE: /api/v1

── AUTH ──────────────────────────────────────────
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/me

── ONBOARDING ────────────────────────────────────
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

── BARKOD ────────────────────────────────────────
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

── WATER ─────────────────────────────────────────
POST   /water
GET    /water?start_date=&end_date=
GET    /water/date/{date}
PUT    /water/{id}
DELETE /water/{id}

── SLEEP ─────────────────────────────────────────
POST   /sleep
GET    /sleep?start_date=&end_date=
GET    /sleep/date/{date}
PUT    /sleep/{id}
DELETE /sleep/{id}

── PREFERENCES ───────────────────────────────────
POST   /preferences
GET    /preferences
PUT    /preferences
DELETE /preferences

── SHOPPING ──────────────────────────────────────
POST   /shopping                    # quantity: STRING (dikkat!)
GET    /shopping                    # {items: [...], summary: {...}} döner
GET    /shopping/recurring
PUT    /shopping/{id}
PATCH  /shopping/{id}/toggle
DELETE /shopping/{id}
DELETE /shopping/completed/clear

── REPORTS ───────────────────────────────────────
GET    /reports/weekly?reference_date=   # nested: {water, sleep, exercise, measurements}
GET    /reports/monthly?year=&month=     # nested: {water, sleep, exercise, measurements}

── AI ────────────────────────────────────────────
POST   /ai/weekly-summary           # {reference_date} → {summary}
POST   /ai/workout-plan             # {workout_location, fitness_goal, fitness_level, available_days}
POST   /ai/meal-advice              # {calorie_target}
POST   /ai/recipe                   # {available_ingredients, meal_type, calorie_limit}
POST   /ai/calorie-from-photo       # multipart/form-data, field: "file"

── SOCIAL ────────────────────────────────────────
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
GET    /social/leaderboard

── GAMIFICATION ──────────────────────────────────
GET    /gamification/summary        # {level, streaks, badges}
GET    /gamification/streaks
GET    /gamification/badges
GET    /gamification/level

── STEPS ─────────────────────────────────────────
POST   /steps
GET    /steps?start_date=&end_date=
GET    /steps/date/{date}
PUT    /steps/{id}

── CYCLE ─────────────────────────────────────────
POST   /cycle
GET    /cycle
GET    /cycle/history
PUT    /cycle/{id}
```

---

## 9. Flutter Uygulama Mimarisi — Faz 10 ✅ TAMAMLANDI

```
trackforge-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                    # GoRouter + MaterialApp + SplashScreen
│   │
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart     # Dio singleton + AuthInterceptor
│   │   │   ├── endpoints.dart      # Tüm URL sabitleri
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   └── token_manager.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── l10n/                   ← YENİ (Lokalizasyon)
│   │   │   ├── app_en.arb          # İngilizce string'ler
│   │   │   └── app_tr.arb          # Türkçe string'ler
│   │   └── utils/
│   │       └── date_utils.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart           ✅
│   │   │   └── register_screen.dart        ✅
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart      ✅ (4 adım + validasyon)
│   │   ├── home/
│   │   │   ├── home_screen.dart            ✅
│   │   │   ├── dashboard_screen.dart       ✅
│   │   │   └── more_screen.dart            ✅
│   │   ├── takip/
│   │   │   ├── takip_screen.dart           ✅
│   │   │   ├── olcum_tab.dart              ✅
│   │   │   ├── diyet_tab.dart              ✅
│   │   │   ├── su_tab.dart                 ✅
│   │   │   └── uyku_tab.dart               ✅
│   │   ├── egzersiz/
│   │   │   ├── egzersiz_screen.dart        ✅
│   │   │   └── seans_detay_screen.dart     ✅
│   │   ├── ai/
│   │   │   ├── ai_screen.dart              ✅
│   │   │   ├── weekly_summary_screen.dart  ✅
│   │   │   ├── workout_plan_screen.dart    ✅
│   │   │   ├── meal_advice_screen.dart     ✅
│   │   │   ├── recipe_screen.dart          ✅
│   │   │   └── calorie_vision_screen.dart  ✅
│   │   ├── raporlar/
│   │   │   └── raporlar_screen.dart        ✅
│   │   ├── sosyal/
│   │   │   └── sosyal_screen.dart          ✅
│   │   ├── alisveris/
│   │   │   └── alisveris_screen.dart       ✅
│   │   ├── profil/
│   │   │   └── profil_screen.dart          ✅
│   │   ├── gamification/
│   │   │   └── gamification_screen.dart    ✅
│   │   └── steps/
│   │       └── steps_screen.dart           ✅
│   │
│   └── widgets/
│       └── body_map/               # SVG kas grubu anatomisi (polish)
│
└── pubspec.yaml
```

### Flutter Ekran Durumu

| Ekran | Durum | Notlar |
|-------|-------|--------|
| Login / Register | ✅ | JWT flow |
| Onboarding | ✅ | 4 adım, backend entegre |
| Dashboard | ✅ | Gamification + haftalık özet |
| Takip — Ölçüm | ✅ | CRUD |
| Takip — Diyet | ✅ | AI planı shared_prefs'ten gösterilir |
| Takip — Su | ✅ | Dairesel progress, hızlı ekle |
| Takip — Uyku | ✅ | TimePicker, slider |
| Egzersiz | ✅ | Seans + detay + CRUD |
| AI — Haftalık Özet | ✅ | |
| AI — Antrenman Planı | ✅ | AI→otomatik seans oluşturma |
| AI — Diyet Tavsiyesi | ✅ | shared_prefs'e kaydeder |
| AI — Tarif Önerisi | ✅ | Chip listesi |
| AI — Vision Kalori | ✅ | multipart, manuel token |
| Raporlar | ✅ | fl_chart, haftalık+aylık |
| Gamification | ✅ | XP, seviye, streak, rozetler |
| Sosyal | ✅ | Arkadaşlar + liderlik tablosu |
| Alışveriş | ✅ | Liste + barkod tarayıcı |
| Adım Sayar | ✅ | Manuel giriş |
| Profil | ✅ | Görüntüleme + düzenleme + çıkış |
| More | ✅ | Menü kartları |

---

## 10. Kritik Teknik Kararlar & Bilinen Davranışlar

```
# Flutter / Dio
- Web'de flutter_secure_storage çalışmaz → shared_preferences kullanıldı
- Dio LinkedMap cast sorunu → Map<String, dynamic>.from() her yerde zorunlu
- Row içinde ElevatedButton → sonsuz genişlik hatası verir
  → SizedBox ile wrap et veya ayrı satıra al

# API Davranışları
- POST /ai/calorie-from-photo → multipart/form-data, field adı: "file"
  Manuel Authorization header gerekli (interceptor multipart'ta kaçırıyor)
- GET /shopping → {items: [...], summary: {...}} döner (direkt liste değil)
- POST /shopping → quantity: STRING bekleniyor (int değil)
- GET /reports/weekly + /reports/monthly → nested objeler
  (summary field'ı yok, direkt field'lar)
- POST /ai/workout-plan → field'lar: workout_location, fitness_goal,
  fitness_level, available_days (days_per_week değil)
- POST /ai/meal-advice → sadece calorie_target field'ı
- activity_level backend'den "moderate" dönebilir →
  _safeActivityLevel() ile handle et

# State Management
- bottomNavIndexProvider → BottomNav tab kontrolü
- takipTabIndexProvider → Takip ekranı iç tab kontrolü
- AI diyet tavsiyesi → last_meal_advice + last_meal_advice_date
  shared_prefs key'leriyle saklanır

# Onboarding
- register sonrası onboarding kaydı otomatik oluşmayabilir
  → GET+PUT/POST logic ile handle edildi
- is_completed = false → Flutter her girişte gösterir

# Gamification Response
- data['level'] → Map, data['streaks'] → List, data['badges'] → List
```

---

## 11. Tema Sistemi

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
Index:  0       1         2     3        4
                                    └── More Screen:
                                        Raporlar, Gamification,
                                        Adım Sayar, Sosyal,
                                        Alışveriş, Profil
```

---

## 12. Kalori Bankası Sistemi

```
TDEE = BMR × aktivite_katsayısı
BMR  = Mifflin-St Jeor formülü

Kilo verme : günlük_hedef = TDEE - 700
Kas yapma  : günlük_hedef = TDEE + 250
Koruma     : günlük_hedef = TDEE

calorie_balance     = calories_consumed - calories_target
weekly_bank_balance = son 7 günün (target - consumed) toplamı

Minimum kalori: 1500 kcal (güvenli sınır)
```

---

## 13. Regl Takvimi Sistemi

Kadın kullanıcılara özel, döngü bazlı kişiselleştirme katmanı.

```
Faz 1 — Menstrüasyon (Gün 1–5)
  → Hafif antrenman (yürüyüş, yoga, esneme)
  → Demir açısından zengin tarifler

Faz 2 — Foliküler (Gün 6–13)
  → Enerji artıyor, orta-yoğun antrenman ideal
  → Protein ağırlıklı beslenme

Faz 3 — Ovülasyon (Gün 14–16)
  → Zirve performans, yoğun antrenman ideal
  → Kalori hedefi biraz artırılabilir

Faz 4 — Luteal (Gün 17–28)
  → PMS başlangıcı, tatlı isteği
  → Antrenman yoğunluğunu azalt
  → Magnezyum açısından zengin yiyecekler

Entegrasyon:
  - AI antrenman planı → faz bilgisini input olarak alır
  - AI tarif önerici → faz bazlı besin önerileri
  - Haftalık AI raporu → döngü fazını yoruma katar
  - Hatırlatıcı → regl yaklaşıyor bildirimi (3 gün önce)
```

---

## 14. Adım Sayar Sistemi

```
Flutter: pedometer paketi (polish aşamasında aktif edilecek)
Şu an: Manuel giriş ile çalışıyor

Hesaplama:
  distance_km     = step_count × 0.000762
  calories_burned = step_count × 0.04

Gamification:
  - "10.000 adım" günlük rozet
  - Adım streak'i
  - Her 1000 adım → +5 XP

Varsayılan hedef: 10.000 adım/gün
```

---

## 15. Gamification Sistemi

### Seviye Sistemi

| Seviye | Başlık | XP |
|--------|--------|----|
| 1 | Beginner | 0 |
| 2 | Active | 500 |
| 3 | Fit | 1500 |
| 4 | Athlete | 3000 |
| 5 | Champion | 6000 |

**XP Kaynakları:** Antrenman +50 · Su hedefi +20 · Uyku +15 · Rozet +100 · Haftalık rapor +10

### Rozet Sistemi

| Badge Key | Açıklama | Tetikleyici |
|-----------|----------|-------------|
| `first_workout` | İlk Antrenman 💪 | İlk seans |
| `7_day_water` | 7 Gün Su 💧 | Water streak = 7 |
| `30_day_water` | 30 Gün Su 🏆 | Water streak = 30 |
| `weight_loss_5kg` | 5 kg Kayıp ⚡ | Ölçüm farkı ≥ 5 kg |
| `weight_loss_10kg` | 10 kg Kayıp 🔥 | Ölçüm farkı ≥ 10 kg |
| `first_photo` | İlk Fotoğraf 📸 | İlk fotoğraf yüklendi |
| `streak_warrior` | Streak Savaşçısı ⚔️ | Exercise streak = 7 |

---

## 16. Çoklu Dil Desteği

```
Desteklenen diller: Türkçe (TR) · İngilizce (EN)
Paket: flutter_localizations + intl

Dosya yapısı:
  core/l10n/
  ├── app_tr.arb    ← Türkçe string'ler (varsayılan)
  └── app_en.arb    ← İngilizce string'ler

Kapsam:
  - Tüm ekran başlıkları
  - Form label ve hata mesajları
  - Buton metinleri
  - AI yanıt dışı tüm statik metinler
  - Input validasyon mesajları

Dil seçimi: Profil ekranından değiştirilebilir,
            shared_prefs'e kaydedilir.

Gelecek: Kullanıcı talebi olursa yeni dil eklenebilir
         (ARB dosyası eklemek yeterli)
```

---

## 17. AI Layer Detayı

```python
ai/
├── client.py               # Claude API — claude-sonnet-4-5
├── analyzers/
│   ├── weekly_analyzer.py  # Haftalık özet
│   └── calorie_vision_analyzer.py  # multipart → base64 → Claude Vision
└── generators/
    ├── workout_generator.py  # workout_location, fitness_goal, fitness_level, available_days
    ├── meal_advisor.py       # calorie_target bazlı → macros, meal_suggestions
    ├── recipe_generator.py   # ingredients + meal_type + calorie_limit → tarif
    └── calorie_bank_advisor.py
```

---

## 18. Güvenlik Mimarisi

```
JWT Flow:
  1. POST /auth/login → access_token (30dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 → POST /auth/refresh (AuthInterceptor otomatik yapar)
  4. Flutter: shared_preferences (web uyumluluğu için)

Env:
  DATABASE_URL, SECRET_KEY, ALGORITHM
  ACCESS_TOKEN_EXPIRE_MINUTES=30
  REFRESH_TOKEN_EXPIRE_DAYS=7
  ANTHROPIC_API_KEY          (aktif — claude-sonnet-4-5)
  OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org
```

---

## 19. Geliştirme Fazları

### ✅ Faz 1 — Auth Sistemi
### ✅ Faz 2 — Core CRUD
### ✅ Faz 3 — Dosya İşlemleri
### ✅ Faz 4 — Egzersiz Takibi
### ✅ Faz 5 — Su, Uyku, Tercihler, Alışveriş
### ✅ Faz 6 — Raporlar
### ✅ Faz 7 — Polish & CI/CD
### ✅ Faz 8 — AI Entegrasyonu (Claude API + Vision)
### ✅ Faz 9 — Onboarding, Barkod, Gamification, Sosyal, Steps, Cycle
### ✅ Faz 10 — Flutter (Tüm ekranlar kodlandı ve test edildi)

---

## 20. Sonraki Aşama: Polish · Test · Deploy · Product

### Polish Listesi
1. `flutter_markdown` — AI yanıtlarında ## ve ** render
2. Antrenman planı egzersiz kartları — ham JSON görünümü düzelt
3. YouTube link entegrasyonu — egzersiz form videoları
4. Dark mode toggle
5. Gerçek adım sayarı — `pedometer` paketi aktif edilecek
6. Regl takvimi ekranı — `menstrual_cycles` entegrasyonu
7. Push notification / hatırlatıcılar
8. Kas grubu SVG anatomisi
9. Tüm form alanlarına input validasyonu (Flutter + Pydantic)
10. Çoklu dil desteği — TR + EN (flutter_localizations + intl)

### Deploy
- Backend: Railway (aktif) — domain bağlı, Swagger erişilebilir
- Landing page: Railway domain'e index sayfası ekleniyor
- Flutter: APK build → Google Play (Android önce)
- iOS: Arkadaş Mac'i üzerinden Xcode build

### Product
- Freemium model: Free / PRO (~149 TL) / PRO+
- "Founder Access" lansmanı
- MAC+ (MACFit) rekabet analizi tamamlandı

---

## 21. Git Stratejisi

```
main       ← production-ready
develop    ← aktif geliştirme
feature/*  ← tek özellik
fix/*      ← bug fix
docs/*     ← dokümantasyon

Commit: feat / fix / refactor / test / docs / chore
```

---

*Bu doküman projenin yaşayan anayasası.*
*Son güncelleme: Nisan 2026 — v5.1*
*Backend: Faz 1-9 tamamlandı · Flutter: Faz 10 tamamlandı*
*Sonraki: Polish · Test · Deploy · Product*