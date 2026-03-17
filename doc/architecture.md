# TrackForge — Mimari Tasarım Dokümanı
**Versiyon:** v2.0 — Güncel & Genişletilmiş  
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
AI Hazır   : Evet (pluggable AI layer)
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
| **CI/CD** | GitHub Actions | — | Otomatik test + lint |
| **Mobil** | Flutter | 3.x | iOS + Android tek codebase |
| **HTTP Client** | Dio | latest | Interceptor, retry, token refresh |
| **State Mgmt** | Riverpod | 2.x | Test edilebilir, compile-safe |
| **Grafik** | fl_chart | latest | Native Flutter charts |
| **AI — Analiz** | Claude API (Anthropic) | — | Haftalık özet, trend analizi, tavsiye |
| **AI — Görsel** | DALL-E 3 / Stable Diffusion | — | Hedef vücut görselleştirme |
| **AI — Vision** | Claude Vision / GPT-4o | — | Fotoğraftan kalori hesaplama |

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
│   │           ├── water_tracking.py       ← Faz 5
│   │           ├── sleep_tracking.py       ← Faz 5
│   │           ├── user_preferences.py     ← Faz 5
│   │           ├── shopping_list.py        ← Faz 5
│   │           ├── reports.py              ← Faz 6
│   │           └── ai.py                  ← Faz 8
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
│   │   │   └── user_preference.py         ← Faz 5
│   │   │
│   │   └── interfaces/
│   │       ├── i_user_repository.py
│   │       ├── i_measurement_repository.py
│   │       ├── i_note_repository.py
│   │       ├── i_meal_compliance_repository.py
│   │       ├── i_file_upload_repository.py
│   │       ├── i_exercise_session_repository.py
│   │       ├── i_session_exercise_repository.py
│   │       ├── i_water_log_repository.py  ← Faz 5
│   │       ├── i_sleep_log_repository.py  ← Faz 5
│   │       └── i_user_preference_repository.py ← Faz 5
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
│   │   │   ├── user_preference_service.py ← Faz 5
│   │   │   ├── shopping_list_service.py   ← Faz 5
│   │   │   └── report_service.py          ← Faz 6
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
│   │       ├── user_preference.py         ← Faz 5
│   │       ├── shopping_list.py           ← Faz 5
│   │       └── report.py                  ← Faz 6
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
│   │   │   ├── water_log_repository.py    ← Faz 5
│   │   │   ├── sleep_log_repository.py    ← Faz 5
│   │   │   └── user_preference_repository.py ← Faz 5
│   │   │
│   │   ├── storage/
│   │   │   └── file_storage_service.py
│   │   │
│   │   └── logging/
│   │       └── logger.py
│   │
│   ├── ai/                               ← Faz 8
│   │   ├── analyzers/
│   │   │   ├── body_trend_analyzer.py
│   │   │   ├── compliance_analyzer.py
│   │   │   ├── calorie_vision_analyzer.py ← Fotoğraftan kalori
│   │   │   └── health_advisor.py          ← Kan değeri/hastalık bazlı tavsiye
│   │   ├── generators/
│   │   │   ├── report_generator.py
│   │   │   ├── workout_plan_generator.py  ← Kişisel PT
│   │   │   ├── meal_plan_generator.py     ← Diyet planı
│   │   │   ├── recipe_generator.py        ← Malzeme bazlı tarif
│   │   │   └── body_visualizer.py         ← Hedef vücut görseli
│   │   └── prompts/
│   │       ├── weekly_summary.py
│   │       ├── workout_plan.py
│   │       ├── meal_plan.py
│   │       └── recipe.py
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
│   ├── architecture.md                   ← bu doküman
│   └── cheatsheet.md
│
├── .env
├── .env.example
├── requirements.txt
├── docker-compose.yml
└── README.md
```

---

## 6. Veritabanı Şeması

### Mevcut Tablolar (Faz 1-4)

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
```

### Faz 5 — Yeni Tablolar

