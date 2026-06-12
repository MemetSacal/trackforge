# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v7.4 — Tam Güncel
**Tarih:** 10 Haziran 2026
**Mimari:** Clean Architecture + Repository Pattern
**Yaklaşım:** Backend-First, AI-Ready, Mobile-First

---

## 1. Proje Kimliği

| Alan | Detay |
|---|---|
| **Ad** | TrackForge — AI-Powered Personal Health & Fitness System |
| **Amaç** | Diyet, ölçüm, egzersiz, uyku, su takibi; AI destekli kişiselleştirilmiş sağlık, beslenme ve antrenman tavsiyesi sunan platform |
| **Mimari** | Clean Architecture + Repository Pattern |
| **AI** | Claude API entegre (claude-sonnet-4-5) |
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
| AI | Claude API (Anthropic) | claude-sonnet-4-5 | Haftalık özet, tavsiye, vision |
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

---

## 5. Backend Klasör Yapısı

```
backend/
├── .env
├── app/
│   ├── main.py
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
│   │       └── cycle.py
│   ├── domain/
│   │   ├── entities/              # 17 entity
│   │   │   ├── user.py            # is_premium: bool = False
│   │   │   └── user_preference.py # diet_preference, ai_name, target_weight_kg, daily_calorie_habit
│   │   └── interfaces/            # 16 interface
│   ├── application/
│   │   ├── services/              # 15 service
│   │   └── schemas/               # 17 schema (PendingRequestResponse eklendi)
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── models/            # 18 model (ai_usage_model eklendi)
│   │   ├── repositories/          # 15 repository
│   │   ├── storage/
│   │   └── logging/
│   ├── ai/
│   │   ├── client.py              # claude-sonnet-4-5
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py
│   │   │   └── calorie_vision_analyzer.py
│   │   └── generators/
│   │       ├── workout_generator.py
│   │       ├── meal_advisor.py
│   │       ├── recipe_generator.py
│   │       └── calorie_bank_advisor.py
│   ├── middleware/
│   └── core/
│       ├── config.py
│       ├── security.py
│       ├── dependencies.py        # get_current_user_premium eklendi
│       ├── ai_rate_limiter.py     # backend rate limit enforcement
│       └── exceptions.py
├── migrations/
│   └── versions/                  # 22 migration
└── static/
    ├── index.html
    └── privacy-policy.html
```

---

## 6. Veritabanı Şeması — 18 Tablo

```sql
users                  # is_premium boolean
body_measurements      # kilo, yağ, kas, bel, göğüs, kalça, kol, bacak
weekly_notes           # haftalık notlar, enerji, ruh hali
meal_compliance        # kalori bankası dahil, complied otomatik hesaplanıyor
file_uploads           # fotoğraf ve dosyalar
exercise_sessions      # antrenman seansları
session_exercises      # seans içi egzersizler (JSON muscle_groups)
water_logs             # su tüketimi
sleep_logs             # uyku (süre, kalite, yatış/kalkış saati)
user_preferences       # boy, yaş, cinsiyet, hedef, ai_name, kan değerleri,
                       # diet_preference, target_weight_kg, daily_calorie_habit
shopping_items         # alışveriş listesi (quantity: STRING)
onboarding_profile     # hedefler, diyet tercihi, target_weight_kg, daily_calorie_habit
streaks                # water / exercise / sleep streak takibi
badges                 # kazanılan rozetler
user_levels            # XP sistemi
friendships            # arkadaşlık istekleri ve durumu (pending/accepted)
step_logs              # günlük adım sayısı (pedometer)
menstrual_cycles       # adet döngüsü takibi
ai_usage_logs          # AI rate limit kayıtları (feature, used_at, user_id)
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

## 8. API Endpoint Yapısı

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

── AI ──
POST   /ai/weekly-summary        # Free: 1/hafta  | Premium: sınırsız
POST   /ai/workout-plan          # Free: 2/hafta  | Premium: sınırsız
POST   /ai/meal-advice           # Free: 2/hafta  | Premium: sınırsız
POST   /ai/recipe                # limit yok
POST   /ai/calorie-from-photo    # Free: 3/gün    | Premium: sınırsız
POST   /ai/calorie-bank-advice   # limit yok
POST   /ai/cycle-advice          # limit yok

── SOCIAL ──
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends            # accepted arkadaşlar
GET    /social/friends/pending    # gelen bekleyen istekler (requester_name dahil)
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

## 9. Flutter Uygulama Mimarisi

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── endpoints.dart
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   └── token_manager.dart
│   │   ├── theme/
│   │   ├── notifications/
│   │   │   └── notification_service.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── rate_limiter.dart          # user_id bazlı key'ler, client-side
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart
│       ├── onboarding/
│       │   └── onboarding_screen.dart     # 6 adım + validasyon
│       ├── home/
│       │   └── dashboard_screen.dart
│       ├── takip/
│       │   ├── olcum_tab.dart
│       │   ├── diyet_tab.dart             # 7 günlük haftalık plan
│       │   ├── su_tab.dart
│       │   └── uyku_tab.dart
│       ├── egzersiz/
│       │   ├── egzersiz_screen.dart
│       │   └── seans_detay_screen.dart
│       ├── ai/
│       │   ├── ai_screen.dart
│       │   ├── ai_helpers.dart
│       │   ├── meal_advice_screen.dart
│       │   ├── workout_plan_screen.dart
│       │   ├── recipe_screen.dart
│       │   ├── calorie_vision_screen.dart
│       │   ├── weekly_summary_screen.dart
│       │   └── cycle_advice_screen.dart
│       ├── raporlar/
│       ├── gamification/
│       ├── sosyal/
│       │   └── sosyal_screen.dart         # pending requests UI eklendi
│       ├── profil/
│       ├── more/
│       ├── steps/
│       └── alisveris/
├── assets/
│   └── images/
│       ├── app_icon.png
│       └── splash_bg.png
│       # ❌ muscle__front_and_back.svg SİLİNMELİ
│       # ❌ body_map_widget.dart SİLİNMELİ
└── android/
    └── trackforge-release.jks
```

