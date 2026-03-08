# FitTrack — Final Mimari Tasarım Dokümanı
**Versiyon:** v1.0 — Birleşik & Rafine  
**Tarih:** Mart 2026  
**Mimari:** Clean Architecture + Repository Pattern  
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First

---

## 1. Proje Kimliği

```
Ad         : FitTrack — AI-Powered Body Tracking System
Amaç       : Diyet, ölçüm, fotoğraf, egzersiz ve notları
             haftalık bazda takip eden, AI destekli analiz
             yapabilen kişisel sağlık platformu
Mimari     : Clean Architecture
Zaman Ref. : DATE_BASED (hafta hesaplanan, saklanmayan)
AI Hazır   : Evet (pluggable AI layer)
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
| **AI (İleride)** | Claude API (Anthropic) | — | Analiz, özet, trend |

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
fittrack-backend/
│
├── app/
│   ├── main.py                          # FastAPI app, middleware, router kayıt
│   │
│   ├── api/
│   │   └── v1/
│   │       ├── router.py                # Tüm endpoint'lerin merkezi kayıt yeri
│   │       └── endpoints/
│   │           ├── auth.py
│   │           ├── measurements.py
│   │           ├── diet_plans.py
│   │           ├── progress_photos.py
│   │           ├── notes.py
│   │           ├── exercises.py
│   │           └── reports.py
│   │
│   ├── domain/
│   │   ├── entities/                    # Saf Python dataclass'ları, ORM'e bağımlı değil
│   │   │   ├── user.py
│   │   │   ├── body_measurement.py
│   │   │   ├── progress_photo.py
│   │   │   ├── diet_plan.py
│   │   │   ├── meal_compliance.py
│   │   │   ├── weekly_note.py
│   │   │   └── exercise_session.py
│   │   │
│   │   └── interfaces/                  # Abstract repository tanımları
│   │       ├── i_measurement_repository.py
│   │       ├── i_photo_repository.py
│   │       ├── i_diet_repository.py
│   │       ├── i_note_repository.py
│   │       └── i_exercise_repository.py
│   │
│   ├── application/
│   │   ├── services/                    # Use case'ler burada yaşar
│   │   │   ├── auth_service.py
│   │   │   ├── measurement_service.py
│   │   │   ├── diet_service.py
│   │   │   ├── photo_service.py
│   │   │   ├── note_service.py
│   │   │   ├── exercise_service.py
│   │   │   └── report_service.py
│   │   │
│   │   └── schemas/                     # Pydantic request/response modelleri
│   │       ├── auth.py
│   │       ├── measurement.py
│   │       ├── diet_plan.py
│   │       ├── photo.py
│   │       ├── note.py
│   │       ├── exercise.py
│   │       └── report.py
│   │
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py                  # SQLAlchemy Base
│   │   │   ├── session.py               # Async engine + session factory
│   │   │   └── models/                  # SQLAlchemy ORM modelleri
│   │   │       ├── user_model.py
│   │   │       ├── measurement_model.py
│   │   │       ├── photo_model.py
│   │   │       ├── diet_model.py
│   │   │       ├── compliance_model.py
│   │   │       ├── note_model.py
│   │   │       └── exercise_model.py
│   │   │
│   │   ├── repositories/                # Interface implementasyonları
│   │   │   ├── measurement_repository.py
│   │   │   ├── photo_repository.py
│   │   │   ├── diet_repository.py
│   │   │   ├── note_repository.py
│   │   │   └── exercise_repository.py
│   │   │
│   │   ├── storage/
│   │   │   ├── i_file_storage.py        # Abstract storage interface
│   │   │   ├── local_file_storage.py    # Filesystem implementasyonu
│   │   │   └── s3_file_storage.py       # AWS S3 implementasyonu (ileride)
│   │   │
│   │   └── logging/
│   │       └── logger.py                # structlog konfigürasyonu
│   │
│   ├── ai/                              # Pluggable AI modülü
│   │   ├── analyzers/
│   │   │   ├── body_trend_analyzer.py   # Kilo/ölçüm trend analizi
│   │   │   ├── compliance_analyzer.py   # Diyet uyum skoru
│   │   │   └── photo_similarity.py      # Fotoğraf karşılaştırma
│   │   ├── generators/
│   │   │   └── report_generator.py      # Claude API ile otomatik özet
│   │   └── prompts/
│   │       └── weekly_summary.py        # Prompt template'leri
│   │
│   ├── core/
│   │   ├── config.py                    # Pydantic Settings, env yönetimi
│   │   ├── security.py                  # JWT encode/decode, hash
│   │   ├── dependencies.py              # FastAPI Depends() tanımları
│   │   └── exceptions.py               # Custom exception sınıfları
│   │
│   └── middleware/
│       ├── auth_middleware.py
│       ├── logging_middleware.py
│       └── error_handler.py
│
├── migrations/                          # Alembic migration dosyaları
│   ├── versions/
│   └── env.py
│
├── tests/
│   ├── unit/
│   │   ├── test_measurement_service.py
│   │   └── test_diet_service.py
│   ├── integration/
│   │   ├── test_measurement_endpoints.py
│   │   └── test_photo_endpoints.py
│   └── conftest.py                      # Test fixtures
│
├── storage/                             # Yerel dosya depolama
│   ├── diet_plans/
│   ├── progress_photos/
│   ├── reports/
│   └── compliance_files/
│
├── logs/
│   └── app.log
│
├── .env                                 # Ortam değişkenleri (git'e girme!)
├── .env.example                         # Örnek env şablonu
├── requirements.txt
├── requirements-dev.txt                 # Test + lint araçları
├── Dockerfile
├── docker-compose.yml                   # Local dev: app + db + pgadmin
├── docker-compose.prod.yml              # Production override
└── README.md
```

