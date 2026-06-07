# TrackForge — Mimari Tasarım Dokümanı

**Versiyon:** v7.1 — Tam Güncel
**Tarih:** Haziran 2026
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
┌─────────────────────────────────────────┐
│           PRESENTATION LAYER            │  ← HTTP, routing, validation
│         api/v1/endpoints/               │
├─────────────────────────────────────────┤
│           APPLICATION LAYER             │  ← Use cases, iş mantığı
│              services/                  │
├─────────────────────────────────────────┤
│             DOMAIN LAYER                │  ← Entity'ler, saf Python
│           domain/entities/              │
│           domain/interfaces/            │
├─────────────────────────────────────────┤
│         INFRASTRUCTURE LAYER            │  ← DB, dosya, dış servisler
│   repositories/ + storage/ + logging/   │
├─────────────────────────────────────────┤
│              AI LAYER                   │  ← Pluggable analiz modülü
│               ai/                       │
└─────────────────────────────────────────┘
Bağımlılık kuralı: Oklar sadece içe doğru akar.
Domain hiçbir şeye bağımlı değil.
```

---

## 5. Backend Klasör Yapısı

```
backend/
├── .env                           # ✅ backend klasörüne taşındı (v7.1)
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
│   │       ├── ai.py              # ✅ calorie-bank-advice endpoint eklendi
│   │       ├── onboarding.py
│   │       ├── barcode.py
│   │       ├── gamification.py
│   │       ├── social.py
│   │       ├── steps.py
│   │       └── cycle.py
│   ├── domain/
│   │   ├── entities/
│   │   └── interfaces/
│   ├── application/
│   │   ├── services/
│   │   │   ├── meal_compliance_service.py  # ✅ complied otomatik + egzersiz kalorisi
│   │   │   └── onboarding_service.py       # ✅ preferences senkronizasyonu
│   │   └── schemas/
│   │       └── meal_compliance.py          # ✅ complied field kaldırıldı
│   ├── infrastructure/
│   │   ├── db/
│   │   │   ├── base.py
│   │   │   ├── session.py
│   │   │   └── models/
│   │   │       ├── user_preference_model.py   # ✅ diet_preference, ai_name, target_weight_kg, daily_calorie_habit eklendi
│   │   │       └── onboarding_profile_model.py # ✅ target_weight_kg, daily_calorie_habit eklendi
│   │   ├── repositories/
│   │   ├── storage/
│   │   └── logging/
│   ├── ai/
│   │   ├── client.py              # claude-sonnet-4-5
│   │   ├── analyzers/
│   │   │   ├── weekly_analyzer.py
│   │   │   └── calorie_vision_analyzer.py
│   │   └── generators/
│   │       ├── workout_generator.py   # fitness_goal profilden otomatik
│   │       ├── meal_advisor.py        # fitness_goal profilden otomatik
│   │       ├── recipe_generator.py
│   │       └── calorie_bank_advisor.py  # ✅ entegre edildi (v7.1)
│   ├── middleware/
│   └── core/
│       ├── config.py              # ANTHROPIC_API_KEY (CLAUDE_API_KEY → rename ✅)
│       ├── security.py
│       ├── dependencies.py
│       └── exceptions.py
├── migrations/
│   └── versions/
│       ├── e6c55c10c52b_add_target_weight_calorie_habit_burned.py  # ✅
│       └── 5d79c5ec0994_add_user_pref_new_fields.py                # ✅
├── static/
│   ├── index.html
│   └── privacy-policy.html
└── tests/
```

---

## 6. Veritabanı Şeması — 17 Tablo

```sql
users
body_measurements
weekly_notes
meal_compliance        # ✅ complied otomatik hesaplama, egzersiz kalorisi dahil (v7.1)
file_uploads
exercise_sessions
session_exercises
water_logs
sleep_logs
user_preferences       # ✅ diet_preference, ai_name, target_weight_kg, daily_calorie_habit eklendi (v7.1)
shopping_items
onboarding_profile     # ✅ target_weight_kg, daily_calorie_habit eklendi (v7.1)
streaks                ✅
badges                 ✅
user_levels            ✅
friendships            ✅
step_logs              ✅
menstrual_cycles       ✅
```

---

## 7. API Endpoint Yapısı

```
BASE: /api/v1

