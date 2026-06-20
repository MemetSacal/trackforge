# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v8.1 — Tam Güncel
**Tarih:** 20 Haziran 2026
**Mimari:** Clean Architecture + Repository Pattern
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First
**Durum:** Prod canlı · 26 tablo · 122 route · 37 mobil ekran · tek migration head (0003_add_email_verification)

---

## 1. Proje Kimliği

| Alan | Detay |
|---|---|
| **Ad** | TrackForge — AI-Powered Personal Health & Fitness System |
| **Amaç** | Diyet, ölçüm, egzersiz, uyku, su takibi; AI destekli kişiselleştirilmiş sağlık, beslenme ve antrenman tavsiyesi sunan platform |
| **Mimari** | Clean Architecture + Repository Pattern |
| **AI** | Claude API — `claude-sonnet-4-5` (ana üretim) + `claude-haiku-4-5-20251001` (sohbet) |
| **GitHub** | github.com/MemetSacal/trackforge |
| **Geliştirici** | Memet Saçal — Bilgisayar Mühendisliği, OMÜ |

---

## 2. Teknoloji Stack'i

| Katman | Teknoloji | Versiyon | Neden |
|---|---|---|---|
| Backend | FastAPI | 0.115+ | Async, otomatik OpenAPI |
| Veritabanı | PostgreSQL | 16+ | ACID, JSON desteği |
| ORM | SQLAlchemy | 2.0+ | Async destekli, type-safe |
| Migration | Alembic | latest | Schema versiyon yönetimi |
| Auth | JWT (python-jose) | latest | Stateless, mobil uyumlu |
| Validation | Pydantic v2 | 2.0+ | FastAPI native entegrasyon |
| Loglama | structlog | latest | Structured JSON logging |
| **Email** | **Resend API** | **v8.1 — yeni** | **Transactional email, httpx ile basit REST entegrasyonu** |
| Test | pytest + pytest-asyncio | latest | **v8.1 — yeni**, SQLite in-memory, 57 test |
| CI/CD | GitHub Actions | — | Otomatik lint pipeline |
| Hosting | Render Starter | $7/ay | Cold start yok, 7/24 uyanık |
| Python | 3.14 | — | Render ortamı |
| Mobil | Flutter | 3.41.6 | iOS + Android tek codebase |
| HTTP Client | Dio | latest | Interceptor, retry, token refresh |
| State Mgmt | Riverpod | 2.x | Test edilebilir, compile-safe |
| Navigation | GoRouter | 14.x | Declarative routing |
| Grafik | fl_chart | 0.69.x | Native Flutter charts |
| Markdown | flutter_markdown_plus | 1.0.7 | AI yanıt render |
| Barcode | mobile_scanner | 5.2.3 | Barkod okuma |
| Notifications | flutter_local_notifications | 18.0.1 | Push bildirim |
| Pedometer | pedometer | 4.0.2 | Telefon sensörü adım takibi |
| Storage | shared_preferences | 2.3.3 | Local cache (user_id bazlı) |
| Secure | flutter_secure_storage | 9.2.2 | JWT token |
| Icons | flutter_launcher_icons | 0.14.4 | Tüm boyut üretimi |
| Splash | flutter_native_splash | 2.4.x | Native splash screen |
| Barkod API | Open Food Facts | — | Ücretsiz besin veritabanı |

---

## 3. Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                         │
│   Flutter App (iOS + Android)                           │
│   Screens → Providers (Riverpod) → ApiClient           │
│              ↓                                          │
│         Dio HTTP Client + AuthInterceptor               │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS / REST / JSON
                      │ Authorization: Bearer <JWT>
┌─────────────────────▼───────────────────────────────────┐
│                    API GATEWAY                          │
│              FastAPI (Uvicorn/Gunicorn)                 │
│  Router /api/v1 | JWT Auth | CORS Middleware            │
│                                                         │
│  CLEAN ARCHITECTURE CORE                                │
│  Presentation → Application → Domain → Infrastructure  │
│                    ↓                                    │
│               AI Layer (pluggable)                      │
└──────────┬──────────────────────────┬───────────┬───────┘
           │                          │           │
  ┌────────▼──────┐          ┌────────▼──────┐ ┌──▼─────────────┐
  │  PostgreSQL   │          │  Static Files  │ │  Resend API     │
  │  (Render)     │          │ landing+privacy│ │  (email — v8.1) │
  └───────────────┘          └────────────────┘ └─────────────────┘