---

## 6. Veritabanı Şeması

### Tasarım Prensipleri
- `DATE_BASED` zaman referansı — hafta hesaplanan kavram, saklanmayan
- UUID primary key — distributed sistemlere hazır
- `file_path` saklanır, blob değil
- Soft delete yok, basit tutuyoruz başlangıçta

```sql
-- ─────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────
users
├── id              UUID        PK, default gen_random_uuid()
├── email           VARCHAR     UNIQUE, NOT NULL
├── password_hash   VARCHAR     NOT NULL
├── full_name       VARCHAR     NOT NULL
├── created_at      TIMESTAMPTZ DEFAULT now()
└── updated_at      TIMESTAMPTZ DEFAULT now()

-- ─────────────────────────────────────────
-- BODY MEASUREMENTS
-- ─────────────────────────────────────────
body_measurements
├── id                  UUID        PK
├── user_id             UUID        FK → users
├── date                DATE        NOT NULL        ← zaman referansı
├── weight_kg           FLOAT
├── body_fat_pct        FLOAT       nullable
├── muscle_mass_kg      FLOAT       nullable
├── waist_cm            FLOAT
├── chest_cm            FLOAT
├── hip_cm              FLOAT
├── arm_cm              FLOAT
├── leg_cm              FLOAT
└── created_at          TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, date)

-- ─────────────────────────────────────────
-- PROGRESS PHOTOS
-- ─────────────────────────────────────────
progress_photos
├── id              UUID        PK
├── user_id         UUID        FK → users
├── date            DATE        NOT NULL
├── file_path       VARCHAR     NOT NULL
├── angle           VARCHAR     CHECK (front/side/back)
├── description     TEXT        nullable
└── created_at      TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, date)

-- ─────────────────────────────────────────
-- DIET PLANS
-- ─────────────────────────────────────────
diet_plans
├── id              UUID        PK
├── user_id         UUID        FK → users
├── start_date      DATE        NOT NULL
├── end_date        DATE        NOT NULL
├── file_path       VARCHAR     NOT NULL    ← PDF
├── notes           TEXT        nullable
└── created_at      TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, start_date)

-- ─────────────────────────────────────────
-- MEAL COMPLIANCE (Diyet Uyum Kaydı)
-- ─────────────────────────────────────────
meal_compliance
├── id                  UUID        PK
├── user_id             UUID        FK → users
├── date                DATE        NOT NULL
├── compliance_score    INT         CHECK (1-10)
├── compliance_file     VARCHAR     nullable  ← opsiyonel dosya
├── notes               TEXT        nullable
└── created_at          TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, date)

-- ─────────────────────────────────────────
-- WEEKLY NOTES
-- ─────────────────────────────────────────
weekly_notes
├── id              UUID        PK
├── user_id         UUID        FK → users
├── date            DATE        NOT NULL
├── title           VARCHAR     nullable
├── content         TEXT        NOT NULL
├── energy_level    INT         CHECK (1-10)
├── mood_score      INT         CHECK (1-10)
└── created_at      TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, date)

-- ─────────────────────────────────────────
-- EXERCISE SESSIONS
-- ─────────────────────────────────────────
exercise_sessions
├── id                  UUID        PK
├── user_id             UUID        FK → users
├── date                DATE        NOT NULL
├── exercise_type       VARCHAR     CHECK (walking/gym/cycling/other)
├── name                VARCHAR     nullable  ← "Bench Press" vb.
├── duration_minutes    INT         nullable
├── distance_km         FLOAT       nullable
├── sets                INT         nullable
├── reps                INT         nullable
├── weight_kg           FLOAT       nullable
├── notes               TEXT        nullable
└── created_at          TIMESTAMPTZ DEFAULT now()

INDEX: (user_id, date)
```

