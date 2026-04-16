# ResumAI — Full-Stack AI-Powered Resume Analyzer

## Overview

A production-ready, self-improvement-focused resume analysis platform serving students, job seekers, and professionals. The system combines classical NLP (TF-IDF + spaCy) with LLM APIs (OpenAI + Google Gemini) to deliver ATS scoring, keyword gap analysis, and actionable AI feedback.

---

## User Review Required

> [!IMPORTANT]
> **API Key Strategy**: The system requires both an OpenAI API key and a Google Gemini API key. Do you want these stored as environment variables only, or also manageable via the admin panel?

> [!IMPORTANT]
> **Google OAuth**: Requires a Google Cloud project with OAuth credentials. Do you have one ready, or should I scaffold it with placeholder redirect URIs?

> [!WARNING]
> **PostgreSQL**: The backend requires a running PostgreSQL instance. I'll use `SQLAlchemy` with Flask and generate a `docker-compose.yml` that includes Postgres, so it works out-of-the-box with Docker.

> [!CAUTION]
> **File Storage**: Resumes will be stored as binary BLOBs in PostgreSQL (not the filesystem), which keeps storage self-contained but may impact performance at scale. A future S3/cloud storage upgrade path will be noted in the code.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENT LAYER                        │
│   React.js SPA  ←→  React Router  ←→  Axios/Fetch      │
└────────────────────────┬────────────────────────────────┘
                         │ REST / JSON
┌────────────────────────▼────────────────────────────────┐
│                    FLASK BACKEND                         │
│  Auth Routes │ Resume Routes │ Analysis Routes │ Admin   │
│         JWT Middleware │ Rate Limiting │ CORS            │
└────┬────────────────────────────────────┬───────────────┘
     │                                    │
┌────▼────────┐                  ┌────────▼──────────────┐
│ PostgreSQL  │                  │    AI Processing       │
│  (via ORM)  │                  │  Pipeline Service      │
│ Users       │                  │  ┌─────────────────┐  │
│ Resumes     │                  │  │ 1. spaCy Parser  │  │
│ Analyses    │                  │  │ 2. TF-IDF Engine │  │
│ Admin Logs  │                  │  │ 3. ATS Scorer    │  │
└─────────────┘                  │  │ 4. OpenAI API    │  │
                                 │  │ 5. Gemini API    │  │
                                 │  └─────────────────┘  │
                                 └───────────────────────┘
```

---

## Proposed Changes

### Backend — Flask Application

#### [NEW] `backend/app/__init__.py`
Flask application factory with blueprint registration, CORS, JWT config, and database init.

#### [NEW] `backend/app/config.py`
Environment-based config classes (Development, Production, Testing).

#### [NEW] `backend/app/models/`
SQLAlchemy ORM models for all PostgreSQL tables.

| File | Model |
|------|-------|
| `user.py` | `User` — auth, profile, role |
| `resume.py` | `Resume` — binary storage, metadata |
| `analysis.py` | `Analysis` — AI results, scores |
| `admin_log.py` | `AdminLog` — audit trail |

#### [NEW] `backend/app/routes/`
Flask blueprints, one per feature domain.

| File | Prefix | Key Endpoints |
|------|--------|---------------|
| `auth.py` | `/api/auth` | `POST /register`, `POST /login`, `GET /google`, `GET /google/callback`, `POST /logout`, `GET /me` |
| `resume.py` | `/api/resume` | `POST /upload`, `GET /list`, `GET /:id`, `DELETE /:id`, `GET /:id/download` |
| `analysis.py` | `/api/analysis` | `POST /analyze`, `GET /:id`, `GET /history`, `POST /export-pdf` |
| `admin.py` | `/api/admin` | `GET /users`, `GET /stats`, `DELETE /user/:id`, `GET /logs` |

#### [NEW] `backend/app/services/`
Business logic and AI processing, fully decoupled from routes.

| File | Responsibility |
|------|----------------|
| `parser_service.py` | PDF/DOCX text extraction (PyMuPDF + python-docx) |
| `nlp_service.py` | spaCy-based entity extraction (name, skills, education, experience) |
| `tfidf_service.py` | TF-IDF vectorization + cosine similarity for keyword matching |
| `ats_service.py` | ATS rule engine: keyword density, section detection, formatting checks |
| `ai_service.py` | OpenAI GPT-4o + Google Gemini calls for suggestions & feedback |
| `grammar_service.py` | LanguageTool API wrapper for grammar/phrasing feedback |
| `pdf_export_service.py` | ReportLab-based PDF report generation |

#### [NEW] `backend/requirements.txt`
All Python dependencies pinned.

#### [NEW] `backend/.env.example`
All required environment variables with descriptions.

---

### Frontend — React Application

#### [NEW] `frontend/` (Vite + React)

```
frontend/src/
├── components/
│   ├── layout/         # Navbar, Sidebar, Footer
│   ├── upload/         # DragDropZone, FilePreview
│   ├── dashboard/      # StatCards, ActivityFeed
│   ├── analysis/       # ATSMeter, SkillChart, KeywordTable, FeedbackPanel
│   ├── auth/           # LoginForm, RegisterForm, GoogleOAuthButton
│   └── admin/          # UserTable, StatsGrid, LogViewer
├── pages/
│   ├── Landing.jsx     # Hero + feature overview
│   ├── Login.jsx
│   ├── Register.jsx
│   ├── Dashboard.jsx   # Resume history + quick stats
│   ├── Upload.jsx      # Upload + JD entry
│   ├── Analysis.jsx    # Full results view
│   ├── Admin.jsx       # Admin panel
│   └── NotFound.jsx
├── hooks/              # useAuth, useAnalysis, useResume
├── services/           # api.js (Axios instance + interceptors)
├── store/              # Zustand global state
├── utils/              # formatters, validators
└── styles/             # Global CSS, design tokens
```

Key UI components:
- **ATSMeter**: Animated arc gauge (0–100) with color bands
- **SkillMatchChart**: Recharts radar + bar chart for skill coverage
- **KeywordTable**: Two-column matched/missing display with TF-IDF weight
- **FeedbackPanel**: Section-wise accordion with AI suggestions
- **DragDropZone**: react-dropzone with file type validation

---

### Database Schema — PostgreSQL

#### `users`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| email | VARCHAR UNIQUE | |
| password_hash | TEXT | bcrypt, NULL for OAuth |
| full_name | VARCHAR | |
| role | ENUM('user','admin') | default 'user' |
| google_id | VARCHAR | OAuth |
| avatar_url | TEXT | |
| created_at | TIMESTAMP | |
| last_login | TIMESTAMP | |

#### `resumes`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK → users | |
| filename | VARCHAR | original name |
| file_data | BYTEA | binary blob |
| file_type | ENUM('pdf','docx') | |
| parsed_text | TEXT | extracted raw text |
| parsed_data | JSONB | structured sections |
| uploaded_at | TIMESTAMP | |

#### `analyses`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| resume_id | UUID FK → resumes | |
| user_id | UUID FK → users | |
| job_description | TEXT | |
| ats_score | FLOAT | 0–100 |
| match_percentage | FLOAT | cosine similarity |
| matched_keywords | JSONB | array of strings |
| missing_keywords | JSONB | array of strings |
| tfidf_scores | JSONB | keyword→weight map |
| ai_suggestions | JSONB | section-wise feedback |
| grammar_issues | JSONB | list of issues |
| skill_gaps | JSONB | |
| created_at | TIMESTAMP | |

#### `admin_logs`
| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| admin_id | UUID FK → users | |
| action | VARCHAR | |
| target_user_id | UUID nullable | |
| details | JSONB | |
| created_at | TIMESTAMP | |

---

### AI Processing Pipeline

```
Upload Resume + Job Description
         │
         ▼
