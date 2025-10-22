#!/usr/bin/env bash
set -euo pipefail

# Run local environment: setup venv, install deps, start backend and listener.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV_DIR="$ROOT_DIR/.venv"

echo "Using project root: $ROOT_DIR"

if [ ! -d "$VENV_DIR" ]; then
  echo "Creating virtualenv..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r backend/requirements.txt

echo "Starting backend (uvicorn) on http://127.0.0.1:8001"
nohup "$VENV_DIR/bin/uvicorn" backend.app:app --host 127.0.0.1 --port 8001 --reload > "$ROOT_DIR/run_backend.log" 2>&1 &
sleep 1

echo "Starting clipboard listener"
nohup "$VENV_DIR/bin/python" "$ROOT_DIR/backend/cli/run_listener.py" > "$ROOT_DIR/run_listener.log" 2>&1 &

echo
echo "Backend logs: $ROOT_DIR/run_backend.log"
echo "Listener logs: $ROOT_DIR/run_listener.log"
echo
echo "Frontend: open a separate terminal and run:"
echo "  cd frontend && npm install && npm run dev"
echo
echo "To stop processes:"
echo "  pkill -f 'uvicorn backend.app:app' || true"
echo "  pkill -f 'run_listener.py' || true"