---

## 7. API Endpoint Yapısı

```
BASE: /api/v1

── AUTH ──────────────────────────────────────────────
POST   /auth/register                 Kayıt
POST   /auth/login                    Giriş → JWT token
POST   /auth/refresh                  Token yenile

── MEASUREMENTS ──────────────────────────────────────
POST   /measurements                  Ölçüm gir
GET    /measurements?from=&to=        Tarih aralığı ölçümleri
GET    /measurements/{date}           Belirli gün ölçümü
GET    /measurements/history          Tüm geçmiş (grafik için)
PUT    /measurements/{id}             Güncelle
DELETE /measurements/{id}             Sil

── DIET PLANS ────────────────────────────────────────
POST   /diet-plans/upload             PDF yükle
GET    /diet-plans?from=&to=          Tarih aralığı planları
GET    /diet-plans/{id}               Belirli plan
DELETE /diet-plans/{id}               Sil

── MEAL COMPLIANCE ───────────────────────────────────
POST   /compliance                    Günlük uyum kaydı
POST   /compliance/upload             Uyum dosyası yükle
GET    /compliance?from=&to=          Tarih aralığı
GET    /compliance/{date}             Belirli gün

── PROGRESS PHOTOS ───────────────────────────────────
POST   /photos/upload                 Fotoğraf yükle
GET    /photos?from=&to=              Tarih aralığı fotoğraflar
GET    /photos/compare?d1=&d2=        İki tarih karşılaştır  ← önemli
DELETE /photos/{id}                   Sil

── NOTES ─────────────────────────────────────────────
POST   /notes                         Not ekle
GET    /notes?from=&to=               Tarih aralığı notlar
GET    /notes/{date}                  Belirli gün notu
PUT    /notes/{id}                    Güncelle
DELETE /notes/{id}                    Sil

── EXERCISES ─────────────────────────────────────────
POST   /exercises                     Egzersiz ekle
GET    /exercises?from=&to=           Tarih aralığı
GET    /exercises/history             Tüm geçmiş
PUT    /exercises/{id}                Güncelle
DELETE /exercises/{id}                Sil

── REPORTS ───────────────────────────────────────────
GET    /reports/weekly?date=          O haftanın özet raporu
GET    /reports/monthly?month=        Aylık özet
POST   /reports/ai-summary            AI destekli özet üret (ileride)
```

---

## 8. Flutter Uygulama Mimarisi

