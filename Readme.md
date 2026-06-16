<div align="center">

# 🏋️ TrackForge

### AI-Powered Personal Health & Fitness System

*Your personal AI coach that knows your data, understands your goals, and grows with you.*

[![Python](https://img.shields.io/badge/Python-3.14-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-green)](https://fastapi.tiangolo.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16+-blue)](https://www.postgresql.org/)
[![Flutter](https://img.shields.io/badge/Flutter-3.41.6-blue)](https://flutter.dev/)
[![Dio](https://img.shields.io/badge/Dio-HTTP_Client-orange)](https://pub.dev/packages/dio)
[![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-purple)](https://riverpod.dev/)
[![GitHub Actions](https://img.shields.io/badge/CI-GitHub_Actions-black)](https://github.com/features/actions)
[![Render](https://img.shields.io/badge/Hosting-Render-46E3B7)](https://render.com/)
[![JWT](https://img.shields.io/badge/Auth-JWT-red)](https://jwt.io/)
[![Claude](https://img.shields.io/badge/AI-Claude_API-orange)](https://www.anthropic.com/)
[![Open Food Facts](https://img.shields.io/badge/Food_API-Open_Food_Facts-green)](https://world.openfoodfacts.org/)

**[Live API](https://trackforge-3o2j.onrender.com/docs) · [Privacy Policy](https://trackforge-3o2j.onrender.com/static/privacy-policy.html) · [Author](https://github.com/MemetSacal)**

</div>

---

## 📌 Project Overview

**TrackForge** is a full-stack AI-powered personal health ecosystem that combines fitness tracking, nutrition planning, sleep and hydration monitoring, behavioral analytics, and adaptive AI coaching into a single mobile-first platform.

### The Problem It Solves

Most fitness apps treat AI as a chatbot bolted on top. TrackForge's AI operates from a **unified context layer** (`context_builder.py`) that feeds every AI module — workout planner, meal advisor, recipe generator, weekly analyzer — with the same real-time snapshot of the user: current weight, 7-day training completion, calorie bank balance, remaining macros for today, and menstrual cycle phase where applicable. All AI modules share one brain.

### Target Users

- Fitness enthusiasts tracking structured workout programs
- Individuals on calorie-managed diet plans
- Users who want data-driven, personalized health recommendations
- Health-conscious mobile users seeking one app for everything

### Core Use Cases

- Log workouts and get an AI-generated weekly training plan adapted to your history
- Track daily nutrition with calorie bank system — carry over deficit calories across the week
- Photograph a meal and get instant calorie + macro estimation (Claude Vision)
- Receive a weekly AI summary that reads your actual data, not a template
- Monitor menstrual cycle phases with phase-aware AI advice on training intensity and nutrition

---

## ✨ Features

### 🔐 Authentication
- JWT-based stateless authentication (access token 30 min, refresh token 7 days)
- Auto token refresh via Dio AuthInterceptor
- "Remember me" functionality
- Secure local token storage

### 🤖 AI Features
- **Weekly Summary** — AI analysis of actual weekly data (training, sleep, diet, steps)
- **Workout Plan Generator** — location-aware, goal-aware, history-aware plan with generate/revise modes
- **Meal Advice** — BMR/TDEE-based 7-day meal plan with per-day ingredient lists
- **Recipe Generator** — adapted to remaining macros and user preferences (not just available ingredients)
- **Calorie Vision** — photograph any meal → Claude Vision → instant calorie + macro breakdown → save as meal entry
- **Calorie Bank Advisor** — AI advice based on weekly calorie bank status
- **Cycle Advisor** — phase-aware training and nutrition recommendations for female users
- **Chat Assistant** — conversational Haiku-powered health coach (fast, low-cost, token-capped)
- **Unified AI Context** — all AI modules share user profile, recent measurements, training history, cycle phase, remaining macros
- **Async Job Pattern** — heavy AI tasks run in background; client polls via `GET /ai/jobs/{id}`
- **Response Cache** — SHA-256 input hashing; cache hits don't consume quota
- **Feedback System** — 👍/👎 rating per AI output

### 🥗 Nutrition & Diet
- **Calorie Bank System** — TDEE-based daily targets with weekly surplus/deficit carry-over
- **7-Day Meal Plan** — AI-generated with breakfast, lunch, dinner, snack per day
- **Meal Entry Hub** — single entry point: manual / barcode / photo (Vision)
- **Barcode Scanner** — Open Food Facts API integration
- **One-tap Shopping List** — export weekly meal plan ingredients to shopping list
- 3-state compliance: `compliant` (80–120% of target) / `deviated` / `no_data` (no penalty)

### 💪 Exercise
- Workout sessions with multiple exercises per session
- Per-exercise tracking: sets, reps, weight, muscle groups (JSON), completion state
- Exercise catalog for AI grounding
- Bar chart visualization of muscle group distribution
- AI-generated workout plan with one-tap session creation
- Free session flow (separate from AI plan — plan stays locked)

### 📊 Health Tracking
- **Body Measurements** — weight, body fat %, muscle mass, waist, chest, hip, arm, leg
- **Water Intake** — animated fill indicator and daily target tracking
- **Sleep Tracking** — bedtime, wake time, duration, quality score (1-10)
- **Step Counter** — pedometer integration with daily targets
- **Menstrual Cycle** — 4-phase detection with phase-aware AI advice (female users only)
- **Progress Photos** — upload and track visual progress over time
- **Blood Values** — manual entry for lab results
- **Weekly Check-in** — structured mood and energy logging

### 📈 Reports & Analytics
- Weekly and monthly reports with fl_chart visualizations
- Wrapped annual summary
- PDF report export
- Correlation insights across health data

### 🏆 Gamification
- XP system with 5 levels: Beginner → Active → Fit → Athlete → Champion
- Badge system (7 badges at launch) with automatic unlock triggers
- Streak tracking for water, exercise, and sleep
- Confetti celebration animations

### 👥 Social
- Friend system (request / accept / block)
- Friends-only leaderboard (weekly XP ranking)
- Duel system

### 🛒 Shopping
- Smart shopping list with categories, prices, and recurring items
- Barcode scanner integration
- Auto-populate from weekly meal plan

### 🔔 Notifications
- Local push notifications for water, workout, sleep, step, and streak reminders
- In-app notification center
- Per-category notification preferences

### 💎 Freemium (Free / PRO 149 TL/mo / PRO+ 299 TL/mo)
- Server-side quota enforcement via atomic PostgreSQL UPSERT
- Free: Weekly AI 1×, Meal 1×/week, Workout 1×/week, Vision 3×/day, Recipe 2×/week
- PRO: Workout 3×, Meal 3×, Vision 20×/day, Recipe 10×/week
- PRO+: Everything unlimited (7×/week), priority support
- RevenueCat + Google Play Billing integration (screens complete, purchase flow pending)

---

## 📱 Screenshots

### Dashboard
![Dashboard](docs/images/dashboard.png)

### AI Coach
![AI Coach](docs/images/ai_coach.png)

### Workout Plan
![Workout Plan](docs/images/workout_plan.png)

### Meal Advice
![Meal Advice](docs/images/meal_advice.png)

### Calorie Vision
![Calorie Vision](docs/images/calorie_vision.png)

### Weekly Summary
![Weekly Summary](docs/images/weekly_summary.png)

### Exercise Tracking
![Exercise](docs/images/exercise.png)

### Reports
![Reports](docs/images/reports.png)

### Gamification
![Gamification](docs/images/gamification.png)

### Onboarding
![Onboarding](docs/images/onboarding.png)

---

## 🧰 Tech Stack

| Category | Technologies |
|---|---|
| **Mobile** | Flutter 3.41.6, Riverpod 2.x, GoRouter 14.x, Dio, fl_chart, mobile_scanner |
| **Backend** | FastAPI 0.115+, Python 3.14, SQLAlchemy 2.0+ async, Pydantic v2 |
| **Database** | PostgreSQL 16+, Alembic (single baseline migration) |
| **AI** | Claude Sonnet 4.5 (production), Claude Haiku (chat assistant) |
| **Authentication** | JWT (python-jose), passlib/bcrypt, flutter_secure_storage |
| **Local Storage** | shared_preferences (user-scoped cache) |
| **Notifications** | flutter_local_notifications 18.0.1 |
| **External APIs** | Open Food Facts (barcode), Claude Vision (calorie from photo) |
| **Logging** | structlog (structured JSON) |
| **CI/CD** | GitHub Actions (flake8 lint) |
| **Hosting** | Render Starter ($7/mo, always-on) |
| **Monetization** | RevenueCat + Google Play Billing (integration pending) |

---

## 🏗️ Architecture

TrackForge follows **Clean Architecture + Repository Pattern** with a strict unidirectional dependency flow:

```
Entity → Interface → Model → Repository → Service → Schema → Endpoint
```

### Architecture Diagram

```mermaid
graph TD
    subgraph Flutter["Flutter App (iOS + Android)"]
        Screens --> Providers["Providers (Riverpod)"]
        Providers --> ApiClient["Dio ApiClient + AuthInterceptor"]
    end

    ApiClient -->|HTTPS / Bearer JWT| FastAPI

    subgraph Backend["FastAPI Backend (Render)"]
        FastAPI --> Router["/api/v1 Router"]
        Router --> Endpoints["Endpoints (Presentation)"]
        Endpoints --> Services["Services (Application)"]
        Services --> Repositories["Repositories (Infrastructure)"]
        Services --> AILayer["AI Layer"]
        Repositories --> DB[(PostgreSQL)]
    end

    subgraph AILayer["AI Layer"]
        ContextBuilder["context_builder.py ★"]
        ContextBuilder --> WorkoutGen["workout_generator"]
        ContextBuilder --> MealAdvisor["meal_advisor"]
        ContextBuilder --> WeeklyAnalyzer["weekly_analyzer"]
        ContextBuilder --> RecipeGen["recipe_generator"]
        ContextBuilder --> CycleAdvisor["cycle_advisor"]
        ChatAssistant["chat_assistant (Haiku)"]
        VisionAnalyzer["calorie_vision_analyzer"]
    end

    AILayer -->|claude-sonnet-4-5| Claude["Anthropic Claude API"]
    ChatAssistant -->|claude-haiku| Claude

    subgraph Quota["Quota & Cache"]
        QuotaService["QuotaService (atomic UPSERT)"]
        Cache["ai_response_cache (SHA-256)"]
        Jobs["ai_jobs (BackgroundTasks)"]
    end

    Endpoints --> Quota
```

### Clean Architecture Layers

| Layer | Location | Responsibility |
|---|---|---|
| **Presentation** | `api/v1/endpoints/` | HTTP routing, request validation, response serialization |
| **Application** | `application/services/` | Business logic, use cases, orchestration |
| **Domain** | `domain/entities/` + `domain/interfaces/` | Pure Python entities, repository contracts |
| **Infrastructure** | `infrastructure/repositories/` + `db/models/` | Database access, SQLAlchemy ORM |
| **AI** | `ai/` | Pluggable AI modules, unified context, quota enforcement |

---

## 📁 Project Structure

### Backend

```
backend/
├── app/
│   ├── main.py                        # FastAPI app, CORS, routing, static files
│   ├── api/v1/
│   │   ├── router.py                  # Central route registration
│   │   └── endpoints/                 # 20 endpoint modules (119 routes total)
│   ├── domain/
│   │   ├── entities/                  # 17 pure Python dataclass entities
│   │   └── interfaces/                # 15 repository abstract interfaces
│   ├── application/
│   │   ├── services/                  # 15 business logic services
│   │   └── schemas/                   # 17 Pydantic v2 request/response schemas
│   ├── infrastructure/
│   │   ├── db/models/                 # 26 SQLAlchemy ORM models
│   │   ├── repositories/              # 15 concrete repository implementations
│   │   ├── storage/                   # File storage service
│   │   └── logging/                   # structlog configuration
│   ├── ai/
│   │   ├── client.py                  # Claude API client + model constants
│   │   ├── context_builder.py         # ★ Unified user context for all AI modules
│   │   ├── chat_assistant.py          # Haiku-powered conversational assistant
│   │   ├── analyzers/                 # weekly_analyzer, calorie_vision_analyzer
│   │   └── generators/                # workout, meal, recipe, calorie_bank, cycle
│   └── core/
│       ├── config.py                  # QUOTA_LIMITS, model tiers
│       ├── dependencies.py            # get_current_user, get_current_user_premium
│       ├── ai_rate_limiter.py         # Server-side quota enforcement
│       └── security.py                # JWT creation and verification
├── migrations/versions/
│   └── 0001_baseline.py               # Single migration — all 26 tables
├── static/
│   ├── index.html                     # Landing page
│   └── privacy-policy.html
└── tests/
    ├── unit/
    └── integration/
```

### Mobile (Flutter)

```
mobile/lib/
├── main.dart
├── app.dart                           # GoRouter, ThemeModeNotifier, ProviderScope
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Dio singleton + AuthInterceptor + 429 handler
│   │   └── endpoints.dart             # All URL constants
│   ├── auth/token_manager.dart
│   ├── services/
│   │   ├── rate_limiter.dart          # UX-only client rate limiter
│   │   └── ai_job_poller.dart         # Async stream: job_id → poll → result
│   ├── notifications/
│   └── theme/                         # Dark/light theme, color tokens
├── features/
│   ├── ai/widgets/
│   │   ├── ai_feedback_bar.dart       # 👍/👎 under every AI output
│   │   ├── quota_banner.dart          # Quota usage + paywall link
│   │   └── ai_progress_sheet.dart     # Staged AI loading indicator
│   ├── meals/meal_entry_hub.dart      # Single entry: Manual | Barcode | Photo
│   ├── workout/extra_session_sheet.dart
│   └── shopping/plan_to_shopping_service.dart
└── screens/                           # 37 screens across 15 feature groups
    ├── auth/           # login, register
    ├── onboarding/     # 6-step onboarding with validation
    ├── home/           # dashboard, more menu
    ├── takip/          # measurements, diet, water, sleep
    ├── egzersiz/       # session list, session detail
    ├── ai/             # chat, weekly summary, workout plan, meal advice,
    │                   # recipe, calorie vision, calorie bank, cycle advice
    ├── health/         # blood values, progress photos, insights, check-in
    ├── billing/        # subscription, paywall, AI credits
    ├── raporlar/       # charts, Wrapped, PDF
    ├── sosyal/         # friends, leaderboard, duels
    ├── gamification/   # XP, badges, streaks
    ├── profil/
    ├── steps/
    ├── alisveris/      # shopping list + barcode
    └── cycle/          # menstrual cycle (female users only)
```

---

## 🗄️ Database Design

26 tables across 6 functional groups. Single Alembic baseline migration.

| Group | Tables |
|---|---|
| **User / Auth** | `users`, `user_preferences`, `onboarding_profile`, `user_levels` |
| **Health Tracking** | `body_measurements`, `water_logs`, `sleep_logs`, `step_logs`, `meal_compliance`, `menstrual_cycles` |
| **Exercise** | `exercise_sessions`, `session_exercises`, `exercise_catalog` |
| **Health Records** | `blood_values`, `weekly_notes`, `file_uploads` |
| **AI** | `ai_jobs`, `ai_usage_logs`, `ai_response_cache`, `ai_feedback`, `chat_messages` |
| **Social / Gamification** | `friendships`, `duels`, `badges`, `streaks`, `shopping_items` |

### ER Diagram (Core Tables)

```mermaid
erDiagram
    users ||--o{ body_measurements : "tracks"
    users ||--o{ exercise_sessions : "logs"
    users ||--o{ meal_compliance : "records"
    users ||--o{ water_logs : "logs"
    users ||--o{ sleep_logs : "logs"
    users ||--o{ step_logs : "logs"
    users ||--|| user_preferences : "has"
    users ||--|| onboarding_profile : "completes"
    users ||--|| user_levels : "earns"
    users ||--o{ ai_jobs : "requests"
    users ||--o{ ai_usage_logs : "consumes"
    users ||--o{ chat_messages : "sends"
    users ||--o{ friendships : "creates"
    users ||--o{ badges : "earns"
    users ||--o{ streaks : "maintains"
    exercise_sessions ||--o{ session_exercises : "contains"
```

### Key Design Decisions

- `meal_compliance.complied` — automatically computed by backend (3 states: compliant / deviated / no_data)
- `ai_usage_logs` — `UNIQUE(user_id, module, week_start)` with atomic UPSERT for race-safe quota counting
- `session_exercises.muscle_groups` — JSON array for flexible muscle group tagging
- `user_preferences.ai_name` — personalized AI coach name (defaults to "TrackForge AI")

---

## ⚙️ Installation

### Prerequisites

- Python 3.14+
- PostgreSQL 16+
- Flutter 3.41.6+

### Backend

```bash
# Clone the repository
git clone https://github.com/MemetSacal/trackforge.git
cd trackforge/backend

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your values

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

API docs available at `http://localhost:8000/docs`

### Mobile (Flutter)

```bash
cd trackforge/mobile

# Install dependencies
flutter pub get

# Run on device/emulator
flutter run

# Build release APK
flutter build apk --release

# Build AAB (Play Store)
flutter build appbundle --release
```

---

## 🔐 Environment Variables

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:password@host:5432/trackforge

# Security
SECRET_KEY=your-secret-key-min-32-chars
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# AI
ANTHROPIC_API_KEY=your-anthropic-api-key

# External APIs
OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org
```

---

## 🔌 API Overview

Base URL: `https://trackforge-3o2j.onrender.com/api/v1`

### Authentication

| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/register` | Create new account |
| POST | `/auth/login` | Login → access + refresh tokens |
| POST | `/auth/refresh` | Refresh access token |
| GET | `/auth/me` | Current user + is_premium flag |

### Health Tracking

| Method | Endpoint | Description |
|---|---|---|
| POST/GET/PUT/DELETE | `/measurements` | Body measurements CRUD |
| POST/GET/PUT/DELETE | `/water` | Water intake CRUD |
| POST/GET/PUT/DELETE | `/sleep` | Sleep logs CRUD |
| POST/GET/PUT | `/steps` | Step count CRUD |
| POST/GET/PUT/DELETE | `/meal-compliance` | Daily calorie compliance |
| POST/GET/PUT | `/cycle` | Menstrual cycle CRUD |

### Exercise

| Method | Endpoint | Description |
|---|---|---|
| POST/GET/PUT/DELETE | `/exercises/sessions` | Workout sessions |
| POST/GET/PUT/DELETE | `/exercises/sessions/{id}/exercises` | Session exercises |

### AI

| Method | Endpoint | Free Quota | Description |
|---|---|---|---|
| POST | `/ai/weekly-summary` | 1/week | AI weekly analysis |
| POST | `/ai/workout-plan` | 1/week | AI workout plan (generate/revise) |
| POST | `/ai/meal-advice` | 1/week | 7-day meal plan with ingredients |
| POST | `/ai/recipe` | 2/week | Personalized recipe |
| POST | `/ai/calorie-from-photo` | 3/day | Vision calorie estimation |
| POST | `/ai/calorie-bank-advice` | unlimited | Bank status advice |
| POST | `/ai/cycle-advice` | unlimited | Phase-aware advice |
| POST | `/ai/chat` | limited | Chat assistant (Haiku) |
| GET | `/ai/jobs/{id}` | — | Poll async job status |
| POST | `/ai/feedback` | — | Submit 👍/👎 rating |

### Social & Gamification

| Method | Endpoint | Description |
|---|---|---|
| GET | `/social/friends` | Friend list |
| GET | `/social/friends/pending` | Pending requests |
| GET | `/social/leaderboard` | Weekly XP leaderboard (friends only) |
| GET | `/gamification/summary` | Level, streaks, badges |

### Other

| Method | Endpoint | Description |
|---|---|---|
| GET | `/barcode/{barcode}` | Open Food Facts lookup |
| GET | `/reports/weekly` | Weekly health report |
| GET | `/reports/monthly` | Monthly health report |
| POST/GET/PUT | `/onboarding` | Onboarding profile |
| POST/GET/PUT/DELETE | `/shopping` | Shopping list |
| GET/POST/PUT/DELETE | `/preferences` | User preferences |

---

## 🔑 Authentication Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as FastAPI Backend
    participant DB as PostgreSQL

    App->>API: POST /auth/login (email, password)
    API->>DB: Verify password hash (bcrypt)
    DB-->>API: User found
    API-->>App: access_token (30 min) + refresh_token (7 days)
    App->>App: Store tokens (flutter_secure_storage)

    Note over App,API: Subsequent requests

    App->>API: Any request (Bearer access_token)
    API-->>App: 401 Unauthorized (token expired)
    App->>App: AuthInterceptor catches 401
    App->>API: POST /auth/refresh
    API-->>App: New access_token
    App->>API: Retry original request automatically
```

---

## 🔒 Security

| Measure | Implementation |
|---|---|
| **Password hashing** | passlib with bcrypt |
| **JWT signing** | python-jose, HS256 |
| **Token expiry** | Access: 30 min / Refresh: 7 days |
| **Auto token refresh** | Dio interceptor — transparent to user |
| **Secure local storage** | flutter_secure_storage for JWT tokens |
| **CORS** | FastAPI CORS middleware |
| **Input validation** | Pydantic v2 on all endpoints + Flutter form validators |
| **Server-side quota** | Atomic PostgreSQL UPSERT — client cannot bypass |
| **IDOR protection** | AI job ownership: `job.user_id != current_user.id → 404` |

---

## 🤖 AI Integration

### Models

| Model | Usage |
|---|---|
| `claude-sonnet-4-5` | Workout plans, meal advice, weekly summary, vision, recipes, calorie bank, cycle advice |
| `claude-haiku-4-5-20251001` | Chat assistant (fast, low-cost, token-capped) |

### Unified Context System

Every AI call receives the same structured context built by `context_builder.py`:

```
Profile:      goal, target weight, activity level, diet preference
Current:      weight (kg), height (cm), age
Last 7 days:  sessions completed/planned, meal compliance %, avg kcal, avg steps
Cycle phase:  phase name + day number (female users, when available)
Today:        remaining kcal, protein (g), carbs (g), fat (g)
```

Target size: ~300–500 tokens. Fields are omitted when data is unavailable.

### Quota & Cache Flow

```
Client request
    ↓
input_hash = SHA-256(payload + context)
    ↓
Cache hit? → Return cached response (quota NOT consumed)
    ↓
Cache miss → QuotaService.check_and_consume() [atomic UPSERT]
    ↓
Quota OK → Create ai_job → BackgroundTasks.add_task(run_ai_job)
    ↓
Return job_id immediately
    ↓
Flutter polls GET /ai/jobs/{id} every 2 seconds
    ↓
status: done → display result + write to cache
```

### Cost Optimizations

- Cache layer avoids redundant API calls (TTL: 7 days for plans, 30 days for recipes, 0 for vision)
- Haiku model for chat (significantly cheaper than Sonnet)
- Token cap on chat assistant
- Compact context block (~300–500 tokens, not prose)

---

## ⚡ Performance

| Approach | Details |
|---|---|
| **Async throughout** | FastAPI + SQLAlchemy 2.0 async — no blocking I/O |
| **Background tasks** | Heavy AI generation via FastAPI `BackgroundTasks` |
| **Response caching** | AI responses cached by input hash in `ai_response_cache` |
| **Client-side cache** | Weekly meal plan cached in SharedPreferences (user-scoped) |
| **Atomic UPSERT** | Quota counting via PostgreSQL `INSERT ... ON CONFLICT DO UPDATE` |
| **Lazy token refresh** | Dio interceptor retries on 401 only |
| **Structured logging** | structlog JSON output for production observability |

---

## 🔄 CI/CD Pipeline

```mermaid
graph LR
    Push["Git Push"] --> Actions["GitHub Actions"]
    Actions --> Lint["flake8 Lint"]
    Lint -->|pass| Render["Render Auto-Deploy"]
    Lint -->|fail| Block["Build Blocked"]
    Render --> Migrate["alembic upgrade head"]
    Migrate --> Start["uvicorn startup"]
```

**Flake8 config:**
```bash
flake8 backend/app/ --max-line-length=500 \
  --extend-ignore=W292,W291,W391,E302,E303,E305,E261,E262,E265,E231,F401,E741,F821,E501
```

---

## 🚀 Deployment

### Production Stack

```
Flutter App (Android / iOS)
        ↓ HTTPS / JWT
Render Starter ($7/mo, always-on)
   FastAPI + Uvicorn
        ↓
PostgreSQL (Render managed)
        ↓
Anthropic Claude API · Open Food Facts API
```

**Render start command:**
```bash
cd backend && \
PYTHONPATH=/opt/render/project/src alembic upgrade head && \
cd .. && \
uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT
```

### Live URLs

| Service | URL |
|---|---|
| API | https://trackforge-3o2j.onrender.com |
| Swagger Docs | https://trackforge-3o2j.onrender.com/docs |
| Landing Page | https://trackforge-3o2j.onrender.com/ |
| Privacy Policy | https://trackforge-3o2j.onrender.com/static/privacy-policy.html |

---

## 🧪 Testing

Test infrastructure in place (`tests/unit/` and `tests/integration/` with pytest + httpx). Comprehensive test coverage is planned for a future release. The CI pipeline currently enforces linting on every push.

---

## 🗺️ Roadmap

- [x] JWT authentication system
- [x] Core health tracking (measurements, water, sleep, steps, diet)
- [x] Exercise session tracking with muscle group support
- [x] AI workout planner
- [x] AI meal advisor with 7-day plans
- [x] AI weekly summary
- [x] AI calorie vision (Claude Vision)
- [x] AI recipe generator
- [x] AI calorie bank advisor
- [x] AI cycle advisor
- [x] AI chat assistant (Claude Haiku)
- [x] Unified AI context layer (context_builder)
- [x] Server-side quota enforcement
- [x] Async AI job pattern with client polling
- [x] AI response caching
- [x] AI feedback system (👍/👎)
- [x] Barcode scanner (Open Food Facts)
- [x] Calorie bank system (weekly carry-over)
- [x] Gamification (XP, levels, badges, streaks)
- [x] Social system (friends, leaderboard, duels)
- [x] Shopping list with meal plan export
- [x] Reports with fl_chart (weekly + monthly + Wrapped + PDF)
- [x] Menstrual cycle tracking with phase-aware AI
- [x] Blood values tracking
- [x] Progress photos
- [x] Dark/light theme
- [x] Push notifications
- [x] 6-step onboarding flow
- [x] Freemium subscription screens (RevenueCat skeleton)
- [x] Google Play internal test track
- [ ] RevenueCat subscription purchase flow
- [ ] FCM push notifications (proactive coaching triggers)
- [ ] Health Connect / wearable integration
- [ ] Apple Developer account + App Store
- [ ] Multilingual support (TR + EN)
- [ ] Expanded badge catalog

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit with Conventional Commits: `git commit -m 'feat: add your feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

Commit types: `feat` · `fix` · `refactor` · `docs` · `chore`

---

## 📄 License

```
MIT License

Copyright (c) 2026 Memet Saçal

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 👤 Author

<div align="center">

**Memet Saçal**
Computer Engineering Student, Ondokuz Mayıs University

[![GitHub](https://img.shields.io/badge/GitHub-MemetSacal-181717?style=for-the-badge&logo=github)](https://github.com/MemetSacal)

</div>

---

<div align="center">

*Built from scratch · FastAPI + Flutter + Claude AI · 26 tables · 119 routes · 37 screens*

</div>