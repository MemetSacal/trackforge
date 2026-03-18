# TrackForge — Mimari Tasarım Dokümanı
**Versiyon:** v3.0 — Güncel & Genişletilmiş  
**Tarih:** Mart 2026  
**Mimari:** Clean Architecture + Repository Pattern  
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First

---

## 1. Proje Kimliği

```
Ad         : TrackForge — AI-Powered Personal Health & Fitness System
Amaç       : Diyet, ölçüm, fotoğraf, egzersiz, uyku, su takibi ve notları
             haftalık bazda takip eden; kan değerleri, hastalık geçmişi ve
             kişisel tercihler doğrultusunda AI destekli kişiselleştirilmiş
             sağlık, beslenme ve antrenman tavsiyesi sunan platform.
Mimari     : Clean Architecture + Repository Pattern
Zaman Ref. : DATE_BASED (hafta hesaplanan, saklanmayan)
AI Hazır   : Evet (pluggable AI layer — Claude API entegre)
GitHub     : https://github.com/MemetSacal/trackforge
```

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
│   │           ├── water.py              ← Faz 5
│   │           ├── sleep.py              ← Faz 5
│   │           ├── preferences.py        ← Faz 5
│   │           ├── shopping.py           ← Faz 5
│   │           ├── reports.py            ← Faz 6
│   │           └── ai.py                ← Faz 8
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
│   │   │   ├── water_log.py             ← Faz 5
│   │   │   ├── sleep_log.py             ← Faz 5
│   │   │   └── user_preference.py       ← Faz 5
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
│   │       └── i_user_preference_repository.py  ← Faz 5
│   │
│   ├── application/
│   │   ├── services/
│   │   │   ├── auth_service.py
│   │   │   ├── measurement_service.py
│   │   │   ├── note_service.py
│   │   │   ├── meal_compliance_service.py
│   │   │   ├── file_upload_service.py
│   │   │   ├── exercise_service.py
│   │   │   ├── water_service.py         ← Faz 5
│   │   │   ├── sleep_service.py         ← Faz 5
│   │   │   ├── preference_service.py    ← Faz 5
│   │   │   ├── shopping_service.py      ← Faz 5
│   │   │   └── report_service.py        ← Faz 6
│   │   │
│   │   └── schemas/
│   │       ├── auth.py
│   │       ├── measurement.py
│   │       ├── note.py
│   │       ├── meal_compliance.py
│   │       ├── file_upload.py
│   │       ├── exercise.py
│   │       ├── water.py                 ← Faz 5
│   │       ├── sleep.py                 ← Faz 5
│   │       ├── preference.py            ← Faz 5
│   │       ├── shopping.py              ← Faz 5
│   │       ├── report.py               ← Faz 6
│   │       └── ai.py                   ← Faz 8
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
│   │   │       ├── water_log_model.py   ← Faz 5
│   │   │       ├── sleep_log_model.py   ← Faz 5
│   │   │       └── user_preference_model.py ← Faz 5
│   │   │
│   │   ├── repositories/
│   │   │   ├── user_repository.py
│   │   │   ├── measurement_repository.py
│   │   │   ├── note_repository.py
│   │   │   ├── meal_compliance_repository.py
│   │   │   ├── file_upload_repository.py
│   │   │   ├── exercise_session_repository.py
│   │   │   ├── session_exercise_repository.py
│   │   │   ├── water_log_repository.py  ← Faz 5
│   │   │   ├── sleep_log_repository.py  ← Faz 5
│   │   │   └── user_preference_repository.py ← Faz 5
│   │   │
│   │   ├── storage/
│   │   │   └── file_storage_service.py
│   │   │
│   │   └── logging/
│   │       └── logger.py
│   │
│   ├── ai/                              ← Faz 8
│   │   ├── client.py                   ← Claude API bağlantısı
│   │   ├── analyzers/
│   │   │   └── weekly_analyzer.py      ← Haftalık özet analizi
│   │   └── generators/
│   │       ├── workout_generator.py    ← Lokasyon bazlı antrenman planı
│   │       ├── meal_advisor.py         ← Kan değeri bazlı diyet tavsiyesi
│   │       └── recipe_generator.py     ← Malzeme bazlı tarif önerisi
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
│   ├── architecture.md                 ← bu doküman
│   ├── cheatsheet.md
│   └── images/                         ← UI mockup görselleri
│
├── .github/
│   └── workflows/
│       └── ci.yml                      ← GitHub Actions lint pipeline
│
├── .env
├── .env.example
├── requirements.txt
├── docker-compose.yml
└── README.md
```

---

## 6. Veritabanı Şeması

### Mevcut Tablolar (Faz 1-5) — 11 tablo

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

-- MEAL COMPLIANCE
meal_compliance
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── complied        BOOLEAN     NOT NULL
├── compliance_rate FLOAT       (0-100)
├── notes           TEXT
└── created_at      TIMESTAMPTZ

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

-- SESSION EXERCISES (cascade → exercise_sessions)
session_exercises
├── id              VARCHAR     PK
├── session_id      VARCHAR     FK → exercise_sessions (CASCADE DELETE)
├── exercise_name   VARCHAR     NOT NULL
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
├── liked_foods     JSON
├── disliked_foods  JSON
├── allergies       JSON
├── diseases        JSON
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

---

## 7. API Endpoint Yapısı

```
BASE: /api/v1