```
fittrack-flutter/
├── lib/
│   ├── main.dart
│   ├── app.dart                         # GoRouter + tema setup
│   │
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart          # Dio instance, interceptors
│   │   │   ├── endpoints.dart           # URL sabitleri
│   │   │   └── api_exceptions.dart      # Hata yönetimi
│   │   ├── auth/
│   │   │   ├── token_manager.dart       # flutter_secure_storage
│   │   │   └── auth_interceptor.dart    # Token refresh logic
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   └── utils/
│   │       ├── date_utils.dart          # Tarih → hafta hesaplama
│   │       └── file_picker_helper.dart
│   │
│   ├── data/
│   │   ├── models/                      # JSON ↔ Dart modeller
│   │   │   ├── measurement_model.dart
│   │   │   ├── diet_plan_model.dart
│   │   │   ├── photo_model.dart
│   │   │   ├── note_model.dart
│   │   │   └── exercise_model.dart
│   │   │
│   │   └── repositories/               # API çağrıları burada
│   │       ├── measurement_repository.dart
│   │       ├── diet_repository.dart
│   │       ├── photo_repository.dart
│   │       ├── note_repository.dart
│   │       └── exercise_repository.dart
│   │
│   ├── providers/                       # Riverpod state
│   │   ├── auth_provider.dart
│   │   ├── measurement_provider.dart
│   │   ├── photo_provider.dart
│   │   ├── note_provider.dart
│   │   └── exercise_provider.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── home/
│   │   │   └── dashboard_screen.dart    # Haftalık özet
│   │   ├── diet/
│   │   │   ├── diet_upload_screen.dart  # Sayfa 1: Diyetisyen planı
│   │   │   └── compliance_screen.dart   # Sayfa 2: Uyum kaydı
│   │   ├── photos/
│   │   │   └── photo_compare_screen.dart # Sayfa 3: Fotoğraf kıyas
│   │   ├── measurements/
│   │   │   └── measurement_screen.dart  # Sayfa 4: Ölçümler + grafik
│   │   ├── notes/
│   │   │   └── notes_screen.dart        # Sayfa 5: Haftalık notlar
│   │   └── exercise/
│   │       └── exercise_screen.dart     # Sayfa 6: Egzersiz log
│   │
│   └── widgets/
│       ├── week_navigator.dart          # Hafta ileri/geri
│       ├── file_upload_card.dart
│       ├── measurement_chart.dart       # fl_chart wrapper
│       ├── photo_compare_widget.dart
│       └── mood_energy_slider.dart
│
└── pubspec.yaml
```

---

## 9. AI Layer Detayı

```python
# Pluggable yapı — şimdi stub, ileride gerçek implementasyon

ai/
├── analyzers/
│   ├── body_trend_analyzer.py
│   │   # Input: son N haftanın ölçümleri
│   │   # Output: trend raporu, yorum
│   │
│   ├── compliance_analyzer.py
│   │   # Input: meal_compliance kayıtları
│   │   # Output: ortalama uyum skoru, zayıf günler
│   │
│   └── photo_similarity.py
│       # Input: iki fotoğraf path
│       # Output: değişim özeti (görsel diff)
│
├── generators/
│   └── report_generator.py
│       # Claude API çağrısı
│       # Input: haftalık tüm veri (ölçüm + uyum + not + egzersiz)
│       # Output: okunabilir haftalık özet metni
│
└── prompts/
    └── weekly_summary.py
        # Prompt template'leri burada saklanır
        # Versiyon kontrolü altında — prompt geliştirme kolay olur
```

---

## 10. Güvenlik Mimarisi

```
JWT Flow:
  1. POST /auth/login → access_token (15dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 gelince: POST /auth/refresh → yeni access_token
  4. Flutter: flutter_secure_storage ile token saklama
  5. Python: python-jose ile imzalama, passlib ile şifre hash

Env Değişkenleri (.env):
  DATABASE_URL=postgresql+asyncpg://...
  SECRET_KEY=<güçlü random key>
  ALGORITHM=HS256
  ACCESS_TOKEN_EXPIRE_MINUTES=15
  REFRESH_TOKEN_EXPIRE_DAYS=7
  STORAGE_TYPE=local  # veya s3
  AWS_BUCKET_NAME=...  (ileride)
  CLAUDE_API_KEY=...   (ileride)
```

---

## 11. Loglama Stratejisi

```python
# structlog ile structured JSON logging

# Her log satırı şunu içerir:
{
  "timestamp": "2026-03-07T10:23:45Z",
  "level": "INFO",
  "event": "measurement_created",
  "user_id": "uuid...",
  "endpoint": "POST /measurements",
  "duration_ms": 42,
  "request_id": "uuid..."
}

# Log seviyeleri:
# INFO    → normal operasyon (create, read, update)
# WARNING → beklenmeyen ama kırıcı olmayan durum
# ERROR   → exception, başarısız işlem
```

---

## 12. Git Stratejisi