---

## 10. Flutter Ekran Durumu

| Ekran | Durum | Notlar |
|---|---|---|
| Login / Register | ✅ | JWT flow, beni hatırla |
| Onboarding | ✅ | 6 adım, backend entegre |
| Dashboard | ✅ | Gamification + AI koç kartı |
| Takip — Ölçüm | ⚠️ | Yağ oranı tekrar hesaplama yok, boy profilden gelmiyor |
| Takip — Diyet | ✅ | 7 günlük haftalık plan |
| Takip — Su | ✅ | Hızlı ekle, progress bar |
| Takip — Uyku | ✅ | TimePicker, kalite slider |
| Egzersiz | ⚠️ | Egzersiz 2 kere ekleniyor, AI planı seansa aktarılmıyor, kas grafiği yok |
| AI — Haftalık Özet | ✅ | Markdown render |
| AI — Antrenman Planı | ⚠️ | Egzersiz ekle butonu kaldırılacak, kas grafiği yok |
| AI — Diyet Tavsiyesi | ✅ | shared_prefs cache |
| AI — Tarif Önerisi | ⚠️ | Ara sıra hata veriyor |
| AI — Vision Kalori | ✅ | multipart, manuel token |
| AI — Kalori Bankası | ⚠️ | Telafi seçenekleri sonrası scroll yok, UI renksiz |
| AI — Regl Tavsiyesi | ✅ | cycle_advice_screen |
| Raporlar | ✅ | fl_chart, haftalık+aylık |
| Gamification | ✅ | XP, seviye, streak, rozetler |
| Sosyal | ✅ | Arkadaşlar + pending istekler + liderboard |
| Alışveriş | ✅ | Liste + barkod |
| Adım Sayar | ⚠️ | Pedometer kapalı gözüküyor |
| Profil | ⚠️ | Hedef değiştirilemiyor, AI ismi güncelleme çalışmıyor |
| More | ✅ | Menü kartları |
| Regl Takvimi | ✅ | Sadece gender == female |

---

## 11. Shared_prefs Veri Yapısı

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

// ── AI Rate Limiter (user_id bazlı) — client-side ───
'vision_count_{userId}_{Y}_{M}_{D}'
'weekly_analysis_{userId}_{Y}_w{N}'
'meal_advice_{userId}_{Y}_w{N}'
'workout_plan_{userId}_{Y}_w{N}'

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

## 12. AI Rate Limiter Sistemi

