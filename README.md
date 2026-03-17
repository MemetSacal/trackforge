# TrackForge

![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-black?style=for-the-badge&logo=JSON%20web%20tokens)
![SQLAlchemy](https://img.shields.io/badge/SQLAlchemy-D71F00?style=for-the-badge&logo=sqlalchemy&logoColor=white)

> *Track your health. Decide with your data. Evolve with AI.*

---

## 🧠 Why TrackForge?

People track their health data across dozens of different apps.
Water intake in one app, sleep in another, workouts somewhere else.
In the end, no single app sees you **as a whole**.

**TrackForge** brings all these pieces into one unified system.
Body measurements, water intake, sleep quality, exercise sessions, diet compliance, shopping list —
all in one API, one data model, one report.

TrackForge is designed for people who want to manage their diet and fitness journey through data — not guesswork.

And this is just the beginning.

In upcoming phases, **Claude API** integration will transform TrackForge from a tracking tool into a personal health coach:

- 🩸 Personalized diet advice based on blood values
- 📸 Calorie estimation from food photos
- 🏋️ Location-based workout plans (home / gym / outdoors)
- 🎯 Goal body visualization
- 📊 Weekly AI summary report — *"How was your week?"*

---

## ⚙️ Tech Stack

| Layer | Technology | Why? |
|---|---|---|
| **Backend** | FastAPI 0.115+ | Fast development + automatic API documentation |
| **Database** | PostgreSQL 16 | ACID compliance, JSON support, powerful indexing |
| **ORM** | SQLAlchemy 2.0 (async) | Strong ORM with full async support |
| **Migration** | Alembic | Schema version control is a must |
| **Auth** | JWT (python-jose) | Stateless, mobile-friendly |
| **Validation** | Pydantic v2 | Native integration with FastAPI |
| **File I/O** | aiofiles | Non-blocking chunked file writes |
| **Container** | Docker + Compose | Reproducible dev environment |
| **AI (Phase 8)** | Claude API (Anthropic) | Long context window, powerful analysis |
| **Vision (Phase 8)** | Claude Vision / GPT-4o | Calorie estimation from food images |
| **Image AI (Phase 8)** | DALL-E 3 / Stable Diffusion | Goal body visualization |
| **Mobile (Phase 9)** | Flutter | Single codebase for iOS + Android |

> **Why async?** All DB queries, file operations, and future AI API calls run non-blocking — built for high concurrency from day one.
>
> **Why Clean Architecture?** Dependencies are minimized, testability is maximized. The domain layer depends on nothing — adding Flutter, a new AI service, or a different database won't break the architecture.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│           PRESENTATION LAYER                │  ← HTTP, routing, validation
│         api/v1/endpoints/                   │
├─────────────────────────────────────────────┤
│           APPLICATION LAYER                 │  ← Use cases, business logic
│         services/ + schemas/                │
├─────────────────────────────────────────────┤
│             DOMAIN LAYER                    │  ← Pure Python entities
│    domain/entities/ + domain/interfaces/    │  ← Repository abstractions
├─────────────────────────────────────────────┤
│         INFRASTRUCTURE LAYER                │  ← DB, files, external services
│  repositories/ + db/models/ + storage/      │
└─────────────────────────────────────────────┘

Dependency rule: arrows point inward only.
The domain layer depends on nothing.
```

> **Example:** When adding a new AI service, only the infrastructure layer is affected. The domain and application layers remain completely untouched.

For detailed architecture documentation: [`doc/architecture.md`](doc/architecture.md)

---

## 📦 Installation

### Requirements
- Python 3.11+
- Docker + Docker Compose
- Git

### 1. Clone the repository

```bash
git clone https://github.com/MemetSacal/trackforge.git
cd trackforge
```

### 2. Set up environment variables

```bash
cp .env.example .env
```

Edit `.env`:

```env
DATABASE_URL=postgresql+asyncpg://trackforge:trackforge123@localhost:5432/trackforge_db
SECRET_KEY=your-super-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Phase 8 — AI Integration (can be left empty for now)
CLAUDE_API_KEY=
OPENAI_API_KEY=
STABILITY_API_KEY=
```

### 3. Start PostgreSQL with Docker

```bash
docker-compose up -d
```

| Service | Address |
|---|---|
| PostgreSQL | `localhost:5432` |
| pgAdmin | `localhost:5050` |

pgAdmin login: `admin@trackforge.com` / `admin123`

### 4. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 5. Run migrations

```bash
alembic upgrade head
```

### 6. Start the application

```bash
uvicorn app.main:app --reload
```

| | |
|---|---|
| **API** | `http://localhost:8000` |
| **Swagger UI** | `http://localhost:8000/docs` |
| **ReDoc** | `http://localhost:8000/redoc` |

---

## 🚀 Quick Start

> Make sure the server is running before trying these examples: `uvicorn app.main:app --reload`

### 1. Register

```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "pass123", "full_name": "John Doe"}'
```

### 2. Login → get token

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "pass123"}'
```

```json
{
  "access_token": "eyJhbGci...",
  "refresh_token": "eyJhbGci...",
  "token_type": "bearer"
}
```

### 3. Log water intake

```bash
curl -X POST http://localhost:8000/api/v1/water \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{"date": "2026-03-17", "amount_ml": 2100, "target_ml": 2800}'
```

### 4. Get weekly report

```bash
curl -X GET "http://localhost:8000/api/v1/reports/weekly?reference_date=2026-03-17" \
  -H "Authorization: Bearer <access_token>"