```
Branch yapısı:
  main          ← her zaman production-ready
  develop       ← aktif geliştirme branch'i
  feature/*     ← tek özellik geliştirme
  fix/*         ← bug fix
  docs/*        ← sadece dokümantasyon

Örnek branch isimleri:
  feature/auth-jwt
  feature/measurement-crud
  feature/photo-upload
  feature/flutter-dashboard
  fix/token-refresh-bug

Commit formatı (Conventional Commits):
  feat:     yeni özellik
  fix:      hata düzeltme
  refactor: yeniden yazım, davranış değişmeden
  test:     test ekleme
  docs:     dokümantasyon
  chore:    build, config

Örnekler:
  feat: add body measurement CRUD endpoints
  feat: implement JWT refresh token flow
  fix: correct weight_kg validation in measurement schema
  docs: update API endpoint reference in README
```

---

## 13. Geliştirme Fazları (Roadmap)

### 🟢 Faz 1 — Temel Altyapı
```
□ Docker Compose kurulumu (app + postgres + pgadmin)
□ FastAPI proje iskeleti (Clean Architecture klasör yapısı)
□ Alembic kurulumu + ilk migration
□ PostgreSQL bağlantısı (async SQLAlchemy)
□ JWT auth sistemi (register + login + refresh)
□ structlog entegrasyonu
□ GitHub repo + develop branch + README.md iskelet
□ Flutter proje kurulumu + Dio + Riverpod + GoRouter
```

### 🟡 Faz 2 — Core Entities
```
□ Body measurements CRUD (backend + flutter)
□ Weekly notes CRUD (backend + flutter)
□ Meal compliance kayıt sistemi
□ Tarih bazlı sorgulama (from/to parametreleri)
□ Hafta hesaplama utility (flutter tarafında)
```

### 🟠 Faz 3 — Dosya İşlemleri
```
□ Fotoğraf yükleme + sunma
□ Fotoğraf karşılaştırma endpoint + ekranı
□ Diyet planı PDF yükleme
□ Compliance dosyası yükleme
□ File storage soyutlaması (local → S3 hazır)
```

### 🔵 Faz 4 — Egzersiz & Raporlar
```
□ Egzersiz session log sistemi
□ fl_chart ile ölçüm grafikleri (flutter)
□ /reports/weekly endpoint
□ Dashboard ekranı (haftalık özet)
```

### 🟣 Faz 5 — Polish & Deployment
```
□ GitHub Actions (lint + test pipeline)
□ Docker production config
□ API dokümantasyon gözden geçirme (Swagger)
□ README.md tamamlama
□ flutter_secure_storage + token refresh test
```

### ⚫ Faz 6 — AI Entegrasyonu
```
□ Claude API entegrasyonu
□ report_generator.py implementasyonu
□ body_trend_analyzer.py
□ compliance_analyzer.py
□ POST /reports/ai-summary endpoint
□ Flutter: AI özet ekranı
```

---

## 14. Teknoloji Kararları — Gerekçeler

| Karar | Alternatif | Neden bu? |
|---|---|---|
| FastAPI > Flask | Flask | Async native, Pydantic v2, otomatik OpenAPI, tip güvenli |
| PostgreSQL > SQLite | SQLite | Production-ready, indexing, JSON desteği, managed servis seçeneği |
| SQLAlchemy 2.0 (async) | Tortoise ORM | FastAPI ile native uyum, async tam destek |
| Alembic | Manuel migration | Schema versiyon kontrolü şart |
| structlog > print/logging | stdlib logging | JSON output, bağlam ekleme kolay, test edilebilir |
| Riverpod > Provider/Bloc | Bloc | Compile-safe, daha az boilerplate, test kolay |
| GoRouter > Navigator 2 | Navigator 2 | Declarative routing, deep link hazır |
| flutter_secure_storage | SharedPreferences | JWT token güvenli saklama için şart |
| DATE_BASED > week_id FK | weeks tablosu | Esneklik, hafta tanımı değişebilir, sorgu daha kolay |
| Repository pattern | Direkt ORM çağrısı | Test edilebilirlik, soyutlama, AI servis gelecekte farklı kaynak kullanabilir |

---

*Bu doküman projenin yaşayan anayasası — her fazda ilgili bölümler güncellenecek.*
*Son güncelleme: Mart 2026 — v1.0*