```

**v8.1 notu:** Backend artık Resend'e (3. parti email servisi) async olarak bağımlı. `register` endpoint'i email gönderimini try/except ile izole eder — Resend down olsa bile kayıt başarısız olmaz, sadece doğrulama maili gitmez.

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

Akış: **Entity → Interface → Model → Repository → Service → Schema → Endpoint**

---

## 5. Backend Klasör Yapısı

```
backend/
├── .env
├── pytest.ini                     # v8.1 — yeni: test marker tanımları (p0/p1/p2/regression/security)
├── app/
│   ├── main.py                    # FastAPI app, CORS, routing, static
│   ├── api/v1/
│   │   ├── router.py
│   │   └── endpoints/
│   │       ├── auth.py            # v8.1: +verify-email, +resend-verification
│   │       ├── measurements.py
│   │       ├── notes.py
│   │       ├── meal_compliance.py
│   │       ├── files.py
│   │       ├── exercises.py       # v8.1: +PATCH /sessions/{id}/complete
│   │       ├── water.py
│   │       ├── sleep.py
│   │       ├── preferences.py
│   │       ├── shopping.py
│   │       ├── reports.py
│   │       ├── ai.py
│   │       ├── onboarding.py
│   │       ├── barcode.py
│   │       ├── gamification.py
│   │       ├── social.py
│   │       ├── steps.py
│   │       ├── cycle.py
│   │       ├── ai_jobs.py         # GET /ai/jobs/{id} — job durumu sorgulama
│   │       └── ai_feedback.py     # POST /ai/feedback — 👍/👎
│   ├── domain/
│   │   ├── entities/              # 17 entity
│   │   │   ├── user.py            # is_premium: bool = False
│   │   │   │                      # v8.1: +email_verified, +email_token, +email_token_expires
│   │   │   ├── user_preference.py # diet_preference, ai_name, target_weight_kg, daily_calorie_habit
│   │   │   ├── exercise_session.py # v8.1: +is_completed (seans seviyesi tamamlanma)
│   │   │   └── ...
│   │   └── interfaces/            # 15 interface
│   ├── application/
│   │   ├── services/              # 15 service
│   │   │   ├── auth_service.py    # v8.1: throwaway domain blok, şifre güç kontrolü,
│   │   │   │                      # email_token üretimi + Resend tetikleme
│   │   │   ├── exercise_service.py # v8.1: complete_session() use case
│   │   │   └── meal_compliance_service.py # v8.1: kademeli kalori artışı mantığı revize
│   │   └── schemas/
│   │       ├── auth.py            # v8.1: TokenResponse.email_verified eklendi
│   │       ├── ai_common.py       # JobStatus, QuotaInfo, FeedbackCreate
│   │       ├── workout_plan.py    # day_of_week: int (1-7) — Türkçe gün adı parse kaldırıldı
│   │       └── ...                # 17 schema toplam
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── models/            # 26 model
│   │   │       ├── user_model.py  # v8.1: +email_verified, +email_token, +email_token_expires
│   │   │       ├── user_preference_model.py
│   │   │       ├── onboarding_profile_model.py
│   │   │       ├── user_level_model.py
│   │   │       ├── body_measurement_model.py
│   │   │       ├── water_log_model.py
│   │   │       ├── sleep_log_model.py
│   │   │       ├── step_log_model.py
│   │   │       ├── meal_compliance_model.py
│   │   │       ├── menstrual_cycle_model.py
│   │   │       ├── exercise_session_model.py  # v8.1: +is_completed (seans seviyesi)
│   │   │       ├── session_exercise_model.py  # completed alanı var (egzersiz seviyesi — ayrı alan)
│   │   │       ├── exercise_catalog_model.py  # egzersiz kataloğu
│   │   │       ├── blood_values_model.py      # kan değerleri (v1.1)
│   │   │       ├── note_model.py              # haftalık check-in
│   │   │       ├── file_upload_model.py       # ilerleme fotoğrafları
│   │   │       ├── ai_job_model.py            # asenkron AI işleri
│   │   │       ├── ai_usage_log_model.py      # kota sayacı
│   │   │       ├── ai_response_cache_model.py # input_hash bazlı cache
│   │   │       ├── ai_feedback_model.py       # 👍/👎
│   │   │       ├── chat_message_model.py      # sohbet geçmişi
│   │   │       ├── friendship_model.py
│   │   │       ├── duel_model.py              # düello
│   │   │       ├── badge_model.py
│   │   │       ├── streak_model.py
│   │   │       └── shopping_item_model.py
│   │   ├── repositories/          # 15 repository
│   │   │   └── exercise_session_repository.py # v8.1: update()/_to_entity() artık
│   │   │                                       # is_completed'ı doğru okuyup yazıyor
│   │   │                                       # (test suite'in bulduğu gerçek bug, düzeltildi)
│   │   ├── storage/
│   │   └── logging/
│   ├── ai/
│   │   ├── client.py              # Claude client + model sabitleri
│   │   │                          # v8.1: MAX_TOKENS_RECIPE 1000→2200 (uzun tarifte JSON kesilip
│   │   │                          # parse hatası 500 veriyordu)
│   │   ├── context_builder.py     # ★ build_user_context() — tüm AI modüllerinin ortak bağlamı
│   │   ├── chat_assistant.py      # Haiku modeli, 3 kilitli kural
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py
│   │   │   └── calorie_vision_analyzer.py
│   │   └── generators/
│   │       ├── workout_generator.py
│   │       ├── meal_advisor.py
│   │       ├── recipe_generator.py     # v8.1: diyet uyumu ratio ≤1.20 sınırı eklendi
│   │       ├── calorie_bank_advisor.py
│   │       └── cycle_advisor.py
│   ├── middleware/
│   └── core/
│       ├── config.py              # QUOTA_LIMITS + model kademesi
│       │                          # v8.1: +RESEND_API_KEY, +APP_BASE_URL, +FROM_EMAIL
│       ├── security.py
│       ├── dependencies.py        # get_current_user_premium
│       ├── email_service.py       # v8.1 — yeni: Resend REST API wrapper (httpx, async)
│       │                          # send_verification_email() / resend / RESEND_API_KEY
│       │                          # yoksa sessiz console-log fallback (geliştirme modu)
│       ├── ai_rate_limiter.py
│       └── exceptions.py
├── migrations/
│   └── versions/
│       ├── 0001_baseline.py       # tüm 26 tablo buradan kuruluyor
│       ├── 0002_add_is_completed_to_exercise_sessions.py  # v8.1 — yeni
│       └── 0003_add_email_verification.py                 # v8.1 — yeni
│                                  # ★ ZİNCİR KURALI: down_revision bir önceki migration'a
│                                  #   bağlanmalı, asla baseline'dan paralel dallanmamalı
│                                  #   (bkz. Bölüm 20 — "Multiple head" production kesintisi yaşandı)
├── static/
│   ├── index.html
│   └── privacy-policy.html
└── tests/                         # v8.1 — artık DOLU (önceden sadece boş iskelet: integration/, unit/)
    ├── conftest.py                 # SQLite in-memory, unique email fixture, free/pro/other_user
    ├── test_auth.py                # 14 test — register, login, security, email verification
    ├── test_compliance.py          # 12 test — kalori uyum mantığı, kademeli artış
    ├── test_exercise.py            # 10 test — completion tracking, IDOR
    ├── test_features.py            # 11 test — shopping idempotency, measurements, preferences
    ├── test_onboarding_profile.py  # 10 test — onboarding, premium sync, hesap izolasyonu
    ├── integration/                # eskiden kalma boş iskelet, dokunulmadı
    └── unit/                       # eskiden kalma boş iskelet, dokunulmadı