```

```json
{
  "week_start": "2026-03-16",
  "week_end": "2026-03-22",
  "water": { "avg_daily_ml": 2100, "target_hit_days": 3, "total_days": 5 },
  "sleep": { "avg_hours": 7.75, "avg_quality": 8.2, "total_days": 5 },
  "meal_compliance": { "complied_days": 6, "total_days": 7, "compliance_rate": 85.7 },
  "exercise": { "total_sessions": 4, "total_calories": 1240, "total_duration_minutes": 180 }
}
```

> **Note:** Failed requests return standard HTTP error codes — `401 Unauthorized` for missing/invalid tokens, `422 Unprocessable Entity` for validation errors, `404 Not Found` for missing resources.

---

## 📡 API Endpoints

> All endpoints can be tested interactively via **Swagger UI** at `http://localhost:8000/docs`

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/auth/register` | Register |
| POST | `/api/v1/auth/login` | Login → JWT token |
| POST | `/api/v1/auth/refresh` | Refresh token |

### Body Measurements
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/measurements` | Add measurement |
| GET | `/api/v1/measurements?from=&to=` | Date range |
| PUT | `/api/v1/measurements/{id}` | Update |
| DELETE | `/api/v1/measurements/{id}` | Delete |

### Water Tracking
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/water` | Log water intake |
| GET | `/api/v1/water?start_date=&end_date=` | Date range |
| GET | `/api/v1/water/date/{date}` | Specific day |
| PUT | `/api/v1/water/{id}` | Update |
| DELETE | `/api/v1/water/{id}` | Delete |

### Sleep Tracking
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/sleep` | Log sleep |
| GET | `/api/v1/sleep?start_date=&end_date=` | Date range |
| GET | `/api/v1/sleep/date/{date}` | Specific day |
| PUT | `/api/v1/sleep/{id}` | Update |
| DELETE | `/api/v1/sleep/{id}` | Delete |

### Exercise
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/exercises/sessions` | Create session |
| GET | `/api/v1/exercises/sessions?from=&to=` | Date range |
| PUT | `/api/v1/exercises/sessions/{id}` | Update |
| DELETE | `/api/v1/exercises/sessions/{id}` | Delete (cascade deletes exercises) |

### Meal Compliance
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/meal-compliance` | Log daily compliance |
| GET | `/api/v1/meal-compliance?from=&to=` | Date range |
| PUT | `/api/v1/meal-compliance/{id}` | Update |
| DELETE | `/api/v1/meal-compliance/{id}` | Delete |

### File Uploads
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/files/photos` | Upload progress photo |
| POST | `/api/v1/files/diet-plans` | Upload PDF diet plan |
| GET | `/api/v1/files/download/{id}` | Download file |
| DELETE | `/api/v1/files/{id}` | Delete |

### User Preferences
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/preferences` | Create preferences |
| GET | `/api/v1/preferences` | Get preferences |
| PUT | `/api/v1/preferences` | Update |
| DELETE | `/api/v1/preferences` | Delete |

### Shopping List
| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/v1/shopping` | Add item |
| GET | `/api/v1/shopping` | Full list + cart summary |
| PUT | `/api/v1/shopping/{id}` | Update |
| PATCH | `/api/v1/shopping/{id}/toggle` | Mark as completed |
| DELETE | `/api/v1/shopping/{id}` | Delete |
| DELETE | `/api/v1/shopping/completed/clear` | Clear completed items |

### Reports
| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/v1/reports/weekly?reference_date=` | Weekly summary report |
| GET | `/api/v1/reports/monthly?year=&month=` | Monthly summary report |