```
── CLIENT SIDE (rate_limiter.dart) ──────────────────────
Limitler (Free tier):
  Vision kalori    → günde 3
  Haftalık analiz  → haftada 1
  Diyet tavsiyesi  → haftada 2
  Antrenman planı  → haftada 2

user_id bazlı key'ler — hesap değişince limit izole
clearUserLimits() → logout'ta çağrılıyor
isPremium() → true ise tüm limitler bypass

⚠️ AÇIK SORUN:
  - Premium hesap client-side limitöre takılıyor
    Çözüm: isPremium() DB'den değil /auth/me'den okumalı
  - Kullanıcı tavsiye alıp kaydetmeden çıkınca hak tükeniyor
    Çözüm: RateLimiter.recordMealAdviceUse() → _saveAdvice() içine taşı

── BACKEND SIDE (ai_rate_limiter.py) ────────────────────
ai_usage_logs tablosunda feature + used_at bazlı kayıt
is_premium = true → limit kontrolü bypass
429 döner → Flutter "PRO'ya geç" dialog gösterir
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
complied → backend otomatik hesaplıyor (net tüketim / hedef → %80-120 = uyuldu)
Egzersiz kalorisi bankaya dahil
POST /ai/calorie-bank-advice → short_message, detailed_advice, tomorrow_suggestion, telafi_options

⚠️ AÇIK SORUN:
  - Kalori bankası hedefi 0 görünüyor (ölçüm girilmeden önce TDEE hesaplanamıyor)
  - Diyet tavsiyesi (2500 kcal) ile kalori bankası (2000 kcal) önerileri çelişiyor
  - Telafi seçenekleri bölümünden sonra scroll çalışmıyor
```

---

## 14. AI Diyet Planı Sistemi

```
meal_advisor.py → 7 günlük haftalık plan döner
fitness_goal → profilden otomatik okunuyor

  weekly_plan: {
    pazartesi: { breakfast, lunch, dinner, snack }
    ...
    pazar: { ... }
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
  → complied switch kaldırıldı, backend otomatik hesaplıyor
  → Logout'ta user_id bazlı temizleniyor

MAX_TOKENS_MEAL = 3000

⚠️ AÇIK SORUN:
  - AI diyet planı sefer başı günlük oluşturuyor, haftalık değil
    Çözüm: meal_advisor.py'de weekly_plan zorunlu yapıldı, kontrol gerekiyor
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
  - Onboarding'de girilen başlangıç kilosu dashboard'a aktarılmıyor
  - Register → tercih listesi → uygulamadan çık → gir → hesap açılmış oluyor (normal)
```

---

## 16. Regl Takvimi Sistemi

```
Görünürlük: gender == 'female' → _genderProvider

Faz 1 — Menstrüasyon (Gün 1–5)   → Hafif antrenman, demir açısından zengin
Faz 2 — Foliküler (Gün 6–13)     → Orta yoğun, protein ağırlıklı
Faz 3 — Ovülasyon (Gün 14–16)    → Zirve performans, kalori artırılabilir
Faz 4 — Luteal (Gün 17–28)       → Yoğunluk azalt, magnezyum açısından zengin

AI Entegrasyonu (V1.1):
  → AI antrenman planı + tarif önerici + haftalık rapor
  → Faz bilgisi prompt'a eklenecek
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

## 18. Monetizasyon Planı (V1.1)

| Paket | Fiyat | Özellikler |
|---|---|---|
| **Free** | Ücretsiz | Haftalık AI analizi 1x, Diyet tavsiyesi 2x/hafta, Antrenman planı 2x/hafta, Vision 3x/gün |
| **PRO** | 149 TL/ay | Analiz sınırsız, Diyet günlük dinamik, Antrenman 2x/hafta, Vision 10x/gün |
| **PRO+** | 299 TL/ay | Her şey sınırsız, Regl AI, Kan değerleri, Öncelikli destek |

**Teknoloji:** RevenueCat + Google Play Billing (V1.1)
**Şu an:** is_premium DB'de manuel — memetsacal@icloud.com → true

---

## 19. AI Layer Detayı

```python
ai/
├── client.py                      # claude-sonnet-4-5
├── analyzers/
│   ├── weekly_analyzer.py
│   └── calorie_vision_analyzer.py # multipart → base64 → Claude Vision
└── generators/
    ├── workout_generator.py        # workout_location, fitness_goal,
    │                               # fitness_level, available_days
    ├── meal_advisor.py             # calorie_target → 7 günlük plan
    ├── recipe_generator.py         # kullanıcı ne istediğini söyler →
    │                               # diyet+kalori+alerji bazlı tarif →
    │                               # malzemeler alışveriş listesine
    └── calorie_bank_advisor.py     # haftalık banka durumu → öneri
```

---

## 20. Güvenlik

```
JWT Flow:
  1. POST /auth/login → access_token (30dk) + refresh_token (7gün)
  2. Her istekte: Authorization: Bearer <access_token>
  3. 401 → POST /auth/refresh (AuthInterceptor otomatik)

CORS: allow_origins=["*"], allow_credentials=False

Env Variables (Render):
  DATABASE_URL
  SECRET_KEY
  ANTHROPIC_API_KEY
  OPEN_FOOD_FACTS_BASE_URL