── AUTH ──
POST   /auth/register
POST   /auth/login
POST   /auth/refresh
GET    /auth/me

── ONBOARDING ──
POST/GET/PUT  /onboarding
POST          /onboarding/complete   # ✅ target_weight_kg + daily_calorie_habit gönderir (v7.1)

── MEASUREMENTS ──
POST/GET/PUT/DELETE  /measurements

── MEAL COMPLIANCE ──
POST/GET/PUT/DELETE  /meal-compliance   # ✅ complied field kaldırıldı, otomatik hesaplanıyor (v7.1)
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
POST   /ai/weekly-summary
POST   /ai/workout-plan              # fitness_goal profilden otomatik okunuyor (v7.1)
POST   /ai/meal-advice               # fitness_goal profilden otomatik okunuyor (v7.1)
POST   /ai/recipe
POST   /ai/calorie-from-photo        # multipart/form-data, field: "file"
POST   /ai/calorie-bank-advice       # ✅ YENİ — kalori bankası AI analizi (v7.1)
POST   /ai/cycle-advice

── SOCIAL ──
POST   /social/friends/request
POST   /social/friends/accept/{id}
DELETE /social/friends/{id}
GET    /social/friends
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
GET    /                                      # Landing page
GET    /static/privacy-policy.html
GET    /health
GET    /docs
```

---

## 8. Flutter Uygulama Mimarisi

```
mobile/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   ├── endpoints.dart         # ✅ aiCalorieBankAdvice eklendi (v7.1)
│   │   │   └── api_exceptions.dart
│   │   ├── auth/
│   │   │   └── token_manager.dart     # ✅ user_id kaydet/oku/temizle (v7.1)
│   │   ├── theme/
│   │   ├── notifications/
│   │   │   └── notification_service.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       └── rate_limiter.dart      # ✅ user_id bazlı key'ler (v7.1)
│   └── screens/
│       ├── auth/
│       ├── onboarding/
│       │   └── onboarding_screen.dart # ✅ hedef kilo + kalori alışkanlığı adımı eklendi (v7.1)
│       ├── home/
│       │   └── dashboard_screen.dart  # ✅ AI Kalori Analizi butonu + BankAdviceSheet (v7.1)
│       ├── takip/
│       │   ├── olcum_tab.dart         # ✅ Navy Method yağ oranı hesaplama (v7.1)
│       │   ├── diyet_tab.dart         # ✅ complied switch kaldırıldı, backend'den okunuyor (v7.1)
│       │   ├── su_tab.dart
│       │   └── uyku_tab.dart
│       ├── egzersiz/
│       ├── ai/
│       │   ├── ai_screen.dart         # ✅ "Claude API" chip kaldırıldı (v7.1)
│       │   ├── meal_advice_screen.dart # ✅ amaç sorusu kaldırıldı, profil hedefi (v7.1)
│       │   ├── workout_plan_screen.dart # ✅ amaç sorusu kaldırıldı (v7.1)
│       │   ├── recipe_screen.dart
│       │   ├── calorie_vision_screen.dart # ✅ kalori onay butonu (v7.1)
│       │   ├── weekly_summary_screen.dart
│       │   ├── ai_helpers.dart
│       │   └── cycle_advice_screen.dart
│       ├── raporlar/
│       ├── gamification/
│       ├── sosyal/
│       ├── profil/
│       ├── more/
│       ├── steps/
│       └── alisveris/
├── assets/
│   └── images/
│       ├── app_icon.png
│       └── muscle__front_and_back.svg  # çift alt çizgi!
└── android/
    ├── app/src/main/res/
    │   ├── drawable*/ic_notification.png  # ✅ tüm DPI klasörleri (v7.1)
    └── trackforge-release.jks
```

---

## 9. Shared_prefs Veri Yapısı

```dart
// ── Auth & User ─────────────────────────────────────
'access_token'
'refresh_token'
'current_user_id'           # ✅ eklendi (v7.1)

// ── Tema ────────────────────────────────────────────
'theme_mode'