```

---

## 6. Veritabanı Şeması — 26 Tablo

```sql
── KULLANICI / AUTH ──────────────────────────────────────
users                  # is_premium boolean
                       # v8.1: +email_verified (bool, default true — mevcut kullanıcılar kilitlenmesin)
                       #       +email_token (str, nullable)
                       #       +email_token_expires (datetime, nullable)
user_preferences       # boy, yaş, cinsiyet, hedef, ai_name, kan değerleri,
                       # diet_preference, target_weight_kg, daily_calorie_habit
onboarding_profile     # hedefler, diyet tercihi, target_weight_kg, daily_calorie_habit
user_levels            # XP sistemi

── TAKİP ─────────────────────────────────────────────────
body_measurements      # kilo, yağ, kas, bel, göğüs, kalça, kol, bacak
water_logs             # su tüketimi
sleep_logs             # uyku (süre, kalite, yatış/kalkış saati)
step_logs              # günlük adım sayısı (pedometer)
meal_compliance        # kalori bankası dahil, complied otomatik hesaplanıyor
                       # 3 durum: compliant / deviated / no_data
menstrual_cycles       # adet döngüsü takibi

── EGZERSİZ ─────────────────────────────────────────────
exercise_sessions      # antrenman seansları
                       # v8.1: +is_completed (bool) — SEANS seviyesi tamamlanma
                       #       (session_exercises.completed'tan farklı — o egzersiz seviyesi)
session_exercises      # seans içi egzersizler (JSON muscle_groups, completed)
exercise_catalog       # egzersiz kataloğu (AI grounding için ID listesi)

── SAĞLIK (v1.1) ────────────────────────────────────────
blood_values           # kan değerleri
weekly_notes           # haftalık check-in kartı
file_uploads           # ilerleme fotoğrafları

── AI ───────────────────────────────────────────────────
ai_jobs                # asenkron AI işleri (pending|running|done|failed)
ai_usage_logs          # kota sayacı (user_id + module + week_start, UniqueConstraint)
ai_response_cache      # input_hash bazlı cache (TTL: workout/meal/weekly=7gün, recipe=30gün)
ai_feedback            # 👍/👎 geri bildirim
chat_messages          # sohbet asistanı geçmişi

── SOSYAL / OYUN ────────────────────────────────────────
friendships            # arkadaşlık (pending/accepted/blocked)
duels                  # düello sistemi
badges                 # kazanılan rozetler
streaks                # water / exercise / sleep streak
shopping_items         # alışveriş listesi (quantity: STRING)
```

---

## 7. Input Validasyon Kuralları

```
── ONBOARDING / USER PREFERENCES ──
  height_cm      : 100 – 250 cm
  weight_kg      : 30  – 300 kg
  age            : 10  – 100
  gender         : male / female

── VÜCUT ÖLÇÜMLERİ ──
  weight_kg      : 30  – 300 kg
  body_fat_pct   : 1   – 60  %
  muscle_mass_kg : 10  – 150 kg
  waist_cm       : 30  – 200 cm

── SU TAKİBİ ──
  amount_ml      : 50  – 10000 ml
  target_ml      : 500 – 10000 ml