```sql
-- WATER LOGS (Günlük su takibi)
water_logs
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── amount_ml       INT         NOT NULL    ← içilen miktar ml
├── target_ml       INT                     ← günlük hedef
└── created_at      TIMESTAMPTZ

-- SLEEP LOGS (Uyku takibi)
sleep_logs
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users
├── date            DATE        NOT NULL
├── sleep_time      TIME                    ← yatış saati
├── wake_time       TIME                    ← kalkış saati
├── duration_hours  FLOAT                   ← toplam süre
├── quality_score   INT         (1-10)      ← uyku kalitesi
├── notes           TEXT
└── created_at      TIMESTAMPTZ

-- USER PREFERENCES (Kişisel tercihler)
user_preferences
├── id              VARCHAR     PK
├── user_id         VARCHAR     FK → users  UNIQUE
├── liked_foods     TEXT                    ← JSON array
├── disliked_foods  TEXT                    ← JSON array
├── allergies       TEXT                    ← JSON array
├── diseases        TEXT                    ← JSON array (hastalıklar)
├── blood_values    TEXT                    ← JSON (kan değerleri)
├── workout_location VARCHAR               ← home/gym/park
├── fitness_goal    VARCHAR                ← lose_weight/build_muscle/maintain
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

── WATER TRACKING (Faz 5) ────────────────────────
POST   /water
GET    /water?from=&to=
GET    /water/date/{date}
PUT    /water/{id}
DELETE /water/{id}

── SLEEP TRACKING (Faz 5) ────────────────────────
POST   /sleep
GET    /sleep?from=&to=
GET    /sleep/date/{date}
PUT    /sleep/{id}
DELETE /sleep/{id}

── USER PREFERENCES (Faz 5) ──────────────────────
POST   /preferences
GET    /preferences
PUT    /preferences

── SHOPPING LIST (Faz 5) ─────────────────────────
GET    /shopping-list?from=&to=          ← haftalık diyet planına göre otomatik

── REPORTS (Faz 6) ───────────────────────────────
GET    /reports/weekly?date=
GET    /reports/monthly?month=

── AI (Faz 8) ────────────────────────────────────
POST   /ai/calorie-from-photo            ← fotoğraftan kalori hesapla
POST   /ai/workout-plan                  ← kişisel PT planı
POST   /ai/meal-plan                     ← diyet planı önerisi
POST   /ai/recipe                        ← malzeme bazlı tarif
POST   /ai/body-visualization            ← hedef vücut görseli
POST   /ai/weekly-summary                ← haftalık AI özet raporu
GET    /ai/health-advice                 ← kan değeri/hastalık bazlı tavsiye
```

---

## 8. AI Layer Detayı