// ── AI Diyet Planı (user_id bazlı) ──────────────────
'last_meal_advice_{userId}'           # ✅ izolasyon düzeltildi (v7.1)
'last_meal_advice_date_{userId}'      # ✅
'last_recommended_foods_{userId}'     # ✅
'last_foods_to_avoid_{userId}'        # ✅
'last_weekly_meal_plan_{userId}'      # ✅

// ── AI Rate Limiter (user_id bazlı) ─────────────────
'vision_count_{userId}_{Y}_{M}_{D}'        # ✅ izolasyon düzeltildi (v7.1)
'weekly_analysis_{userId}_{Y}_w{N}'        # ✅
'meal_advice_{userId}_{Y}_w{N}'            # ✅
'workout_plan_{userId}_{Y}_w{N}'           # ✅

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
'in_app_notifications'      // title||body||time formatı
'notif_seeded_{Y}_{M}_{D}'
```

---

## 10. AI Rate Limiter Sistemi

```dart
// core/utils/rate_limiter.dart
// Limitler:
//   Vision kalori    → günde 3
//   Haftalık analiz  → haftada 1
//   Diyet tavsiyesi  → haftada 1
//   Antrenman planı  → haftada 1

// ✅ v7.1: user_id bazlı key'ler — hesap değişince limit izole
// 'vision_count_{userId}_{Y}_{M}_{D}'
// clearUserLimits() → logout'ta çağrılıyor
```

---

## 11. Kalori Bankası Sistemi

```
TDEE = BMR × aktivite_katsayısı
BMR  = Mifflin-St Jeor formülü

Kilo verme : günlük_hedef = TDEE - 500   # ✅ -700'den -500'e güncellendi (v7.1)
Kas yapma  : günlük_hedef = TDEE + 250
Koruma     : günlük_hedef = TDEE

calorie_balance     = (calories_consumed - calories_burned) - calories_target
weekly_bank_balance = son 7 günün (target - net_consumed) toplamı
Minimum kalori      : 1500 kcal

today_max_calories  = daily_target + max(weekly_bank, 0)
bank_message        = backend üretir

# ✅ v7.1: complied artık otomatik hesaplanıyor
# Net tüketim (yenen - yakılan) / hedef → %80-120 arası = uyuldu
# Kullanıcı switch'e dokunmuyor

# ✅ v7.1: Egzersiz kalorisi bankaya dahil
# calories_burned o günkü egzersiz seanslarından toplanıyor

# ✅ v7.1: calorie_bank_advisor.py entegre edildi
# POST /ai/calorie-bank-advice → dashboard'dan "AI Kalori Analizi Al" butonu
# Dönen alanlar: short_message, detailed_advice, tomorrow_suggestion, telafi_options
```

---

## 12. AI Diyet Planı Sistemi

```
meal_advisor.py → 7 günlük haftalık plan döner
fitness_goal → artık UI'dan seçilmiyor, profilden otomatik okunuyor ✅ (v7.1)

  weekly_plan: {
    pazartesi: { breakfast, lunch, dinner, snack }
    ...
    pazar: { ... }
  }
  meal_suggestions: bugünün günü (otomatik set edilir)

Flutter storage (user_id bazlı ✅):
  last_meal_advice_{userId}
  last_meal_advice_date_{userId}
  last_recommended_foods_{userId}
  last_foods_to_avoid_{userId}
  last_weekly_meal_plan_{userId}

diyet_tab.dart:
  → Bugünün menüsü gösterilir
  → complied switch kaldırıldı, backend otomatik hesaplıyor ✅ (v7.1)
  → Logout'ta user_id bazlı temizleniyor ✅ (v7.1)

MAX_TOKENS_MEAL = 3000
```

---

## 13. Onboarding Akışı

```
v7.1'de güncellendi ✅

Adım 1: Hedefler (goals listesi, max 3 seçim)
Adım 2: Temel Bilgiler (boy, kilo, yaş, cinsiyet, hedef kilo — opsiyonel)
Adım 3: Aktivite seviyesi
Adım 4: Diyet tercihi
Adım 5: Kalori alışkanlığı (under_1500 / 1500_2000 / 2000_2500 / 2500_3000 / over_3000)
Adım 6: AI Koç ismi

_complete() → onboarding/complete endpoint'ine gönderir:
  goals, diet_preference, target_weight_kg, daily_calorie_habit

