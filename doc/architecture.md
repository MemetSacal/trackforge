# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v8.0 — Tam Güncel
**Tarih:** 15 Haziran 2026
**Mimari:** Clean Architecture + Repository Pattern
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First
**Durum:** Prod canlı · 26 tablo · 119 route · 37 mobil ekran · tek migration head (0001_baseline)

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
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
  ┌────────▼──────┐          ┌────────▼──────────┐
  │  PostgreSQL   │          │  Static Files      │
  │  (Render)     │          │  landing + privacy │
  └───────────────┘          └───────────────────┘
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

Akış: **Entity → Interface → Model → Repository → Service → Schema → Endpoint**

---

## 5. Backend Klasör Yapısı

```
backend/
├── .env
├── app/
│   ├── main.py                    # FastAPI app, CORS, routing, static
│   ├── api/v1/
│   │   ├── router.py
│   │   └── endpoints/
│   │       ├── auth.py
│   │       ├── measurements.py
│   │       ├── notes.py
│   │       ├── meal_compliance.py
│   │       ├── files.py
│   │       ├── exercises.py
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
│   │   │   ├── user_preference.py # diet_preference, ai_name, target_weight_kg, daily_calorie_habit
│   │   │   └── ...
│   │   └── interfaces/            # 15 interface
│   ├── application/
│   │   ├── services/              # 15 service
│   │   └── schemas/
│   │       ├── ai_common.py       # JobStatus, QuotaInfo, FeedbackCreate
│   │       ├── workout_plan.py    # day_of_week: int (1-7) — Türkçe gün adı parse kaldırıldı
│   │       └── ...                # 17 schema toplam
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── models/            # 26 model
│   │   │       ├── user_model.py
│   │   │       ├── user_preference_model.py
│   │   │       ├── onboarding_profile_model.py
│   │   │       ├── user_level_model.py
│   │   │       ├── body_measurement_model.py
│   │   │       ├── water_log_model.py
│   │   │       ├── sleep_log_model.py
│   │   │       ├── step_log_model.py
│   │   │       ├── meal_compliance_model.py
│   │   │       ├── menstrual_cycle_model.py
│   │   │       ├── exercise_session_model.py
│   │   │       ├── session_exercise_model.py  # completed alanı var
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
│   │   ├── storage/
│   │   └── logging/
│   ├── ai/
│   │   ├── client.py              # Claude client + model sabitleri
│   │   ├── context_builder.py     # ★ build_user_context() — tüm AI modüllerinin ortak bağlamı
│   │   │                          # Okur: ölçümler, egzersiz, beslenme, kan değerleri,
│   │   │                          # haftalık check-in, regl fazı, kalan makrolar
│   │   ├── chat_assistant.py      # Haiku modeli, 3 kilitli kural:
│   │   │                          # plan üretmez / token tavanı / ucuz model + kota
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py # vision öğünleri dahil + geçen hafta gerçekleşmesi
│   │   │   └── calorie_vision_analyzer.py  # sonuç → meal_draft → kullanıcı onaylayınca öğün kaydı
│   │   └── generators/
│   │       ├── workout_generator.py    # context + egzersiz ID grounding
│   │       │                           # day_of_week: int, mode: generate|revise
│   │       ├── meal_advisor.py         # context + ingredients alanı + revise_remaining_days modu
│   │       ├── recipe_generator.py     # kalan makro context + fridge_photo opsiyonel
│   │       ├── calorie_bank_advisor.py
│   │       └── cycle_advisor.py        # regl fazı → antrenman + beslenme tavsiyesi
│   ├── middleware/
│   └── core/
│       ├── config.py              # QUOTA_LIMITS + model kademesi buraya taşındı
│       ├── security.py
│       ├── dependencies.py        # get_current_user_premium
│       ├── ai_rate_limiter.py     # backend kota enforcement (tek doğruluk kaynağı)
│       │                          # QuotaService.check_and_consume() → atomik UPSERT
│       │                          # 429 + QUOTA_EXCEEDED döner
│       └── exceptions.py
├── migrations/
│   └── versions/
│       └── 0001_baseline.py       # ★ tek migration — tüm 26 tablo buradan kuruluyor
│                                  # Yeni özellik → baseline üstüne zincirle
├── static/
│   ├── index.html                 # Landing page
│   └── privacy-policy.html
└── tests/
    ├── integration/
    └── unit/
```

