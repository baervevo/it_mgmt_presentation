#!/bin/bash
# Start ćwiczenia (Linux/macOS): zbuduj i uruchom kontenery, wejdź do control.
set -e
cd "$(dirname "$0")"

docker compose up -d --build
echo ">> Wchodzę do kontenera control (repo w ~/workspace). Wyjście: 'exit'."
docker compose exec control bash