```python
ai/
├── analyzers/
│   ├── body_trend_analyzer.py
│   │   # Input:  son N haftanın ölçümleri
│   │   # Output: trend raporu, yorum
│   │
│   ├── compliance_analyzer.py
│   │   # Input:  meal_compliance kayıtları
│   │   # Output: uyum skoru, zayıf günler, öneri
│   │
│   ├── calorie_vision_analyzer.py
│   │   # Input:  yemek/içecek fotoğrafı
│   │   # Output: tahmini kalori, makro değerler
│   │   # API:    Claude Vision veya GPT-4o
│   │
│   └── health_advisor.py
│       # Input:  kan değerleri, hastalıklar, ölçümler
│       # Output: kişiselleştirilmiş sağlık tavsiyesi
│
├── generators/
│   ├── report_generator.py
│   │   # Input:  haftalık tüm veri
│   │   # Output: okunabilir haftalık özet metni
│   │   # API:    Claude API
│   │
│   ├── workout_plan_generator.py
│   │   # Input:  lokasyon (home/gym/park), hedef, seviye
│   │   # Output: set/rep/egzersiz listesi
│   │
│   ├── meal_plan_generator.py
│   │   # Input:  tercihler, hastalıklar, kan değerleri, kalori hedefi
│   │   # Output: haftalık diyet planı
│   │
│   ├── recipe_generator.py
│   │   # Input:  evdeki malzemeler, sevilen/sevilmeyen yiyecekler
│   │   # Output: sağlıklı tarif + kalori bilgisi
│   │
│   └── body_visualizer.py
│       # Input:  mevcut fotoğraf, hedef yağ oranı, kilo, kas kütlesi
│       # Output: hedef vücudu gösteren yapay görsel
│       # API:    DALL-E 3 veya Stable Diffusion
│
└── prompts/
    ├── weekly_summary.py
    ├── workout_plan.py
    ├── meal_plan.py
    └── recipe.py
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
  CLAUDE_API_KEY=...       (Faz 8)
  OPENAI_API_KEY=...       (Faz 8 — Vision için)
  STABILITY_API_KEY=...    (Faz 8 — Görselleştirme için)
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

### ⏳ Faz 5 — Yeni Backend Özellikleri
```
□ Su takibi CRUD (water_logs)
□ Uyku takibi CRUD (sleep_logs)
□ Kullanıcı tercihleri (yemek tercihleri, hastalıklar, kan değerleri, hedef)
□ Alışveriş listesi (haftalık diyet planına göre otomatik)
```

### ⏳ Faz 6 — Raporlar
```
□ /reports/weekly endpoint
□ /reports/monthly endpoint
□ Kalori günlük toplam hesaplama
□ Kalori açığı/fazlası analizi
```

### ⏳ Faz 7 — Polish & Deployment
```
□ GitHub Actions (lint + test pipeline)
□ Docker production config
□ Swagger dokümantasyon gözden geçirme
□ README.md tamamlama
□ pytest unit + integration testler
```

### ⏳ Faz 8 — AI Entegrasyonu
```
□ Claude API entegrasyonu
□ Fotoğraftan kalori hesaplama (Vision API)
□ Kişisel PT — lokasyon bazlı antrenman planı (home/gym/park)
□ Kan değeri + hastalık bazlı diyet tavsiyesi
□ Hedef vücut görselleştirme (DALL-E 3 / Stable Diffusion)
□ Malzeme bazlı sağlıklı tarif önerisi
□ Haftalık AI özet raporu
□ body_trend_analyzer.py
□ compliance_analyzer.py
□ report_generator.py
```

### ⏳ Faz 9 — Flutter
```
□ Flutter proje kurulumu (Dio + Riverpod + GoRouter)
□ flutter_secure_storage + token refresh
□ Auth ekranları (login, register)
□ Dashboard (haftalık özet)
□ Tüm backend özelliklerinin ekranları
□ fl_chart ile grafikler
□ AI özellik ekranları
```

---

## 13. Flutter Uygulama Mimarisi

```
trackforge-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                              # GoRouter + tema setup
│   │
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart               # Dio instance, interceptors
│   │   │   ├── endpoints.dart                # URL sabitleri
│   │   │   └── api_exceptions.dart           # Hata yönetimi
│   │   ├── auth/
│   │   │   ├── token_manager.dart            # flutter_secure_storage
│   │   │   └── auth_interceptor.dart         # Token refresh logic
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   └── utils/
│   │       ├── date_utils.dart               # Tarih → hafta hesaplama
│   │       └── file_picker_helper.dart
│   │
│   ├── data/
│   │   ├── models/                           # JSON ↔ Dart modeller
│   │   │   ├── user_model.dart
│   │   │   ├── measurement_model.dart
│   │   │   ├── note_model.dart
│   │   │   ├── meal_compliance_model.dart
│   │   │   ├── file_upload_model.dart
│   │   │   ├── exercise_model.dart
│   │   │   ├── water_log_model.dart
│   │   │   ├── sleep_log_model.dart
│   │   │   └── user_preference_model.dart
│   │   │
│   │   └── repositories/                    # API çağrıları burada
│   │       ├── auth_repository.dart
│   │       ├── measurement_repository.dart
│   │       ├── note_repository.dart
│   │       ├── meal_compliance_repository.dart
│   │       ├── file_repository.dart
│   │       ├── exercise_repository.dart
│   │       ├── water_repository.dart
│   │       ├── sleep_repository.dart
│   │       ├── preference_repository.dart
│   │       └── ai_repository.dart
│   │
│   ├── providers/                           # Riverpod state yönetimi
│   │   ├── auth_provider.dart
│   │   ├── measurement_provider.dart
│   │   ├── note_provider.dart
│   │   ├── meal_compliance_provider.dart
│   │   ├── file_provider.dart
│   │   ├── exercise_provider.dart
│   │   ├── water_provider.dart
│   │   ├── sleep_provider.dart
│   │   ├── preference_provider.dart
│   │   └── ai_provider.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── home/
│   │   │   └── dashboard_screen.dart        # Haftalık özet — ana ekran
│   │   │
│   │   ├── measurements/
│   │   │   ├── measurement_screen.dart      # Ölçüm girişi
│   │   │   └── measurement_chart_screen.dart # fl_chart grafik
│   │   │
│   │   ├── notes/
│   │   │   └── notes_screen.dart
│   │   │
│   │   ├── diet/
│   │   │   ├── meal_compliance_screen.dart
│   │   │   └── diet_plan_upload_screen.dart
│   │   │
│   │   ├── files/
│   │   │   └── photo_gallery_screen.dart
│   │   │
│   │   ├── exercises/
│   │   │   ├── exercise_session_screen.dart
│   │   │   └── exercise_history_screen.dart
│   │   │
│   │   ├── water/
│   │   │   └── water_tracking_screen.dart
│   │   │
│   │   ├── sleep/
│   │   │   └── sleep_tracking_screen.dart
│   │   │
│   │   ├── preferences/
│   │   │   └── user_preference_screen.dart  # Tercihler, kan değerleri, hedefler
│   │   │
│   │   ├── reports/
│   │   │   ├── weekly_report_screen.dart
│   │   │   └── monthly_report_screen.dart
│   │   │
│   │   └── ai/
│   │       ├── calorie_scan_screen.dart     # Fotoğraftan kalori
│   │       ├── workout_plan_screen.dart     # Kişisel PT
│   │       ├── meal_plan_screen.dart        # AI diyet planı
│   │       ├── recipe_screen.dart           # Malzeme bazlı tarif
│   │       ├── body_visualization_screen.dart # Hedef vücut görseli
│   │       └── ai_summary_screen.dart       # Haftalık AI özet
│   │
│   └── widgets/
│       ├── week_navigator.dart              # Hafta ileri/geri
│       ├── file_upload_card.dart
│       ├── measurement_chart.dart           # fl_chart wrapper
│       ├── water_progress_bar.dart          # Günlük su hedefi
│       ├── sleep_quality_card.dart
│       ├── mood_energy_slider.dart
│       ├── ai_advice_card.dart              # AI tavsiye kartı
│       └── body_goal_card.dart              # Hedef vücut görseli kartı
│
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
| DALL-E 3 / SD | Midjourney | API erişimi var, programatik kullanım |

---

*Bu doküman projenin yaşayan anayasası — her fazda ilgili bölümler güncellenecek.*  
*Son güncelleme: Mart 2026 — v2.0*