── AUTH ──────────────────────────────────────────
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/me

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
POST   /ai/weekly-summary          ← haftalık AI özet raporu ✅
POST   /ai/workout-plan            ← lokasyon bazlı antrenman planı ✅
POST   /ai/meal-advice             ← kan değeri bazlı diyet tavsiyesi ✅
POST   /ai/recipe                  ← malzeme bazlı tarif önerisi ✅
POST   /ai/calorie-from-photo      ← fotoğraftan kalori (Vision) ✅
POST   /ai/body-visualization      ← hedef vücut görseli (DALL-E) ⏳ beklemede
```

---

## 8. AI Layer Detayı

```python
ai/
├── client.py
│   # Claude API bağlantısı — tüm modüller bunu kullanır
│   # Model: claude-sonnet-4-5
│
├── analyzers/
│   └── weekly_analyzer.py
│       # Input:  WeeklyReportResponse (Faz 6 raporu)
│       # Output: Türkçe kişiselleştirilmiş özet metin
│       # API:    Claude API
│
└── generators/
    ├── workout_generator.py
    │   # Input:  lokasyon (home/gym/outdoor), hedef, seviye, gün sayısı
    │   # Output: JSON haftalık antrenman planı (set/rep/kalori)
    │
    ├── meal_advisor.py
    │   # Input:  liked_foods, allergies, diseases, blood_values, fitness_goal
    │   # Output: JSON diyet tavsiyesi (kalori, makro, öneriler, uyarılar)
    │
    └── recipe_generator.py
        # Input:  mevcut malzemeler, tercihler, alerjiler, öğün tipi
        # Output: JSON tarif (malzemeler, adımlar, besin değerleri)

Not: report_service.py haftalık/aylık veri özetini yönetir.
body_trend_analyzer.py ve compliance_analyzer.py bu servis tarafından
karşılandığı için ayrıca implement edilmedi.
```

---

## 9. Güvenlik Mimarisi

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

Env Değişkenleri (.env):
  DATABASE_URL=postgresql+asyncpg://...
  SECRET_KEY=<güçlü random key>
  ALGORITHM=HS256
  ACCESS_TOKEN_EXPIRE_MINUTES=15
  REFRESH_TOKEN_EXPIRE_DAYS=7
  STORAGE_TYPE=local
  CLAUDE_API_KEY=...         (Faz 8 — aktif)
  OPENAI_API_KEY=...         (Faz 8 — Vision için, opsiyonel)
  STABILITY_API_KEY=...      (DALL-E alternatifi, beklemede)
```

---

## 10. Loglama Stratejisi

```python
# structlog ile structured JSON logging
{
  "timestamp": "2026-03-13T10:00:00Z",
  "level": "INFO",
  "event": "measurement_created",
  "user_id": "uuid...",
  "endpoint": "POST /measurements",
  "duration_ms": 42,
  "request_id": "uuid..."
}
```

---

## 11. Git Stratejisi

```
Branch yapısı:
  main          ← her zaman production-ready
  develop       ← aktif geliştirme branch'i
  feature/*     ← tek özellik geliştirme
  fix/*         ← bug fix
  docs/*        ← sadece dokümantasyon

Commit formatı (Conventional Commits):
  feat:     yeni özellik
  fix:      hata düzeltme
  refactor: yeniden yazım
  test:     test ekleme
  docs:     dokümantasyon
  chore:    build, config
```

---

## 12. Geliştirme Fazları (Roadmap)

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
✅ requirements.txt
✅ .env.example
⏳ Docker production config (ileriye bırakıldı)
⏳ pytest unit + integration testler (ileriye bırakıldı)
```

### ✅ Faz 8 — AI Entegrasyonu
```
✅ Claude API entegrasyonu (client.py)
✅ Haftalık AI özet raporu (weekly_analyzer.py)
✅ Lokasyon bazlı antrenman planı (workout_generator.py)
✅ Kan değeri + hastalık bazlı diyet tavsiyesi (meal_advisor.py)
✅ Malzeme bazlı sağlıklı tarif önerisi (recipe_generator.py)
✅ Fotoğraftan kalori hesaplama — Claude Vision (calorie_vision_analyzer.py)
⏳ Hedef vücut görselleştirme — DALL-E 3 (beklemede, OpenAI key gerekli)

Not: body_trend_analyzer.py, compliance_analyzer.py ve report_generator.py
mimaride planlanmıştı ancak bu işlevler report_service.py ve
weekly_analyzer.py tarafından karşılandığı için ayrıca implement edilmedi.
```

### ⏳ Faz 9 — Flutter
```
⏳ Flutter proje kurulumu (Dio + Riverpod + GoRouter)
⏳ flutter_secure_storage + token refresh
⏳ Auth ekranları (login, register)
⏳ Dashboard (haftalık özet)
⏳ Tüm backend özelliklerinin ekranları
⏳ fl_chart ile grafikler
⏳ AI özellik ekranları
```

---

## 13. Flutter Uygulama Mimarisi

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
│   │   ├── home/
│   │   ├── measurements/
│   │   ├── notes/
│   │   ├── diet/
│   │   ├── exercises/
│   │   ├── water/
│   │   ├── sleep/
│   │   ├── preferences/
│   │   ├── reports/
│   │   └── ai/
│   └── widgets/
└── pubspec.yaml
```

---

## 14. Teknoloji Kararları — Gerekçeler

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

---

*Bu doküman projenin yaşayan anayasası — her fazda ilgili bölümler güncellenecek.*  
*Son güncelleme: Mart 2026 — v3.0*