── UYKU ──
  duration_hours : 1   – 16 saat
  quality_score  : 1   – 10

── EGZERSİZ ──
  duration_minutes : 1   – 600 dk
  calories_burned  : 0   – 5000 kcal
  sets             : 1   – 20
  reps             : 1   – 200
  weight_kg        : 0   – 500 kg

── DİYET / KALORİ ──
  calories_consumed : 0  – 10000 kcal
  calories_target   : 0  – 10000 kcal

── ADIM SAYAR ──
  step_count     : 0   – 100000 adım/gün
  target_steps   : 1000 – 50000

── REGL ──
  cycle_length_days  : 20 – 45 gün
  period_length_days : 2  – 10 gün

── AUTH (v8.1 — yeni) ──
  password       : min 8 karakter, en az 1 harf + 1 rakam
  email          : throwaway/disposable domain blok listesi (mailinator, guerrillamail,
                   yopmail, 10minutemail vb. 50+ domain)
```

---

## 8. API Endpoint Yapısı — 122 Route

```
BASE: /api/v1

── AUTH ──
POST   /auth/register             # v8.1: kayıt sonrası async email doğrulama tetiklenir
                                   #       (try/except izole — Resend down olsa register başarısız olmaz)
POST   /auth/login                # v8.1: response'a email_verified flag eklendi
POST   /auth/refresh
GET    /auth/me                   # is_premium + email_verified döndürüyor
GET    /auth/verify-email         # v8.1 — yeni: HTML response, browser'dan açılır (mail linki)
POST   /auth/resend-verification  # v8.1 — yeni: doğrulanmamış kullanıcı için yeni mail tetikler

── ONBOARDING ──
POST/GET/PUT  /onboarding
POST          /onboarding/complete

── MEASUREMENTS ──
POST/GET/PUT/DELETE  /measurements

── MEAL COMPLIANCE ──
POST/GET/PUT/DELETE  /meal-compliance
GET                  /meal-compliance/date/{date}

── BARCODE ──
GET    /barcode/{barcode}

── EXERCISES ──
POST/GET/PUT/DELETE  /exercises/sessions
PATCH                /exercises/sessions/{id}/complete   # v8.1 — yeni: seansı tamamlandı işaretler
POST/GET/PUT/DELETE  /exercises/sessions/{id}/exercises

── WATER / SLEEP / STEPS ──
POST/GET/PUT/DELETE  /water
POST/GET/PUT/DELETE  /sleep
POST/GET/PUT         /steps

── SHOPPING ──
POST/GET/PUT/DELETE  /shopping
PATCH                /shopping/{id}/toggle
DELETE               /shopping/completed/clear

── REPORTS ──
GET    /reports/weekly?reference_date=
GET    /reports/monthly?year=&month=

── AI ──────────────────────────────────────────────────
POST   /ai/weekly-summary
POST   /ai/workout-plan
POST   /ai/meal-advice
POST   /ai/recipe                # v8.1: MAX_TOKENS_RECIPE 1000→2200, diyet uyumu sınırı eklendi
POST   /ai/calorie-from-photo
POST   /ai/calorie-bank-advice
POST   /ai/cycle-advice
POST   /ai/chat

GET    /ai/jobs/{id}
POST   /ai/feedback

── SOCIAL ──
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
GET    /social/friends/pending
GET    /social/leaderboard

── GAMIFICATION ──
GET    /gamification/summary
GET    /gamification/streaks
GET    /gamification/badges
GET    /gamification/level

── CYCLE ──
POST/GET/PUT  /cycle
GET           /cycle/history

── STATIC ──
GET    /
GET    /static/privacy-policy.html
GET    /health
GET    /docs
```

---

## 9. AI Mimarisi Detayı

*(Değişiklik yok — v8.0'daki context_builder, kota sistemi, job pattern, model seçimi aynen geçerli. Tek değişiklik: `MAX_TOKENS_RECIPE` 1000→2200, bkz. Bölüm 5.)*

### context_builder.py — Silo Sorununun Çözümü

```
Okur (son durum + son 7 gün):
  - Profil: hedef, hedef kilo, aktivite, diyet tercihi
  - Güncel ölçüm: kilo, boy, yaş
  - Son 7 gün: antrenman, beslenme uyumu %, kayıtsız gün sayısı, ort. kalori, ort. adım
  - Kullanıcının plana kendi eklediği egzersizler
  - Döngü fazı (regl — varsa)
  - Bugün kalan makrolar

Kural: ~300-500 token hedef, sayısal + kompakt, veri yoksa alan atlanır
```

### Kota Sistemi

```
QUOTA_LIMITS (config.py):
  free:     workout:1, meal:1, weekly:1, recipe:2, vision:3
  pro:      workout:3, meal:3, weekly:1, recipe:10, vision:20
  pro_plus: workout:7, meal:7, weekly:2, recipe:30, vision:60