[1] File Parsing (parser_service.py)
    PyMuPDF (PDF) / python-docx (DOCX)
    → raw_text
         │
         ▼
[2] NLP Extraction (nlp_service.py)
    spaCy en_core_web_sm
    → name, skills[], education[], experience[]
    → projects[], contact_info{}
         │
         ▼
[3] TF-IDF + Cosine Similarity (tfidf_service.py)
    - Fit TfidfVectorizer on [resume_text, job_description]
    - Compute cosine_similarity(resume_vec, jd_vec)
    → match_percentage, matched_keywords[], missing_keywords[]
         │
         ▼
[4] ATS Scoring (ats_service.py)
    Rule-based checks:
    - Section detection (Summary, Experience, Education, Skills)
    - Keyword density
    - Bullet point usage
    - No tables/columns (ATS parsing)
    - File format compliance
    - Contact info completeness
    → ats_score (0–100) with breakdown
         │
         ▼
[5] AI Feedback (ai_service.py)
    OpenAI GPT-4o (primary):
    - "Improve the experience bullets"
    - "Suggest missing skills for this JD"
    Google Gemini (secondary / fallback):
    - Section-wise analysis
    - Overall narrative feedback
    → ai_suggestions{} (keyed by section)
         │
         ▼
[6] Grammar Check (grammar_service.py)
    LanguageTool API
    → grammar_issues[]
         │
         ▼
[7] Persist to PostgreSQL
    Save Analysis record
         │
         ▼
[8] Return JSON Response to Frontend
```

---

### Authentication Flow

```
Email/Password:
  Register → bcrypt hash → store in DB → issue JWT
  Login → verify hash → issue access JWT (15m) + refresh JWT (7d)
  Refresh → /api/auth/refresh → new access token

Google OAuth:
  FE: Click "Sign in with Google"
  BE: GET /api/auth/google → redirect to Google consent
  Google → callback → /api/auth/google/callback
  BE: Verify token → upsert user (google_id) → issue JWT
  FE: Store JWT in httpOnly cookie (or memory + refresh token)

JWT Middleware:
  All protected routes → @jwt_required decorator
  Admin routes → @admin_required (role check)
```

---

## Open Questions

> [!IMPORTANT]
> **Deployment Target**: Are you deploying this locally (Docker Compose) or to a cloud provider (Render, Railway, AWS)? This affects how I configure CORS origins and environment variables.

> [!IMPORTANT]
> **AI Cost Control**: OpenAI and Gemini calls cost money per request. Should I add a daily analysis limit per free user (e.g., 5/day)?

---

## Verification Plan

### Automated
- `pytest` for all Flask route and service unit tests
- `vitest` for React component tests

### Manual Browser Verification
- Upload a PDF resume → verify parsed sections appear correctly
- Enter a job description → verify ATS score + match % render
- Verify keyword table shows matched/missing keywords
- Verify AI feedback accordion loads section suggestions
- Test Google OAuth redirect → callback → dashboard redirect
- Test admin panel user list and log viewer

### Build Validation
- `npm run build` on frontend → zero errors
- `flask db upgrade` on backend → migrations apply cleanly
- `docker-compose up` → all services healthy