```

---

## 21. Kritik Teknik Notlar

```
# Flutter / Dio
- Web'de flutter_secure_storage çalışmaz → shared_prefs kullanıldı
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
- POST /ai/workout-plan → workout_location, fitness_goal, fitness_level, available_days
- POST /ai/meal-advice → haftalık plan + bugünün meal_suggestions döner
- POST /ai/calorie-bank-advice → short_message, detailed_advice, tomorrow_suggestion, telafi_options
- activity_level → _safeActivityLevel() ile handle et
- complied → artık POST/PUT body'sine gönderilmiyor, backend otomatik hesaplıyor
- GET /social/friends/pending → PendingRequestResponse (requester_name JOIN ile)
- AI rate limit aşılınca → 429 döner, Flutter "PRO'ya geç" gösterir

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
- env.py'de load_dotenv ile .env otomatik bulunuyor
- Render start command: alembic upgrade heads (plural — multiple heads)
- Multiple heads çıkarsa: alembic merge heads → upgrade heads → revision

# State Management
- ThemeModeNotifier / StateNotifierProvider → dark mode
- _genderProvider → regl ekranı kontrolü
- AI diyet → shared_prefs (user_id bazlı)
- RateLimiter → shared_prefs (user_id bazlı)
- Logout → clearUserLimits() + diyet cache temizleme
```

---

## 22. Build Ortamı Durumu

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

## 23. Geliştirme Fazları

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
| 14 | V1.1 Özellikler — Sosyal UI, Backend Rate Limit | ⏳ APK test bekliyor |

---

## 24. Açık Sorunlar

### 🔴 Kritik
- **body_map_widget.dart silinmeli** — artık kullanılmıyor, derleme hatası verir
- **Splash ekranı çalışmıyor** — flutter_native_splash drawable üretiyor ama göstermiyor

### 🟡 Önemli
- **Premium hesap client-side limitöre takılıyor** — isPremium() token'dan değil DB'den okumalı
- **Egzersiz 2 kere ekleniyor** — seans detay ekranında duplicate insert var
- **AI planından oluşturulan egzersiz seansa/kas grubuna aktarılmıyor**
- **Profil — hedef değiştirilemiyor** — fitness_goal PUT çalışmıyor
- **Profil — AI ismi güncellenmiyor** — ai_name PUT sonrası AI ekranına yansımıyor
- **Onboarding başlangıç kilosu dashboard'a aktarılmıyor**
- **Çapraz hesap uyku verisi** — varsayılan uyku değerleri diğer hesaba görünüyor
- **Çapraz hesap kalori verisi** — bir hesabın 280 kcal'i diğer hesapta görünüyor
- **Çapraz hesap egzersiz** — diğer hesabın egzersiz seansı silinemiyor (404)

### 🟠 UI/UX
- **Kalori bankası telafi scroll yok** — telafi seçenekleri sonrası sayfa kesilmiyor
- **Kalori bankası UI renksiz** — detailed_advice düz metin, badge/renk yok
- **Antrenman planı — egzersiz ekle butonu kaldırılacak** — AI zaten oluşturuyor
- **Egzersiz kas grubu grafiği** — seans detayında ve AI planında çıkmıyor
- **Dashboard — serilere tümüne bas** — gamification'a yönlendirmiyor
- **Ölçüm tabı — yağ oranı tekrar hesaplama** — değer değişince "Tekrar Hesapla" çıkmıyor
- **Ölçüm tabı — boy profilden gelmiyor**

### ⏳ Bekleyen
- Bildirim ikonu kalıcı fix (drawable vector XML)
- Play Store — App icon (512x512), Feature graphic, screenshots, İngilizce listing

---

## 25. Play Store Durumu

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

## 26. V1.1 Planı

- FCM — arkadaş isteği bildirimi + kabul/red push
- Abonelik sistemi (RevenueCat — Free/PRO/PRO+)
- Regl fazı AI entegrasyonu (diyet + antrenman + haftalık rapor)
- Çoklu dil desteği — TR + EN (flutter_localizations + intl)
- Antrenman planı kas grubu tekrar önleme
- Apple Developer hesabı

---

## 27. Canlı URL'ler

| Servis | URL |
|---|---|
| Backend | https://trackforge-3o2j.onrender.com |
| Landing page | https://trackforge-3o2j.onrender.com/ |
| Privacy policy | https://trackforge-3o2j.onrender.com/static/privacy-policy.html |
| API Docs | https://trackforge-3o2j.onrender.com/docs |

---

## 28. Önemli Dosya Yolları

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
*Son güncelleme: 10 Haziran 2026 — v7.4*
*Backend: Faz 1–9 tamamlandı · Flutter: Faz 10–14 devam ediyor*
*Sonraki: Açık sorunlar → APK test → Play Store submit*