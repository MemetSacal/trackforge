# ⚡ TrackForge

[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org)
[![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=for-the-badge&logo=sqlalchemy&logoColor=white)](https://www.sqlalchemy.org)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Claude API](https://img.shields.io/badge/Claude_API-Anthropic-6B46C1?style=for-the-badge)](https://www.anthropic.com)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)

[![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen?style=flat-square)]()
[![Phase](https://img.shields.io/badge/Phase-10%2F10-brightgreen?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)

> *You don't need another tracker.*
> *You need a system that understands you.*

**TrackForge** turns your raw health data into **decisions, insights, and action plans** — powered by AI.

</div>

---

## 🚨 The Problem

Most fitness apps only **collect data**:
- You log your weight
- You log your meals
- You log your workouts

But then… nothing.

No real understanding. No guidance. No adaptation.

---

## ✅ The Solution

TrackForge is built as a **thinking system**, not a logging tool.

It analyzes your behavior patterns, detects trends in your data, adapts recommendations dynamically, and acts like a **personal AI coach** — one that actually knows your history.

---

## 🔄 How It Works

```
Track  →  Understand  →  Improve  →  (repeat)
```

1. **Track** — Log your data: weight, meals, sleep, workouts, water
2. **Analyze** — AI processes your patterns and behavior over time
3. **Guide** — You get personalized, data-driven recommendations
4. **Improve** — You act. The system adapts.

---

## 📸 Product Preview

### Dashboard Experience

> The AI Coach card gives you a daily briefing — what's going well, what needs attention, and what to do next.

<p align="center">
  <img src="doc/images/dashboard_light.png" width="45%" alt="Dashboard Light Mode"/>
  &nbsp;&nbsp;
  <img src="doc/images/dashboard_dark.png" width="45%" alt="Dashboard Dark Mode"/>
</p>

---

### Health Tracking

> Body measurements, Calorie Bank, and sleep quality — all in one place.

<p align="center">
  <img src="doc/images/tracking_light.png" width="30%" alt="Body Measurements"/>
  &nbsp;
  <img src="doc/images/calorie_bank_dark.png" width="30%" alt="Calorie Bank"/>
  &nbsp;
  <img src="doc/images/sleep_light.png" width="30%" alt="Sleep Tracking"/>
</p>

---

### AI-Powered Features

> Claude API integration that goes beyond static plans — it thinks with your data.

<p align="center">
  <img src="doc/images/exercise_dark.png" width="45%" alt="Exercise & Muscle Groups"/>
  &nbsp;&nbsp;
  <img src="doc/images/ai_coach_light.png" width="45%" alt="AI Coach"/>
</p>

---

### Insights, Reports & Social

> Weekly AI commentary on your progress, and a friends-only leaderboard that keeps you accountable.

<p align="center">
  <img src="doc/images/reports_dark.png" width="45%" alt="Reports"/>
  &nbsp;&nbsp;
  <img src="doc/images/social_light.png" width="45%" alt="Social Leaderboard"/>
</p>

---

## 🧠 AI That Actually Thinks

Unlike static plans, TrackForge AI:
- Reads your full weekly data — weight, diet, sleep, exercise, water, mood
- Gives feedback like a real coach, not a calculator
- Adjusts diet advice based on your blood values and health history
- Understands your cycle phase and adapts workout + nutrition recommendations
- Estimates calories from a food photo using Claude Vision
- Generates personalized recipes based on available ingredients

| Feature | Description |
|---|---|
| 📊 Weekly AI Summary | Full analysis of your week — trends, wins, suggestions |
| 📸 Calorie Vision | Upload a food photo → Claude Vision estimates calories & macros |
| 🍽️ Diet Advisor | BMR/TDEE-based plan with allergy & preference support |
| 👨‍🍳 Recipe Generator | Ingredient-based healthy recipe suggestions |
| 💪 Workout Planner | Location-aware program (home / gym / outdoor) |

---

## ⚙️ Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Backend** | FastAPI 0.115+ | Async native, automatic OpenAPI docs |
| **Database** | PostgreSQL 16 | ACID, JSON support, powerful indexing |
| **ORM** | SQLAlchemy 2.0 (async) | Full async support, type-safe |
| **Migration** | Alembic | Schema version control |
| **Auth** | JWT (python-jose) | Stateless, mobile-friendly |
| **Validation** | Pydantic v2 | Native FastAPI integration |
| **File I/O** | aiofiles | Non-blocking chunked file writes |
| **Container** | Docker + Compose | Reproducible dev environment |
| **AI** | Claude API (claude-sonnet-4-5) | Long context, Vision support, powerful analysis |
| **Barcode** | Open Food Facts API | 3M+ products, free |
| **Mobile** | Flutter 3.x | iOS + Android single codebase |
| **State Mgmt** | Riverpod 2.x | Compile-safe, testable |
| **HTTP Client** | Dio | Interceptors, token refresh |
| **Charts** | fl_chart | Native Flutter charts |
| **Routing** | GoRouter | Declarative, deep-link ready |
| **CI/CD** | GitHub Actions | Automated lint pipeline |

> **Why async?** All DB queries, file operations, and AI API calls run non-blocking — built for concurrency from day one.
>
> **Why Clean Architecture?** The domain layer depends on nothing. Swapping databases, AI providers, or adding Flutter won't break the core. Only the infrastructure layer is affected.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                         │
│           Flutter App (iOS + Android)                   │
│     Screens → Riverpod Providers → Repositories         │
│                    Dio HTTP Client                       │
└─────────────────────┬───────────────────────────────────┘
                      │ HTTPS / REST / JSON
                      │ Authorization: Bearer <JWT>
┌─────────────────────▼───────────────────────────────────┐
│                FastAPI (Uvicorn)                         │
│         Router /api/v1 · JWT Auth · CORS                 │
│                                                         │
│   ┌──────────────────────────────────────────────────┐  │
│   │            CLEAN ARCHITECTURE CORE               │  │
│   │  Presentation → Application → Domain             │  │
│   │                    ↓                             │  │
│   │              Infrastructure                      │  │
│   │                    ↓                             │  │
│   │           AI Layer (Claude API)                  │  │
│   └──────────────────────────────────────────────────┘  │
└──────────────┬──────────────────────┬───────────────────┘
               │                      │
      ┌────────▼──────┐     ┌─────────▼──────┐
      │  PostgreSQL   │     │  File Storage   │
      │  (async ORM)  │     │  Local → S3     │
      └───────────────┘     └────────────────┘
```

**Dependency rule:** Arrows only flow inward. The domain layer has zero external dependencies.

| Layer | Path | Responsibility |
|---|---|---|
| Presentation | `api/v1/endpoints/` | HTTP routing, request validation |
| Application | `application/services/` | Business logic, use cases |
| Domain | `domain/entities/` + `domain/interfaces/` | Pure Python entities, contracts |
| Infrastructure | `infrastructure/repositories/` | DB queries, external APIs |
| AI | `ai/analyzers/` + `ai/generators/` | Claude API integration |

---

## ✨ Key Features

### 🏋️ Fitness & Activity
- Exercise sessions with per-exercise logging (sets, reps, weight, muscle groups)
- Interactive muscle group anatomy map with front/back toggle (Flutter)
- YouTube integration — form video for every exercise
- Step counter with manual entry and daily goals
- Streak system for water, exercise, and sleep consistency

### 🥗 Nutrition & Diet
- **Calorie Bank System** — a rolling 7-day calorie credit model
  - Daily target = TDEE ± offset (lose / maintain / gain)
  - Earn credits on low days, spend on high days
  - 1,500 kcal safety floor enforced
- Meal compliance tracking with macro breakdown
- Barcode scanner → Open Food Facts API (3M+ products)
- BMR/TDEE via Mifflin-St Jeor formula
- AI-powered calorie estimation from food photos (Claude Vision)

### 😴 Health Monitoring
- Water intake with daily goals, quick-add buttons, and history
- Sleep logging: quality score, duration, sleep/wake times
- Body measurements: weight, body fat %, muscle mass, waist, chest, hips, arms, legs
- Blood values & health history in user profile
- Menstrual cycle tracker with phase-aware AI recommendations

### 🏆 Gamification
- XP & Level system: Beginner → Active → Fit → Athlete → Champion
- Badge system: first workout, water streaks, weight loss milestones
- Streak tracking across water, exercise, and sleep
- Friends-only weekly XP leaderboard

### 🛒 Shopping List
- Smart grocery list with category, price, recurring item support
- Barcode scan to add items directly from product database

### 📊 Reports
- Weekly + monthly reports with fl_chart trend graphs
- Weight, water, and sleep charts
- AI commentary integrated into weekly reports

### 🤖 AI Coach
- Customizable AI coach name (saved to user preferences)
- Weekly health summary with actionable insights
- Personalized workout plans (gym / home / outdoor)
- Diet advice based on BMR/TDEE and health profile
- Recipe suggestions from available ingredients
- Calorie estimation from food photos

---

## 🗄️ Database

TrackForge uses **17 tables** across all phases:

```
Core:           users, body_measurements, weekly_notes
Nutrition:      meal_compliance, shopping_items
Activity:       exercise_sessions, session_exercises
Health:         water_logs, sleep_logs, user_preferences
                step_logs, menstrual_cycles
Files:          file_uploads
Onboarding:     onboarding_profile
Gamification:   streaks, badges, user_levels
Social:         friendships
```

### Calorie Bank Logic

```
calories_target     = TDEE - 700   (weight loss)
                    = TDEE + 250   (muscle gain)
                    = TDEE         (maintenance)

calorie_balance     = calories_consumed - calories_target
weekly_bank_balance = rolling 7-day cumulative balance
today_max_calories  = calories_target + weekly_bank_balance
safety_floor        = 1,500 kcal
```

---

## 📡 API Endpoints

> All endpoints are interactive via **Swagger UI** at `http://localhost:8000/docs`

```
── AUTH ──────────────────  POST /register · /login · /refresh · GET /me
── ONBOARDING ────────────  POST · GET · PUT /onboarding · POST /complete
── MEASUREMENTS ──────────  POST · GET · PUT · DELETE /measurements
── NOTES ─────────────────  POST · GET · PUT · DELETE /notes
── MEAL COMPLIANCE ───────  POST · GET · PUT · DELETE /meal-compliance
── WATER ─────────────────  POST · GET · PUT · DELETE /water
── SLEEP ─────────────────  POST · GET · PUT · DELETE /sleep
── STEPS ─────────────────  POST · GET · PUT /steps
── EXERCISES ─────────────  Sessions + per-exercise CRUD
── FILES ─────────────────  Photos + PDF upload, download, delete
── PREFERENCES ───────────  POST · GET · PUT · DELETE /preferences
── SHOPPING ──────────────  Full CRUD + toggle + clear completed
── REPORTS ───────────────  GET /weekly · GET /monthly
── BARCODE ───────────────  GET /barcode/{barcode}
── CYCLE ─────────────────  POST · GET · PUT /cycle
── GAMIFICATION ──────────  GET /summary · /streaks · /badges · /level
── SOCIAL ────────────────  Friend requests · accept · list · leaderboard
── AI ────────────────────  /weekly-summary · /workout-plan · /meal-advice
                            /recipe · /calorie-from-photo
```

---

## 🔐 Authentication

```
POST /auth/login  →  access_token (30 min) + refresh_token (7 days)
Every request     →  Authorization: Bearer <access_token>
Token expired     →  POST /auth/refresh → auto-retry via Dio interceptor
Flutter           →  shared_preferences (web-compatible)
```

---

## 📱 Flutter App Structure

```
lib/
├── main.dart
├── app.dart                    # GoRouter + MaterialApp + ThemeMode
├── core/
│   ├── api/
│   │   ├── api_client.dart     # Dio singleton + AuthInterceptor
│   │   └── endpoints.dart      # All URL constants
│   ├── auth/
│   │   └── token_manager.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/
│       └── date_utils.dart
├── screens/
│   ├── auth/                   # Login, Register
│   ├── onboarding/             # 4-step guided setup
│   ├── home/                   # Dashboard, More
│   ├── takip/                  # Ölçüm, Diyet, Su, Uyku tabs
│   ├── egzersiz/               # Sessions + detail + muscle map
│   ├── ai/                     # 5 AI features
│   ├── raporlar/               # Weekly + monthly charts
│   ├── sosyal/                 # Friends + leaderboard
│   ├── alisveris/              # Shopping list + barcode
│   ├── profil/                 # Profile + settings
│   ├── gamification/           # XP, streaks, badges
│   ├── steps/                  # Step counter
│   └── cycle/                  # Menstrual cycle tracker
└── widgets/
    └── body_map/               # Muscle anatomy widget
```

### Screens

| Screen | Status | Notes |
|--------|--------|-------|
| Login / Register | ✅ | JWT flow |
| Onboarding | ✅ | 4-step, backend integrated |
| Dashboard | ✅ | Gamification + weekly summary |
| Tracking — Measurements | ✅ | Full CRUD |
| Tracking — Diet | ✅ | AI plan via shared_prefs |
| Tracking — Water | ✅ | Circular progress, quick-add |
| Tracking — Sleep | ✅ | TimePicker, quality slider |
| Exercise | ✅ | Sessions + detail + CRUD |
| AI — Weekly Summary | ✅ | Markdown rendering |
| AI — Workout Plan | ✅ | Auto session creation |
| AI — Diet Advice | ✅ | Saved to shared_prefs |
| AI — Recipe | ✅ | Ingredient chip list |
| AI — Calorie Vision | ✅ | Multipart upload |
| Reports | ✅ | fl_chart, weekly + monthly |
| Gamification | ✅ | XP, level, streaks, badges |
| Social | ✅ | Friends + leaderboard |
| Shopping | ✅ | List + barcode scanner |
| Step Counter | ✅ | Manual entry |
| Profile | ✅ | Edit + dark mode + logout |
| More | ✅ | Navigation hub |

---

## 📦 Installation

### Prerequisites
- Python 3.11+
- Docker + Docker Compose
- Flutter 3.x + Android Studio
- Claude API key → [console.anthropic.com](https://console.anthropic.com)

### Backend Setup

```bash
# 1. Clone
git clone https://github.com/MemetSacal/trackforge.git
cd trackforge

# 2. Environment
cp .env.example .env
# Fill in DATABASE_URL, SECRET_KEY, ANTHROPIC_API_KEY

# 3. Start PostgreSQL
docker-compose up -d

# 4. Install dependencies
pip install -r requirements.txt

# 5. Run migrations
alembic upgrade head

# 6. Start server
uvicorn backend.app.main:app --reload --host 0.0.0.0
```

| | |
|---|---|
| **API** | `http://localhost:8000` |
| **Swagger UI** | `http://localhost:8000/docs` |
| **pgAdmin** | `http://localhost:5050` |

### Flutter Setup

```bash
cd mobile
flutter pub get
flutter run
```

### Environment Variables

```env
DATABASE_URL=postgresql+asyncpg://trackforge:trackforge123@localhost:5432/trackforge_db
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

ANTHROPIC_API_KEY=your-anthropic-api-key
OPEN_FOOD_FACTS_BASE_URL=https://world.openfoodfacts.org
```

---

## 🗺️ Roadmap

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Auth system (JWT, Docker, Alembic, structlog) | ✅ Done |
| Phase 2 | Core CRUD (measurements, notes, meal compliance) | ✅ Done |
| Phase 3 | File uploads (photos + PDF, async) | ✅ Done |
| Phase 4 | Exercise tracking (sessions + cascade delete) | ✅ Done |
| Phase 5 | Water, sleep, preferences, shopping list | ✅ Done |
| Phase 6 | Weekly + monthly reports | ✅ Done |
| Phase 7 | Polish & CI/CD (GitHub Actions, README, Docker) | ✅ Done |
| Phase 8 | AI integration (Claude API — 5 features + Vision) | ✅ Done |
| Phase 9 | Onboarding, barcode, gamification, social, steps, cycle | ✅ Done |
| Phase 10 | Flutter mobile app — all screens, polish, APK build | ✅ Done |

### What's Next

```
⏳ Production deploy (Railway / Render)
⏳ Google Play Store submission
⏳ Push notifications & reminders
⏳ Multi-language support (TR + EN)
⏳ iOS App Store (via Mac build)
```

---

## 💡 Why This Project Matters

TrackForge is not just about tracking fitness. It represents:

- **Data-driven decision making** — no guesswork, only evidence
- **Clean Architecture at scale** — domain layer with zero external dependencies
- **AI integration in real-world systems** — Claude API as a thinking layer, not a gimmick
- **Behavior-aware software design** — the system adapts to you, not the other way around
- **Full-stack ownership** — backend, mobile, AI, DevOps — built solo from scratch

> Built as a system, not just an app.

---

## 🗂️ Project Structure

```
trackforge/
├── backend/
│   ├── app/
│   │   ├── ai/                    # Claude API integration
│   │   ├── api/v1/endpoints/      # HTTP layer
│   │   ├── application/           # Services + schemas
│   │   ├── domain/                # Entities + interfaces
│   │   ├── infrastructure/        # DB models + repositories
│   │   └── core/                  # Config, security, dependencies
│   └── migrations/                # Alembic versions
├── mobile/
│   ├── lib/                       # Flutter source
│   ├── assets/                    # Images, fonts
│   └── android/ ios/              # Platform configs
├── doc/
│   ├── architecture.md
│   └── images/                    # UI screenshots
├── .github/workflows/ci.yml
├── docker-compose.yml
├── requirements.txt
└── .env.example
```

---

## 👨‍💻 Author

**Memet Saçal**
Computer Engineering Student — Ondokuz Mayıs University

Full-Stack Developer · Clean Architecture · AI-integrated systems

[![GitHub](https://img.shields.io/badge/GitHub-MemetSacal-181717?style=flat-square&logo=github)](https://github.com/MemetSacal)

---

<div align="center">

*Track your health. Decide with your data. Evolve with AI.*

**⭐ If you find this project interesting, give it a star!**

</div>