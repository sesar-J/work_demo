#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"
BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"
BACKEND_LOG_FILE="${RUN_DIR}/backend.log"
FRONTEND_LOG_FILE="${RUN_DIR}/frontend.log"

mkdir -p "${RUN_DIR}"

if [[ -f "${BACKEND_PID_FILE}" ]] && kill -0 "$(cat "${BACKEND_PID_FILE}")" 2>/dev/null; then
  echo "Backend is already running (pid=$(cat "${BACKEND_PID_FILE}"))."
else
  echo "Starting backend..."
  if [[ -x "${ROOT_DIR}/backend/.venv/bin/python" ]]; then
    BACKEND_PYTHON="${ROOT_DIR}/backend/.venv/bin/python"
  elif command -v python3.12 >/dev/null 2>&1; then
    BACKEND_PYTHON="python3.12"
  else
    BACKEND_PYTHON="python3"
  fi

  (
    cd "${ROOT_DIR}/backend"
    if [[ ! -d ".venv" ]]; then
      "${BACKEND_PYTHON}" -m venv .venv
      source .venv/bin/activate
      pip install -r requirements.txt
    else
      source .venv/bin/activate
    fi
    uvicorn app.main:app --reload --port 8000
  ) >"${BACKEND_LOG_FILE}" 2>&1 &

  echo $! >"${BACKEND_PID_FILE}"
  echo "Backend started: pid=$(cat "${BACKEND_PID_FILE}") log=${BACKEND_LOG_FILE}"
fi

if [[ -f "${FRONTEND_PID_FILE}" ]] && kill -0 "$(cat "${FRONTEND_PID_FILE}")" 2>/dev/null; then
  echo "Frontend is already running (pid=$(cat "${FRONTEND_PID_FILE}"))."
else
  echo "Starting frontend..."
  (
    cd "${ROOT_DIR}/frontend"
    npm install
    npm run dev -- --host 127.0.0.1 --port 5173
  ) >"${FRONTEND_LOG_FILE}" 2>&1 &

  echo $! >"${FRONTEND_PID_FILE}"
  echo "Frontend started: pid=$(cat "${FRONTEND_PID_FILE}") log=${FRONTEND_LOG_FILE}"
fi

echo
echo "Open: http://127.0.0.1:5173/"
echo "Backend health: http://127.0.0.1:8000/api/health"
echo "Tail logs with:"
echo "  tail -f ${BACKEND_LOG_FILE}"
echo "  tail -f ${FRONTEND_LOG_FILE}"
