@echo off
echo ================================================================
echo  ResumAI — Local Development Startup
echo ================================================================
echo.

:: Check if .env exists
if not exist backend\.env (
    echo [!] backend\.env not found. Copying from .env.example...
    copy backend\.env.example backend\.env
    echo [!] Please fill in your API keys in backend\.env before continuing.
    pause
    exit /b 1
)

echo [1/3] Starting PostgreSQL via Docker...
docker compose up db -d
echo     Waiting 5 seconds for Postgres to be ready...
timeout /t 5 /nobreak > NUL

echo [2/3] Starting Flask backend...
start "ResumAI Backend" cmd /k "cd backend && pip install -r requirements.txt > NUL 2>&1 && python -m spacy download en_core_web_sm > NUL 2>&1 && set FLASK_APP=run.py && flask db upgrade && python run.py"

echo [3/3] Starting React frontend...
start "ResumAI Frontend" cmd /k "cd frontend && npm install > NUL 2>&1 && npm run dev"

echo.
echo ================================================================
echo  ResumAI is starting!
echo  Frontend: http://localhost:3000
echo  Backend:  http://localhost:5000/api/health
echo ================================================================
echo.
pause