Senkronizasyon (onboarding_service.py):
  goals[0] → fitness_goal map → user_preferences.fitness_goal
  diet_preference → user_preferences.diet_preference + disliked_foods/allergies güncelleme
  target_weight_kg → user_preferences.target_weight_kg
  daily_calorie_habit → user_preferences.daily_calorie_habit
```

---

## 14. Navy Method Yağ Oranı Hesaplama

```
✅ v7.1'de eklendi — olcum_tab.dart

Erkek:
  %BF = 495 / (1.0324 - 0.19077 × log10(bel - boyun) + 0.15456 × log10(boy)) - 450

Kadın:
  %BF = 495 / (1.29579 - 0.35004 × log10(bel + kalça - boyun) + 0.22100 × log10(boy)) - 450

UI: Vücut yağı alanının yanında "?" butonu → bottom sheet açılır
Sonuç → "Bu değeri kullan" butonu → body_fat_pct alanına otomatik dolar
```

---

## 15. Regl Takvimi Sistemi

```
Faz 1 — Menstrüasyon (Gün 1–5)   → Hafif antrenman
Faz 2 — Foliküler (Gün 6–13)     → Orta yoğun
Faz 3 — Ovülasyon (Gün 14–16)    → Zirve performans
Faz 4 — Luteal (Gün 17–28)       → Yoğunluk azalt

Görünürlük: gender == 'female' → _genderProvider
```

---

## 16. Gamification Sistemi

| Seviye | Başlık | XP |
|---|---|---|
| 1 | Beginner | 0 |
| 2 | Active | 500 |
| 3 | Fit | 1500 |
| 4 | Athlete | 3000 |
| 5 | Champion | 6000 |

**XP Kaynakları:** Antrenman +50 · Su hedefi +20 · Uyku +15 · Rozet +100 · Haftalık rapor +10

---

## 17. Monetizasyon Planı (V1.1)

| Paket | Fiyat | Özellikler |
|---|---|---|
| **Free** | Ücretsiz | Haftalık AI analizi 1x, Diyet tavsiyesi 1x/hafta, Antrenman planı 1x/hafta, Vision 3x/gün, Temel takip sınırsız |
| **PRO** | 149 TL/ay | Haftalık analiz sınırsız, Diyet günlük dinamik, Antrenman 2x/hafta, Vision 10x/gün, Aylık detaylı rapor |
| **PRO+** | 299 TL/ay | Her şey sınırsız, Regl AI entegrasyonu, Kan değerleri analizi, Öncelikli destek |

**Teknoloji:** RevenueCat + Google Play Billing (V1.1)

---

## 18. Tema Sistemi

```dart
// Dark Mode
bg: '#0C0D10'
bgCard: '#141620'
accent: '#FFB020'
positive: '#34D399'
danger: '#FF5555'

// Light Mode
bg: '#F0F2F6'
bgCard: '#FFFFFF'
accent: '#FF6B2B'
positive: '#059669'
danger: '#DC2626'
```

---

## 19. Kritik Teknik Notlar

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
- POST /shopping → quantity: STRING
- GET /reports/* → nested objeler
- POST /ai/meal-advice → haftalık plan + bugünün meal_suggestions döner
- POST /ai/calorie-bank-advice → short_message, detailed_advice, tomorrow_suggestion, telafi_options
- activity_level → _safeActivityLevel() ile handle et
- complied → artık POST/PUT body'sine gönderilmiyor, backend otomatik hesaplıyor ✅

# Build
- Kaynak: C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\mobile\
- Build: C:\TrackForge\ (Türkçe karakter sorunu)
- Pub cache: C:\pub-cache\
- Java: JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
- Git: PowerShell'de && çalışmaz, komutları ayrı çalıştır
- SVG dosya adı: muscle__front_and_back.svg (çift alt çizgi!)
- Bildirim ikonu: android/app/src/main/res/drawable*/ic_notification.png

# Alembic (v7.1)
- .env backend/ klasöründe
- Koşturma: cd backend → $env:PYTHONPATH=... → $env:DATABASE_URL=... → alembic ...
- Render external DB URL kullanılır (asyncpg değil, psycopg2)
- ai_name sütunu yanlışlıkla silindi → migration düzeltildi ✅

# State Management
- ThemeModeNotifier / StateNotifierProvider → dark mode
- SharedPreferences → dark mode persist
- _genderProvider → regl ekranı kontrolü
- AI diyet → shared_prefs (user_id bazlı ✅)
- RateLimiter → shared_prefs (user_id bazlı ✅)
- Logout → clearUserLimits() + diyet cache temizleme ✅
```