---

## 6. Veritabanı Şeması — 26 Tablo

```sql
── KULLANICI / AUTH ──────────────────────────────────────
users                  # is_premium boolean
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
```

---

## 8. API Endpoint Yapısı — 119 Route

```
BASE: /api/v1

── AUTH ──
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/me           # is_premium döndürüyor

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
# Akış: input_hash → cache? → varsa dön (kota tüketilmez)
#        → yoksa QuotaService.check_and_consume() → job oluştur → BackgroundTasks
#        → client job_id ile poll eder → done olunca sonuç

POST   /ai/weekly-summary        # Free: 1/hafta  | Premium: sınırsız
POST   /ai/workout-plan          # Free: 1/hafta  | Premium: sınırsız
                                 # mode: generate|revise, day_of_week: int (1-7)
POST   /ai/meal-advice           # Free: 1/hafta  | Premium: sınırsız
                                 # ingredients alanı dahil, revise_remaining_days modu
POST   /ai/recipe                # Free: 2/hafta  | limit düşük
POST   /ai/calorie-from-photo    # Free: 3/gün    | Premium: sınırsız
                                 # multipart/form-data, field: "file"
                                 # → meal_draft döner, kullanıcı onaylayınca öğün kaydı
POST   /ai/calorie-bank-advice   # limit yok
POST   /ai/cycle-advice          # limit yok
POST   /ai/chat                  # Haiku modeli, sohbet asistanı, token tavanı var

GET    /ai/jobs/{id}             # job durumu + sonuç (IDOR korumalı)
POST   /ai/feedback              # 👍/👎 + opsiyonel yorum

── SOCIAL ──
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
GET    /social/friends/pending    # requester_name JOIN ile
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

### context_builder.py — Silo Sorununun Çözümü

Tüm AI modüllerinin prompt'una giren standart bağlam bloğu.
Beş modül aynı koçun beyni gibi davranır.

```
Okur (son durum + son 7 gün):
  - Profil: hedef, hedef kilo, aktivite, diyet tercihi
  - Güncel ölçüm: kilo, boy, yaş
  - Son 7 gün: antrenman (tamamlanan/planlanan + serbest seanslar),
    beslenme uyumu %, kayıtsız gün sayısı, ort. kalori, ort. adım
  - Kullanıcının plana kendi eklediği egzersizler (AI'a sinyal)
  - Döngü fazı (regl — varsa)
  - Bugün kalan makrolar (kcal, protein, karbonhidrat, yağ)

Kural: ~300-500 token hedef, sayısal + kompakt, veri yoksa alan atlanır
```

### Kota Sistemi

```
── QUOTA_LIMITS (config.py) ─────────────────────────────
  free:     workout:1, meal:1, weekly:1, recipe:2, vision:3
  pro:      workout:3, meal:3, weekly:1, recipe:10, vision:20
  pro_plus: workout:7, meal:7, weekly:2, recipe:30, vision:60

── QuotaService (ai_rate_limiter.py) ────────────────────
  check_and_consume() → atomik PostgreSQL UPSERT
  Limit aşılınca → 429 + QUOTA_EXCEEDED + resets_in_days
  is_premium = true → bypass

── Cache (ai_response_cache) ────────────────────────────
  sha256(payload + context özeti) → input_hash
  Cache isabet → kota TÜKETİLMEZ (önce cache, sonra kota)
  TTL: workout/meal/weekly=7gün, recipe=30gün, vision=0 (cache yok)

── Client Side (rate_limiter.dart) ──────────────────────
  Artık sadece UX — butonu önceden gri göstermek
  Tek doğruluk kaynağı: backend
  429 → QuotaException → QuotaBanner + "PRO'ya geç"
  Sunucudan dönen quota objesi SharedPrefs'e yazılır → senkron kalır
```

### Job Pattern

```
POST /ai/... → job_id döner (hızlı)
BackgroundTasks → run_ai_job(job_id) arka planda çalışır
Flutter → AiJobPoller.watch(jobId) stream ile poll eder (2sn aralık)
GET /ai/jobs/{id} → status: pending|running|done|failed + result
IDOR koruması: job.user_id != current_user.id → 404
```

### AI Modelleri

```
claude-sonnet-4-5  → ana üretim (workout, meal, recipe, weekly, vision, calorie_bank, cycle)
claude-haiku-4-5-20251001 → sohbet asistanı (ucuz, hızlı, token tavanı var)
```

---

## 10. Flutter Uygulama Mimarisi — 37 Ekran

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart              # GoRouter, ThemeModeNotifier, ProviderScope
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart       # Dio + AuthInterceptor
│   │   │   │                         # 429 → QuotaException interceptor
│   │   │   ├── endpoints.dart
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   └── token_manager.dart
│   │   ├── services/
│   │   │   ├── rate_limiter.dart     # Artık sadece UX (buton durumu)
│   │   │   │                         # Güvenlik değil — esas otorite 429
│   │   │   └── ai_job_poller.dart    # job_id → poll → sonuç stream
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── notifications/
│   │   │   └── notification_service.dart  # ⚠️ bildirim ikonu geçici
│   │   └── utils/
│   │       └── date_utils.dart
│   ├── features/
│   │   ├── ai/
│   │   │   ├── providers/
│   │   │   │   └── ai_job_provider.dart   # Riverpod: job durumu state machine
│   │   │   └── widgets/
│   │   │       ├── ai_feedback_bar.dart   # Her AI çıktısının altında 👍/👎
│   │   │       ├── quota_banner.dart      # "Bu hafta 2/3 hakkın kaldı" + paywall köprüsü
│   │   │       └── ai_progress_sheet.dart # "Koçun hazırlıyor..." aşamalı bekleme UI
│   │   ├── meals/
│   │   │   └── meal_entry_hub.dart        # ★ TEK giriş: Manuel | Barkod | Foto (vision)
│   │   ├── workout/
│   │   │   └── extra_session_sheet.dart   # AI planı dışı "serbest seans" akışı
│   │   └── shopping/
│   │       └── plan_to_shopping_service.dart  # Haftalık plan → tek tuş alışveriş listesi
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart          # logo, dark/light toggle, beni hatırla
│       │   └── register_screen.dart
│       ├── onboarding/
│       │   └── onboarding_screen.dart     # 6 adım + validasyon
│       ├── home/
│       │   ├── dashboard_screen.dart      # count-up, check-in kartı, AI koç kartı
│       │   ├── home_screen.dart
│       │   └── more_screen.dart
│       ├── takip/
│       │   ├── takip_screen.dart
│       │   ├── olcum_tab.dart
│       │   ├── diyet_tab.dart             # 7 günlük haftalık plan + "Alışverişe aktar" butonu
│       │   ├── su_tab.dart                # dolan bardak animasyonu
│       │   └── uyku_tab.dart
│       ├── egzersiz/
│       │   ├── egzersiz_screen.dart       # bar chart, haptic tamamlama
│       │   └── seans_detay_screen.dart
│       ├── ai/
│       │   ├── ai_screen.dart
│       │   ├── ai_helpers.dart
│       │   ├── weekly_summary_screen.dart # kartlı özet + AiFeedbackBar
│       │   ├── workout_plan_screen.dart   # staged loader + QuotaBanner
│       │   ├── meal_advice_screen.dart    # QuotaBanner + "kalan günleri güncelle"
│       │   ├── recipe_screen.dart
│       │   ├── calorie_vision_screen.dart # "Öğün olarak kaydet" butonu
│       │   ├── cycle_advice_screen.dart
│       │   └── chat_screen.dart           # Haiku sohbet asistanı
│       ├── health/                        # v1.1
│       │   ├── blood_values_screen.dart
│       │   ├── progress_photos_screen.dart
│       │   ├── insights_screen.dart       # korelasyon kartları
│       │   └── checkin_screen.dart        # haftalık check-in
│       ├── billing/                       # RevenueCat'e hazır iskelet
│       │   ├── subscription_screen.dart
│       │   ├── paywall_screen.dart
│       │   └── ai_credits_screen.dart     # consumable AI hakkı paketleri
│       ├── raporlar/
│       │   └── raporlar_screen.dart       # fl_chart + Wrapped + PDF rapor
│       ├── sosyal/
│       │   ├── sosyal_screen.dart         # pending requests + liderboard
│       │   └── duel_screen.dart           # düello
│       ├── gamification/
│       │   └── gamification_screen.dart   # XP, rozetler (konfeti)
│       ├── profil/
│       │   └── profil_screen.dart         # bilgiler + PRO rozeti
│       ├── more/
│       │   └── more_screen.dart
│       ├── notifications/
│       │   └── notification_screen.dart
│       ├── steps/
│       │   └── steps_screen.dart
│       ├── alisveris/
│       │   └── alisveris_screen.dart      # barkod + liste
│       ├── cycle/
│       │   └── cycle_screen.dart          # gender == female kontrolü
│       └── splash/
│           └── splash_screen.dart         # ❌ çalışmıyor
├── widgets/
│   ├── body_map/
│   │   └── body_map_widget.dart           # ❌ SİLİNMELİ — kullanılmıyor
│   └── core/                              # Cila katmanı
│       ├── count_up_text.dart
│       ├── pulse_skeleton.dart
│       ├── staged_loader.dart
│       └── celebrate.dart                 # konfeti
├── assets/
│   └── images/
│       ├── app_icon.png
│       └── splash_bg.png
│       # ❌ muscle__front_and_back.svg SİLİNMELİ
└── android/
    └── trackforge-release.jks
```

---

## 11. Flutter Ekran Durumu

| Ekran | Durum | Notlar |
|---|---|---|
| Login / Register | ✅ | JWT flow, beni hatırla |
| Onboarding | ✅ | 6 adım, backend entegre |
| Dashboard | ✅ | Gamification + AI koç kartı + check-in |
| Takip — Ölçüm | ⚠️ | Yağ oranı tekrar hesaplama yok, boy profilden gelmiyor |
| Takip — Diyet | ✅ | 7 günlük haftalık plan + alışverişe aktar |
| Takip — Su | ✅ | Dolan bardak animasyonu |
| Takip — Uyku | ✅ | TimePicker, kalite slider |
| Egzersiz | ⚠️ | Egzersiz 2 kere ekleniyor, kas grafiği yok |
| AI — Chat Asistanı | ✅ | Haiku modeli |
| AI — Haftalık Özet | ✅ | Kartlı + AiFeedbackBar |
| AI — Antrenman Planı | ⚠️ | Egzersiz ekle butonu kaldırılacak, kas grafiği yok |
| AI — Diyet Tavsiyesi | ✅ | QuotaBanner + shared_prefs cache |
| AI — Tarif Önerisi | ⚠️ | Ara sıra hata veriyor |
| AI — Vision Kalori | ✅ | "Öğün olarak kaydet" butonu |
| AI — Kalori Bankası | ⚠️ | Telafi sonrası scroll yok, UI renksiz |
| AI — Regl Tavsiyesi | ✅ | cycle_advice_screen |
| Health — Kan Değerleri | ✅ | v1.1 |
| Health — İlerleme Fotoğrafları | ✅ | v1.1 |
| Health — Insights | ✅ | korelasyon kartları |
| Health — Check-in | ✅ | haftalık check-in kartı |
| Billing — Abonelik | ✅ | RevenueCat iskelet hazır |
| Raporlar | ✅ | fl_chart + Wrapped + PDF |
| Sosyal | ✅ | pending istekler + liderboard |
| Düello | ✅ | duel_screen |
| Gamification | ✅ | XP, seviye, streak, rozetler (konfeti) |
| Alışveriş | ✅ | Liste + barkod |
| Adım Sayar | ⚠️ | Pedometer kapalı gözüküyor |
| Profil | ⚠️ | Hedef değiştirilemiyor, AI ismi güncellenmiyor |
| More | ✅ | Menü kartları |
| Regl Takvimi | ✅ | Sadece gender == female |
| Bildirimler | ✅ | notification_screen |
| Splash | ❌ | Çalışmıyor |

---

## 12. Shared_prefs Veri Yapısı

```dart
// ── Auth & User ─────────────────────────────────────
'access_token'
'refresh_token'
'current_user_id'
'remembered_email'

// ── Tema ────────────────────────────────────────────
'theme_mode'

// ── AI Diyet Planı (user_id bazlı) ──────────────────
'last_meal_advice_{userId}'
'last_meal_advice_date_{userId}'
'last_recommended_foods_{userId}'
'last_foods_to_avoid_{userId}'
'last_weekly_meal_plan_{userId}'

// ── AI Rate Limiter (user_id bazlı — sadece UX) ─────
'vision_count_{userId}_{Y}_{M}_{D}'
'weekly_analysis_{userId}_{Y}_w{N}'
'meal_advice_{userId}_{Y}_w{N}'
'workout_plan_{userId}_{Y}_w{N}'
// Sunucudan dönen quota objesi buraya yazılır → senkron

// ── Bildirimler ──────────────────────────────────────
'notif_water_enabled'
'notif_workout_enabled'
'notif_workout_hour' / 'notif_workout_min'
'notif_sleep_enabled'
'notif_sleep_hour' / 'notif_sleep_min'
'notif_meal_enabled'
'notif_steps_enabled'
'notif_streak_enabled'
'notif_weekly_enabled'
'in_app_notifications'
'notif_seeded_{Y}_{M}_{D}'
```

---

## 13. Kalori Bankası Sistemi

```
TDEE = BMR × aktivite_katsayısı
BMR  = Mifflin-St Jeor formülü

Kilo verme : günlük_hedef = TDEE - 500
Kas yapma  : günlük_hedef = TDEE + 250
Koruma     : günlük_hedef = TDEE

calorie_balance     = (calories_consumed - calories_burned) - calories_target
weekly_bank_balance = son 7 günün (target - net_consumed) toplamı
Minimum kalori      : 1500 kcal

today_max_calories  = daily_target + max(weekly_bank, 0)
complied → backend otomatik hesaplıyor
3 durum: compliant (%80-120) / deviated / no_data (ceza puanı üretmez)
Egzersiz kalorisi bankaya dahil
POST /ai/calorie-bank-advice → short_message, detailed_advice, tomorrow_suggestion, telafi_options

⚠️ AÇIK SORUN:
  - Kalori bankası hedefi 0 görünüyor (ölçüm girilmeden TDEE hesaplanamıyor)
  - Diyet tavsiyesi ile kalori bankası önerileri çelişiyor
  - Telafi seçenekleri sonrası scroll çalışmıyor
```

---

## 14. AI Diyet Planı Sistemi

```
meal_advisor.py → 7 günlük haftalık plan + ingredients alanı
fitness_goal → profilden otomatik okunuyor

  weekly_plan: {
    pazartesi: {
      breakfast, lunch, dinner, snack,
      ingredients: [{name, quantity_g}]  ← alışveriş listesi için
    }
    ...
  }

Flutter storage (user_id bazlı):
  last_meal_advice_{userId}
  last_meal_advice_date_{userId}
  last_recommended_foods_{userId}
  last_foods_to_avoid_{userId}
  last_weekly_meal_plan_{userId}

diyet_tab.dart:
  → Bugünün menüsü gösterilir
  → Haftalık plan 7 günlük sekme ile gezilir
  → "Alışveriş listesine aktar" butonu → PlanToShoppingService
  → complied switch kaldırıldı, backend otomatik hesaplıyor
  → Logout'ta user_id bazlı temizleniyor

MAX_TOKENS_MEAL = 3000
```

---

## 15. Onboarding Akışı

```
Adım 1: Hedefler (goals listesi, max 3 seçim)
Adım 2: Temel Bilgiler (boy, kilo, yaş, cinsiyet, hedef kilo — opsiyonel)
Adım 3: Aktivite seviyesi
Adım 4: Diyet tercihi
Adım 5: Kalori alışkanlığı
Adım 6: AI Koç ismi (atlarsa default: TrackForge AI)

_complete() → /onboarding/complete endpoint'ine gönderir
Senkronizasyon: goals[0] → fitness_goal, diet_preference,
                target_weight_kg, daily_calorie_habit → user_preferences'a da yazılır

⚠️ AÇIK SORUN:
  - Onboarding başlangıç kilosu dashboard'a aktarılmıyor
```

---

## 16. Regl Takvimi Sistemi

```
Görünürlük: gender == 'female' → _genderProvider

Faz 1 — Menstrüasyon (Gün 1–5)   → Hafif antrenman, demir açısından zengin
Faz 2 — Foliküler (Gün 6–13)     → Orta yoğun, protein ağırlıklı
Faz 3 — Ovülasyon (Gün 14–16)    → Zirve performans, kalori artırılabilir
Faz 4 — Luteal (Gün 17–28)       → Yoğunluk azalt, magnezyum açısından zengin

AI Entegrasyonu:
  → context_builder.py regl fazını okur
  → workout_generator + meal_advisor + weekly_analyzer + recipe_generator
    faz bilgisine göre kişiselleştirir
  → Ayrıca /ai/cycle-advice endpoint'i doğrudan faz tavsiyesi verir
```

---

## 17. Gamification Sistemi

| Seviye | Başlık | XP |
|---|---|---|
| 1 | Beginner | 0 |
| 2 | Active | 500 |
| 3 | Fit | 1500 |
| 4 | Athlete | 3000 |
| 5 | Champion | 6000 |

**XP Kaynakları:** Antrenman +50 · Su hedefi +20 · Uyku +15 · Rozet +100 · Haftalık rapor +10

| Badge Key | Açıklama | Tetikleyici |
|---|---|---|
| first_workout | İlk Antrenman 💪 | İlk seans |
| 7_day_water | 7 Gün Su 💧 | Water streak = 7 |
| 30_day_water | 30 Gün Su 🏆 | Water streak = 30 |
| weight_loss_5kg | 5 kg Kayıp ⚡ | Ölçüm farkı ≥ 5 kg |
| weight_loss_10kg | 10 kg Kayıp 🔥 | Ölçüm farkı ≥ 10 kg |
| first_photo | İlk Fotoğraf 📸 | İlk fotoğraf yüklendi |
| streak_warrior | Streak Savaşçısı ⚔️ | Exercise streak = 7 |

---

## 18. Monetizasyon Planı

| Paket | Fiyat | Özellikler |
|---|---|---|
| **Free** | Ücretsiz | Haftalık AI 1x, Diyet 1x/hafta, Antrenman 1x/hafta, Vision 3x/gün, Tarif 2x/hafta |
| **PRO** | 149 TL/ay | Analiz 3x, Diyet 3x/hafta, Antrenman 3x/hafta, Vision 20x/gün, Tarif 10x/hafta |
| **PRO+** | 299 TL/ay | Her şey sınırsız (7x/hafta), Öncelikli destek |

**Teknoloji:** RevenueCat + Google Play Billing (V1.1 — ekranlar hazır, satın alma bağlanacak)
**Şu an:** is_premium DB'de manuel — memetsacal@icloud.com → true

---

## 19. Güvenlik

```
JWT Flow:
  1. POST /auth/login → access_token (30dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 → POST /auth/refresh (AuthInterceptor otomatik)

CORS: allow_origins=["*"], allow_credentials=False

AI Job IDOR: job.user_id != current_user.id → 404

Env Variables (Render):
  DATABASE_URL
  SECRET_KEY
  ANTHROPIC_API_KEY
  OPEN_FOOD_FACTS_BASE_URL
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
- POST /ai/workout-plan → workout_location, fitness_goal, fitness_level,
  available_days, mode (generate|revise), day_of_week: int (1-7)
- POST /ai/meal-advice → haftalık plan + ingredients + bugünün meal_suggestions döner
- POST /ai/calorie-bank-advice → short_message, detailed_advice, tomorrow_suggestion, telafi_options
- activity_level → _safeActivityLevel() ile handle et
- complied → backend otomatik hesaplıyor, POST/PUT'a gönderilmiyor
- GET /social/friends/pending → PendingRequestResponse (requester_name JOIN ile)
- AI rate limit aşılınca → 429 + QUOTA_EXCEEDED → QuotaBanner + "PRO'ya geç"
- GET /ai/jobs/{id} → status + result (IDOR korumalı)

# Egzersiz / Kas Grubu
- BodyMapWidget KALDIRILDI
- body_map_widget.dart + muscle__front_and_back.svg SİLİNMELİ
- extractMuscleGroups() → egzersiz_screen.dart'ta tanımlı

# Build
- Kaynak: C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\mobile\
- Build: C:\TrackForge\ (Türkçe karakter sorunu)
- Android SDK: C:\Android\
- Pub cache: C:\pub-cache\
- Java: JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
- Git: PowerShell'de && çalışmaz, komutları ayrı çalıştır
- Windows Defender exclusion: C:\Android, C:\TrackForge

# Alembic
- .env backend/ klasöründe
- Root'tan çalıştır: alembic -c backend/alembic.ini <komut>
- Tek migration head: 0001_baseline.py
- Render start command: alembic upgrade head (tekil)
- Yeni özellik → baseline üstüne zincirle

# CI Flake8
flake8 backend/app/ --max-line-length=500
  --extend-ignore=W292,W291,W391,E302,E303,E305,E261,E262,E265,E231,F401,E741,F821,E501

# Render Start Command
cd backend && PYTHONPATH=/opt/render/project/src alembic upgrade head && cd ..
&& uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT

# State Management
- ThemeModeNotifier / StateNotifierProvider → dark mode
- _genderProvider → regl ekranı kontrolü
- AI diyet → shared_prefs (user_id bazlı)
- RateLimiter → sadece UX (shared_prefs, user_id bazlı)
- Logout → clearUserLimits() + diyet cache temizleme
```

---

## 21. Build Ortamı Durumu

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
| 1 | Auth Sistemi | ✅ |
| 2 | Core CRUD | ✅ |
| 3 | Dosya İşlemleri | ✅ |
| 4 | Egzersiz Takibi | ✅ |
| 5 | Su, Uyku, Tercihler, Alışveriş | ✅ |
| 6 | Raporlar | ✅ |
| 7 | Polish & CI/CD | ✅ |
| 8 | AI Entegrasyonu | ✅ |
| 9 | Onboarding, Barkod, Gamification, Sosyal, Steps, Cycle | ✅ |
| 10 | Flutter — Tüm ekranlar | ✅ |
| 11 | Polish, UI/UX, Icon, Splash, Play Store | ✅ |
| 12 | Bug Fix Round 1 + UI/UX Revize + Yeni Özellikler | ✅ |
| 13 | Bug Fix Round 2 + Kas Grubu Grafiği + Gamification Revize | ✅ |
| 14 | AI v2 — context_builder, kota, job pattern, cache, feedback | ✅ |
| 15 | Prod Deploy — baseline migration, 26 tablo, 119 route, 37 ekran | ✅ |
| 16 | V1.1 — RevenueCat, FCM, Health Connect, Apple Developer | ⏳ Operasyon bağımlı |

---

## 23. Açık Sorunlar

### 🔴 Kritik
- **body_map_widget.dart + muscle__front_and_back.svg silinmeli** — derleme hatası verir
- **Splash ekranı çalışmıyor** — styles.xml bağlantısı kopuk

### 🟡 Önemli
- **Premium hesap client-side limitöre takılıyor** — isPremium() /auth/me'den okumalı
- **Egzersiz 2 kere ekleniyor** — duplicate insert var
- **Profil — hedef değiştirilemiyor** — fitness_goal PUT çalışmıyor
- **Profil — AI ismi güncellenmiyor** — ai_name PUT sonrası yansımıyor
- **Onboarding başlangıç kilosu dashboard'a aktarılmıyor**
- **Çapraz hesap veri sorunu** — uyku/kalori/egzersiz verileri hesaplar arası sızıyor

### 🟠 UI/UX
- **Kalori bankası telafi scroll yok**
- **Kalori bankası UI renksiz** — detailed_advice düz metin
- **Antrenman planı — egzersiz ekle butonu kaldırılacak**
- **Egzersiz kas grubu grafiği** — seans detayında çıkmıyor
- **Dashboard — serilere tümüne bas** → gamification'a yönlendirmiyor
- **Ölçüm tabı — yağ oranı tekrar hesaplama** çalışmıyor
- **Ölçüm tabı — boy profilden gelmiyor**

### ⏳ Bekleyen
- Bildirim ikonu kalıcı fix (drawable vector XML)
- Play Store — App icon (512x512), Feature graphic, screenshots, İngilizce listing, content rating

---

## 24. Play Store Durumu

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

**Apple Developer:** Support'a mail atıldı (kimlik doğrulama sorunu).

---

## 25. V1.1 Planı — Operasyon Bağımlı

| Özellik | Bağımlılık |
|---|---|
| RevenueCat — abonelik + AI hakkı satın alma | Ekranlar hazır, satın alma bağlanacak |
| FCM — proaktif bildirimler (plato, sessizlik tetikleyicileri) | FCM kurulumu |
| Health Connect — giyilebilir / toparlanma skoru | Health Connect API |
| `/billing/add-credits` — consumable satın alımda kotaya ek hak | RevenueCat sonrası |
| Çoklu dil — TR + EN (flutter_localizations + intl) | — |
| Regl fazı AI entegrasyonu derinleştirme | context_builder üzerinden zaten var |
| Antrenman planı kas grubu tekrar önleme | workout_generator revize modu |
| Apple Developer hesabı | Kimlik doğrulama sorunu çözülünce |

---

## 26. Canlı URL'ler

| Servis | URL |
|---|---|
| Backend | https://trackforge-3o2j.onrender.com |
| Landing page | https://trackforge-3o2j.onrender.com/ |
| Privacy policy | https://trackforge-3o2j.onrender.com/static/privacy-policy.html |
| API Docs | https://trackforge-3o2j.onrender.com/docs |

---

## 27. Önemli Dosya Yolları

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
*Son güncelleme: 15 Haziran 2026 — v8.0*
*Prod canlı · 26 tablo · 119 route · 37 mobil ekran · tek migration head*
*Sonraki: Açık sorunlar → APK test → Play Store submit → V1.1*