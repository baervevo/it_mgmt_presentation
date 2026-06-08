@echo off
REM Start cwiczenia (Windows): zbuduj i uruchom kontenery, wejdz do control.
cd /d "%~dp0"

docker compose up -d --build
if errorlevel 1 (
    echo Blad: nie udalo sie zbudowac/uruchomic kontenerow.
    pause
    exit /b 1
)

echo.
echo ^>^> Wchodze do kontenera control (repo w ~/workspace). Wyjscie: 'exit'.
docker compose exec control bash