QuotaService.check_and_consume() → atomik PostgreSQL UPSERT
Cache → sha256(payload + context) → cache isabet kota tüketmez
```

### Job Pattern

```
POST /ai/... → job_id döner → BackgroundTasks → poll (2sn) → GET /ai/jobs/{id}
IDOR koruması: job.user_id != current_user.id → 404
```

---

## 10. Flutter Uygulama Mimarisi — 37 Ekran

*(Klasör yapısı v8.0'dan değişmedi — bu sprintte sadece içerik/mantık fix'leri yapıldı, yeni dosya eklenmedi. Önemli dosyalardaki değişiklikler:)*

```
mobile/lib/
├── core/auth/token_manager.dart      # v8.1: syncFromMe() — /auth/me'den taze premium+email_verified
│                                      # durumunu prefs cache'ine senkronlar
├── core/api/endpoints.dart           # v8.1: +verifyEmail, +resendVerification, +completeSession
├── screens/auth/login_screen.dart    # v8.1: account-switch izolasyon kontrolü
├── screens/home/home_screen.dart     # v8.1: doğrulanmamış email banner (showBanner)
├── screens/egzersiz/
│   ├── egzersiz_screen.dart          # v8.1: tamamlanan seans ✅ badge + turuncu border
│   └── seans_detay_screen.dart       # v8.1: "tüm egzersizler done → seans complete" tetikleyici
├── screens/takip/diyet_tab.dart      # v8.1: besin tercihleri inline düzenleme (_showFoodPrefsSheet)
└── screens/profil/profil_screen.dart # v8.1: weight_gain dropdown seçeneği eklendi
```

*(Diğer tüm ekranlar v8.0'daki gibi — tam dosya listesi için önceki versiyona bakılabilir.)*

---

## 11. Flutter Ekran Durumu

*(v8.0 tablosu byk ölçüde geçerli. Bu sprintte dokunulan ve durumu değişen ekranlar:)*

| Ekran | v8.0 Durum | v8.1 Durum | Not |
|---|---|---|---|
| Egzersiz | ⚠️ | ✅ (kısmen) | Seans completion artık çalışıyor; kas grafiği eksikliği hâlâ açık |
| Takip — Diyet | ✅ | ✅ | Besin tercihleri artık inline düzenlenebiliyor |
| Profil | ⚠️ | ⚠️ → kısmen ✅ | Hedef (weight_gain) artık seçilebiliyor; AI ismi güncelleme durumu doğrulanmadı |
| Login/Register | ✅ | ✅ | Email doğrulama banner'ı eklendi (home_screen üzerinden) |

*(Diğer tüm satırlar v8.0 ile aynı — değişmedi.)*

---

## 12. Shared_prefs Veri Yapısı

*(v8.0 ile aynı, değişiklik yok.)*

---

## 13. Kalori Bankası Sistemi

```
TDEE = BMR × aktivite_katsayısı (Mifflin-St Jeor)

v8.1 — Kademeli Kalori Artışı (yeni mantık):
  daily_calorie_habit = "under_1500" gibi düşük alışkanlıklı kullanıcılara
  TDEE'den direkt yüksek hedef verilmiyor (eskiden 2000+ veriliyordu, çok agresifti).
  Bunun yerine: habit_base (1500) + haftalık uyum durumuna göre adım:
    - 6+ gün uyumlu  → +400 kcal adım
    - 6 günden az    → +200 kcal adım
  Minimum güvenli taban: 1200 kcal (hiçbir zaman altına düşmez)

v8.1 — Diyet Uyumu Mantığı Düzeltmesi:
  ESKİ: ratio < 0.80 → uyumsuz sayılıyordu (az yemek cezalandırılıyordu — YANLIŞ)
  YENİ: sadece ratio > 1.20 (hedefi %20+ aşmak) uyumsuz sayılıyor
        Eksik tüketim HER ZAMAN uyumlu (kilo verme başarısı, ceza değil)

calorie_balance     = (calories_consumed - calories_burned) - calories_target
weekly_bank_balance = son 7 günün (target - net_consumed) toplamı