---

## 20. Geliştirme Fazları

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
| 12 | Bug Fix Round 1 + UI/UX Revize + Yeni Özellikler | ✅ Tamamlandı — Test Bekliyor |

---

## 21. Bug Fix Round 1 — v7.1 Özeti

### ✅ Düzeltildi (Test Bekliyor)

**Kritik:**
- AI limit → user_id bazlı key'ler ✅
- Shared_prefs izolasyonu → logout'ta temizleme ✅
- Uyku güncelleme → _initialized sıfırlama fix ✅
- Ölçüm güncelleme → POST yerine PUT ✅
- Profil yaş + AI koç ismi → _prefsLoaded fix ✅
- Alışveriş checkbox → PATCH endpoint ✅
- Seans filtresi → 30 → 90 gün ✅

**UI/UX:**
- Vision makro format → protein_g → Protein g ✅
- AI ekranı chip → "Claude API" kaldırıldı ✅
- Vision alt yazısı güncellendi ✅
- Tarif sol + butonu ✅
- Diyet uyumu grafiği key fix ✅
- Bildirim ikonu DPI fix ✅
- Adım sayar threshold ✅

**Yeni Özellikler:**
- Vision → kalori onay sorusu ✅
- Bildirim çanı tüm ekranlara ✅
- complied otomatik hesaplama ✅
- Egzersiz kalorisi bankaya dahil ✅
- calorie_bank_advisor entegre ✅
- Onboarding hedef kilo + kalori alışkanlığı ✅
- Diyet/Antrenman amaç sorusu kaldırıldı ✅
- Navy Method yağ oranı ✅

### ⏳ Test Edilecekler
- APK build + telefon testi (tüm değişiklikler)
- AI ekranı hero card "coach" yazısı kontrolü
- calorie_bank_advisor response formatı Flutter uyumu
- Onboarding → preferences senkronizasyon (yeni kayıt)

---

## 22. Play Store Durumu

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
| Üretim sürümü | ⏳ Bug fix testi sonrası |

**Apple Developer:** Support'a mail atıldı (kimlik doğrulama sorunu).

---

## 23. V1.1 Planı

- FCM — arkadaş isteği bildirimi + kabul/red push
- Abonelik sistemi (RevenueCat — Free/PRO/PRO+)
- Antrenman planı kas grubu tekrar önleme
- AI rate limit backend kontrolü
- Apple Developer hesabı (kimlik doğrulama çözülünce)

---

## 24. Canlı URL'ler

| Servis | URL |
|---|---|
| Backend | https://trackforge-3o2j.onrender.com |
| Landing page | https://trackforge-3o2j.onrender.com/ |
| Privacy policy | https://trackforge-3o2j.onrender.com/static/privacy-policy.html |
| API Docs | https://trackforge-3o2j.onrender.com/docs |

---

## 25. Önemli Dosya Yolları

| Dosya | Yol |
|---|---|
| Kaynak (mobile) | C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\mobile\ |
| Build klasörü | C:\TrackForge\ |
| Release APK | C:\TrackForge\build\app\outputs\flutter-apk\app-release.apk |
| Release AAB | C:\TrackForge\build\app\outputs\bundle\release\app-release.aab |
| Keystore | C:\TrackForge\android\app\trackforge-release.jks |
| Keystore yedek | Masaüstü → ÖNEMLİ (TRACKFORGE) klasörü |
| key.properties | C:\TrackForge\android\key.properties |
| .env | C:\Users\Memet Saçal\Desktop\PyCharmProject\TrackForge\backend\.env |

---

*Bu doküman projenin yaşayan anayasası.*
*Son güncelleme: 7 Haziran 2026 — v7.1*
*Backend: Faz 1–9 tamamlandı · Flutter: Faz 10–12 tamamlandı · Sonraki: APK test → Play Store submit*