---

## 🗄️ Database Tables

```
users                →  User accounts
body_measurements    →  Body metrics (weight, body fat, muscle mass...)
weekly_notes         →  Weekly logs (energy level, mood score)
meal_compliance      →  Daily diet compliance records
file_uploads         →  Photos and PDF files
exercise_sessions    →  Workout sessions
session_exercises    →  Exercises within a session (cascade delete)
water_logs           →  Daily water intake
sleep_logs           →  Sleep records (bedtime, wake time, quality score)
user_preferences     →  Preferences (food, allergies, diseases, blood values)
shopping_items       →  Shopping list (price, source, recurring items)
```

---

## 🔐 Authentication

JWT-based authentication:

```
1. POST /auth/login  →  access_token (15 min) + refresh_token (7 days)
2. Every request     →  Authorization: Bearer <access_token>
3. Token expired     →  POST /auth/refresh
```

**To test in Swagger:** Click the **Authorize** button → enter your token.

---

## 🤖 AI Vision (Phase 8)

TrackForge's ultimate goal is to evolve from a tracking tool into a **personal health coach**.

These features are planned and will be developed iteratively.

### Planned AI Features

**📊 Weekly AI Summary Report**
All weekly data (sleep, water, exercise, diet) is sent to Claude API.
The user receives a readable, personalized summary:
*"Your sleep quality improved this week, but water intake was at 68% of your target..."*

**🩸 Blood Value & Disease-Based Diet Advice**
The user's blood values and medical history are analyzed.
Personalized nutrition advice is generated without conflicting with the dietitian's plan.

**📸 Calorie Estimation from Food Photos**
A meal photo is analyzed via Claude Vision or GPT-4o.
Estimated calories, protein, carbs, and fat values are returned.

**🏋️ Personal PT — Location-Based Workout Plan**
Based on the user's workout_location (home / gym / outdoors) and fitness goal,
a weekly workout plan with sets, reps, and exercises is generated.

**🥗 Ingredient-Based Healthy Recipe Suggestions**
Shopping list items + food preferences + allergies are combined
to suggest healthy, personalized recipes.

**🎯 Goal Body Visualization**
Using the user's current photo + target weight/body fat ratio,
a goal body image is generated via DALL-E 3 or Stable Diffusion.

---

## 🗂️ Project Structure

```
trackforge/
├── app/
│   ├── api/v1/endpoints/     # HTTP layer — route definitions
│   ├── application/
│   │   ├── schemas/          # Pydantic request/response models
│   │   └── services/         # Business logic (use cases)
│   ├── domain/
│   │   ├── entities/         # Pure Python dataclasses — no ORM dependency
│   │   └── interfaces/       # Repository abstractions
│   ├── infrastructure/
│   │   ├── db/models/        # SQLAlchemy ORM models
│   │   ├── repositories/     # Interface implementations
│   │   └── storage/          # Async file storage service
│   └── core/                 # Config, security, exceptions, dependencies
├── migrations/               # Alembic migration files
├── uploads/                  # Local file storage
├── doc/                      # Architecture documentation
├── .env.example
├── docker-compose.yml
└── requirements.txt
```

---

## 🗺️ Roadmap

| Phase | Description | Status |
|---|---|---|
| **Phase 1** | Auth system (JWT + refresh token) | ✅ Done |
| **Phase 2** | Core CRUD (measurements, notes, diet compliance) | ✅ Done |
| **Phase 3** | File uploads (photos + PDF, async) | ✅ Done |
| **Phase 4** | Exercise tracking (sessions + cascade delete) | ✅ Done |
| **Phase 5** | Water, sleep, preferences, shopping list | ✅ Done |
| **Phase 6** | Weekly & monthly reports | ✅ Done |
| **Phase 7** | Polish & deployment (CI/CD, tests) | 🔄 In Progress |
| **Phase 8** | AI integration (Claude API + Vision) | ⏳ Planned |
| **Phase 9** | Flutter mobile application | ⏳ Planned |

---

## 📱 UI Preview

> Design prototypes for the upcoming Flutter mobile app and web dashboard (Phase 9).

### Mobile App

![Mobile Dashboard](doc/images/mobile_dashboard.png)

![Mobile Detail](doc/images/mobile_detail.png)

### Web Dashboard

![Web Dashboard](doc/images/web_dashboard.png)


## 👤 Developer

**Memet Saçal**
GitHub: [@MemetSacal](https://github.com/MemetSacal)

---

*TrackForge — Track your health. Decide with your data. Evolve with AI.*