⚠️ AÇIK SORUN (v8.0'dan devam ediyor — bu sprintte dokunulmadı):
  - Kalori bankası hedefi 0 görünüyor (ölçüm girilmeden TDEE hesaplanamıyor)
  - Diyet tavsiyesi ile kalori bankası önerileri çelişiyor
  - Telafi seçenekleri sonrası scroll çalışmıyor
```

---

## 14. AI Diyet Planı Sistemi

```
meal_advisor.py → 7 günlük haftalık plan + ingredients alanı

v8.1: recipe_generator.py → MAX_TOKENS_RECIPE 1000→2200
      (uzun tarifte JSON kesilip parse hatası → 500 veriyordu, artık çözüldü)
      + diyet uyumu ratio ≤1.20 sınırı eklendi

diyet_tab.dart:
  → v8.1: "Önerilen besinler" artık inline düzenlenebiliyor (_showFoodPrefsSheet)
    AI koçun önerdiği besinlere kullanıcı ekleme/çıkarma yapabiliyor
  → v8.1: junk food validasyonu — "cips", "kola", "pizza" gibi girişler reddediliyor
```

---

## 15. Onboarding Akışı

```
Adım 1-6: (v8.0 ile aynı)

v8.1 düzeltmeleri:
  - Onboarding artık uygulama kapatılıp açılınca KALDIĞI YERDEN devam ediyor
    (eskiden home'a atlıyordu — is_completed kontrolü splash'te eklendi)
  - "Kilo almak" hedefi artık doğru şekilde fitness_goal = "weight_gain" olarak
    kaydediliyor (eskiden "muscle_gain"a maplenip karışıyordu)
  - "<1500 kcal" seçeneğinin metni netleştirildi: "Çok az yiyorum, genelde aç hissediyorum"

⚠️ AÇIK SORUN (v8.0'dan devam ediyor — bu sprintte doğrulanmadı):
  - Onboarding başlangıç kilosu dashboard'a aktarılmıyor (kısmen düzeltilmiş olabilir,
    ölçüm endpoint'ine post ediliyor artık — ama dashboard görünümü teyit edilmedi)
```

---

## 16. Regl Takvimi Sistemi

*(v8.0 ile aynı, değişiklik yok.)*

---

## 17. Gamification Sistemi

*(v8.0 ile aynı, değişiklik yok.)*

---

## 18. Monetizasyon Planı

*(v8.0 ile aynı, değişiklik yok. RevenueCat entegrasyonu hâlâ V1.1 kapsamında, bağlanmadı.)*

---

## 19. Güvenlik

```
JWT Flow:
  1. POST /auth/login → access_token (30dk) + refresh_token (7gün) + email_verified flag (v8.1)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 → POST /auth/refresh (AuthInterceptor otomatik)

CORS: allow_origins=["*"], allow_credentials=False

AI Job IDOR: job.user_id != current_user.id → 404
Exercise Session IDOR (v8.1): session.user_id != current_user.id → 404
  (test suite'te doğrulandı: test_sec01_idor_session_read, test_idor_complete_other_session)

v8.1 — Yeni İş Kuralları:
  - Throwaway/disposable email domain blok listesi (register'da)
  - Şifre minimum güç kontrolü: 8+ karakter, harf+rakam zorunlu
  - Email doğrulama: kayıt sonrası token üretilir (24 saat geçerli),
    doğrulanana kadar hesap kilitlenmiyor (email_verified=true default —
    mevcut kullanıcıları kilitlememek için)

Env Variables (Render):
  DATABASE_URL
  SECRET_KEY
  ANTHROPIC_API_KEY
  OPEN_FOOD_FACTS_BASE_URL
  RESEND_API_KEY        # v8.1 — yeni
  APP_BASE_URL           # v8.1 — yeni (doğrulama linkinde kullanılıyor)
  FROM_EMAIL             # v8.1 — yeni, varsayılan: "TrackForge <onboarding@resend.dev>"
                          # ⚠️ kendi domain'in doğrulanmadan farklı bir adres kullanılamaz
```

---

## 20. Kritik Teknik Notlar

```
# Flutter / Dio
- flutter_secure_storage → shared_prefs (web uyumluluğu)
- Dio LinkedMap cast → Map<String, dynamic>.from() zorunlu
- Row içinde ElevatedButton → SizedBox ile wrap et
- CardTheme → CardThemeData (Flutter 3.41.6 breaking change)
- initState'de context kullanma → didChangeDependencies kullan
- _initialized flag → PUT sonrası UI override önleme

# API Davranışları
- POST /ai/calorie-from-photo → multipart, field: "file", manuel Auth header
- GET /shopping → {items: [...], summary: {...}}
- POST /shopping → quantity: STRING (int değil)
- GET /reports/* → nested objeler (summary field yok)
- activity_level → _safeActivityLevel() ile handle et
- complied → backend otomatik hesaplıyor, POST/PUT'a gönderilmiyor
- GET /social/friends/pending → PendingRequestResponse (requester_name JOIN ile)
- AI rate limit aşılınca → 429 + QUOTA_EXCEEDED → QuotaBanner + "PRO'ya geç"
- GET /ai/jobs/{id} → status + result (IDOR korumalı)
- PATCH /exercises/sessions/{id}/complete → is_completed: true döner (v8.1)
- POST /auth/register → email_verified: false döner (yeni kullanıcı, v8.1)

# Egzersiz / Kas Grubu
- BodyMapWidget KALDIRILDI
- body_map_widget.dart + muscle__front_and_back.svg SİLİNMELİ (hâlâ açık)
- extractMuscleGroups() → egzersiz_screen.dart'ta tanımlı

# Build
- Kaynak: C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\mobile\
- Build: C:\TrackForge\ (Türkçe karakter sorunu)
- Android SDK: C:\Android\
- Pub cache: C:\pub-cache\
- Java: JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
- Git: PowerShell'de && çalışmaz, komutları ayrı çalıştır
- Windows Defender exclusion: C:\Android, C:\TrackForge
- ★ Patch dağıtımı: backend/ ve mobile/ İKİ AYRI dizine git apply edilmeli
  (PyCharmProject\TrackForge köküne backend patch, C:\TrackForge köküne flutter patch — sırasıyla)
  Sonra robocopy ile senkron: robocopy C:\TrackForge → PyCharmProject\TrackForge\mobile /E /IS /IT

# Alembic — ★★★ KRİTİK DERS (v8.1)
- .env backend/ klasöründe
- Root'tan çalıştır: alembic -c backend/alembic.ini <komut>
- Migration zinciri: 0001_baseline → 0002_add_is_completed → 0003_add_email_verification
- Render start command: alembic upgrade head (tekil)
- ⚠️ YENİ MİGRATION EKLERKEN: down_revision MUTLAKA bir önceki migration'ın revision
  ID'sine bağlanmalı, ASLA aynı baseline'dan paralel dallandırılmamalı.
  Bu hata bir kez yapıldı (0002 ve 0003 ikisi de "0001_baseline"a bağlıydı),
  Render production deploy'unda "Multiple head revisions" hatasıyla servis düşürdü.
  Deploy öncesi her zaman lokal doğrula: `alembic heads` → tek satır dönmeli.

# CI Flake8
flake8 backend/app/ --max-line-length=500
  --extend-ignore=W292,W291,W391,E302,E303,E305,E261,E262,E265,E231,F401,E741,F821,E501
- E221 (hizalama boşluğu) ve E114/E116 (girinti) hatalarına dikkat —
  kod yazarken görsel hizalama için fazladan boşluk eklenmemeli

# Test Suite (v8.1 — yeni)
- backend/tests/ — 57 pytest testi, SQLite in-memory, ~10 saniyede tamamlanır
- Çalıştırma: python -m pytest backend/tests/ -q
- Marker filtreleme: -m "p0" / -m "regression" / -m "security"
- Push öncesi mutlaka çalıştır — backend mantık hatalarını CI'a gitmeden yakalar
- 3 test SQLite transaction izolasyon limitasyonu nedeniyle xfail —
  bunlar production PostgreSQL'de çalışır, test ortamı kısıtlaması

# State Management
- ThemeModeNotifier / StateNotifierProvider → dark mode
- _genderProvider → regl ekranı kontrolü
- AI diyet → shared_prefs (user_id bazlı)
- RateLimiter → sadece UX (shared_prefs, user_id bazlı)
- Logout → clearUserLimits() + diyet cache temizleme
- syncFromMe() (v8.1) → login/splash'te /auth/me'den premium+email_verified senkronu
```

---

## 21. Build Ortamı Durumu

*(v8.0 ile aynı, değişiklik yok.)*

| Şey | Durum |
|---|---|
| Build alınıyor | ✅ |
| Package name | ✅ com.memetsacal.trackforge |
| Keystore / signing | ✅ trackforge-release.jks, alias: trackforge |
| Uygulama açılıyor | ✅ |
| Genel işlevsellik | ✅ |
| APK testleri | ⏳ Devam ediyor |
| Bildirim ikonu | ⚠️ Geçici (@mipmap/ic_launcher) |
| Splash ekranı | ❌ Çalışmıyor |
| Build süresi | ⚠️ 2-3 dk — Windows Defender exclusion ekle |

---

## 22. Geliştirme Fazları

| Faz | İçerik | Durum |
|---|---|---|
| 1-15 | *(v8.0 ile aynı — bkz. önceki versiyon)* | ✅ |
| 16 | V1.1 — RevenueCat, FCM, Health Connect, Apple Developer | ⏳ Operasyon bağımlı |
| **17** | **Bug Fix Round 3 — 23 madde + Email Doğrulama (Resend) + Egzersiz Completion + Test Suite (57 test) + CI lint fix + Migration zincir düzeltmesi** | **✅ (20 Haziran 2026)** |

---

## 23. Açık Sorunlar

### 🔴 Kritik
- **body_map_widget.dart + muscle__front_and_back.svg silinmeli** — derleme hatası verir *(değişmedi)*
- **Splash ekranı çalışmıyor** — styles.xml bağlantısı kopuk *(bu sprintte dokunulmadı — splash_screen.dart'taki session kontrol mantığı düzeltildi ama native Android splash render sorunu ayrı, hâlâ açık)*

### 🟢 v8.1'de Çözüldüğü Yüksek Güvenle Bilinen Maddeler (v8.0'da açıktı)
- ~~Premium hesap client-side limitöre takılıyor~~ → `syncFromMe()` ile /auth/me'den okunuyor, test suite'te doğrulandı (`test_prof04_premium_sync`)
- ~~Çapraz hesap veri sorunu (uyku/kalori/egzersiz sızıyor)~~ → hesap izolasyonu fix'lendi, çoklu testte doğrulandı (`test_prof01_account_isolation`, `test_fail06_user_switch_request_isolation`)
- ~~Profil — hedef değiştirilemiyor~~ → weight_gain mapping fix'i + dropdown güncellendi, test'te doğrulandı (`test_fitness_goal_weight_gain`)

### 🟡 Önemli (hâlâ açık veya doğrulanmadı)
- **Egzersiz 2 kere ekleniyor** — duplicate insert var *(bu sprintte dokunulmadı, hâlâ açık olabilir — doğrula)*
- **Profil — AI ismi güncellenmiyor** — ai_name PUT sonrası yansımıyor *(bu sprintte dokunulmadı — onboarding'de ai_name kaydı var ama profil ekranından PUT akışı ayrı, doğrulanmadı)*
- **Onboarding başlangıç kilosu dashboard'a aktarılmıyor** *(kısmen düzeltilmiş olabilir — ölçüm endpoint'ine post ediliyor, ama dashboard görünümü teyit edilmedi, cihazda kontrol et)*

### 🟠 UI/UX
- **Kalori bankası telafi scroll yok** *(değişmedi)*
- **Kalori bankası UI renksiz** — detailed_advice düz metin *(değişmedi)*
- **Antrenman planı — egzersiz ekle butonu kaldırılacak** *(değişmedi)*
- **Egzersiz kas grubu grafiği** — seans detayında çıkmıyor *(değişmedi — seans completion ayrı, bu farklı bir özellik eksikliği)*
- **Dashboard — serilere tümüne bas** → gamification'a yönlendirmiyor *(değişmedi)*
- **Ölçüm tabı — yağ oranı tekrar hesaplama** çalışmıyor *(değişmedi)*
- **Ölçüm tabı — boy profilden gelmiyor** *(değişmedi)*

### ⏳ Bekleyen
- Bildirim ikonu kalıcı fix (drawable vector XML)
- Play Store — App icon (512x512), Feature graphic, screenshots, İngilizce listing, content rating
- Email gönderiminde kendi domain'in doğrulanması (şu an `onboarding@resend.dev` sandbox kullanılıyor —
  sadece Resend hesap sahibinin mailine garantili gönderim, geniş kullanıcı tabanı için domain doğrulama şart)

---

## 24. Play Store Durumu

*(v8.0 ile aynı, değişiklik yok.)*

| Alan | Durum |
|---|---|
| Google Developer hesabı | ✅ Onaylandı |
| Package name | com.memetsacal.trackforge |
| Versiyon | 1.0.0+1 |
| AAB build | ✅ 59.5MB |
| Dahili test | ✅ Yüklendi, aktif |
| Türkçe listing | ✅ Taslak |
| İngilizce listing | ⏳ |
| App icon (512x512) | ⏳ |
| Feature graphic (1024x500) | ⏳ |
| Telefon screenshots | ⏳ |
| Content rating | ⏳ |
| Privacy policy URL | ✅ Canlıda |
| Üretim sürümü | ⏳ Açık sorunlar çözülünce |

**Apple Developer:** Support'a mail atıldı (kimlik doğrulama sorunu), cevap bekleniyor.

---

## 25. V1.1 Planı — Operasyon Bağımlı

| Özellik | Bağımlılık | Durum |
|---|---|---|
| **FCM — proaktif bildirimler** | FCM kurulumu | ⏳ **Sıradaki** |
| RevenueCat — abonelik + AI hakkı satın alma | Ekranlar hazır, satın alma bağlanacak | ⏳ |
| Health Connect — giyilebilir / toparlanma skoru | Health Connect API | ⏳ |
| `/billing/add-credits` — consumable satın alımda kotaya ek hak | RevenueCat sonrası | ⏳ |
| Çoklu dil — TR + EN (flutter_localizations + intl) | — | ⏳ |
| Email domain doğrulama | Resend Domains (DNS kayıtları) | ⏳ |
| Regl fazı AI entegrasyonu derinleştirme | context_builder üzerinden zaten var | — |
| Antrenman planı kas grubu tekrar önleme | workout_generator revize modu | ⏳ |
| Apple Developer hesabı | Kimlik doğrulama sorunu çözülünce | ⏳ |

---

## 26. Canlı URL'ler

*(v8.0 ile aynı, değişiklik yok.)*

| Servis | URL |
|---|---|
| Backend | https://trackforge-3o2j.onrender.com |
| Landing page | https://trackforge-3o2j.onrender.com/ |
| Privacy policy | https://trackforge-3o2j.onrender.com/static/privacy-policy.html |
| API Docs | https://trackforge-3o2j.onrender.com/docs |

---

## 27. Önemli Dosya Yolları

*(v8.0 ile aynı, değişiklik yok.)*

| Dosya | Yol |
|---|---|
| Kaynak (mobile) | C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\mobile\ |
| Build klasörü | C:\TrackForge\ |
| Android SDK | C:\Android\ |
| Release APK | C:\TrackForge\build\app\outputs\flutter-apk\app-release.apk |
| Release AAB | C:\TrackForge\build\app\outputs\bundle\release\app-release.aab |
| Keystore | C:\TrackForge\android\app\trackforge-release.jks |
| Keystore yedek | Masaüstü → ÖNEMLİ (TRACKFORGE) klasörü |
| key.properties | C:\TrackForge\android\key.properties |
| .env | C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\backend\.env |

---

*Bu doküman projenin yaşayan anayasası.*
*Son güncelleme: 20 Haziran 2026 — v8.1*
*Prod canlı · 26 tablo · 122 route · 37 mobil ekran · tek migration head (0003_add_email_verification)*
*Bu sprintte: 23 bug fix + email doğrulama + egzersiz completion + 57 testlik suite + CI/migration düzeltmeleri*
*Sonraki: FCM push notification → RevenueCat → Health Connect → Apple Developer → Play Store submit*