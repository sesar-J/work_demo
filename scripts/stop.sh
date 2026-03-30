#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="${ROOT_DIR}/.run"
BACKEND_PID_FILE="${RUN_DIR}/backend.pid"
FRONTEND_PID_FILE="${RUN_DIR}/frontend.pid"

stop_by_pid_file() {
  local pid_file="$1"
  local name="$2"

  if [[ ! -f "${pid_file}" ]]; then
    echo "${name} is not tracked."
    return
  fi

  local pid
  pid="$(cat "${pid_file}")"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}" 2>/dev/null || true
    echo "Stopped ${name} (pid=${pid})."
  else
    echo "${name} process already stopped (pid=${pid})."
  fi
  rm -f "${pid_file}"
}

stop_by_pid_file "${BACKEND_PID_FILE}" "backend"
stop_by_pid_file "${FRONTEND_PID_FILE}" "frontend"
