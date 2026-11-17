#!/usr/bin/env bash
# macOS-compatible helper functions. Place scripts/ inside your project root.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.env"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing $CONFIG_FILE. Copy scripts/config.env.example to scripts/config.env" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG_FILE"
BACKEND_DIR="$PROJECT_ROOT/${BACKEND_DIR:-apps/backend}"
STOREFRONT_DIR="$PROJECT_ROOT/${STOREFRONT_DIR:-apps/storefront}"
BACKEND_PORT="${BACKEND_PORT:-8218}"
STOREFRONT_PORT="${STOREFRONT_PORT:-9900}"
PG_PORT="${PG_PORT:-5432}"
PG_SERVICE="${PG_SERVICE:-postgresql@16}"
STATE_DIR="$PROJECT_ROOT/.local-services"
mkdir -p "$STATE_DIR"

port_pids() { lsof -nP -tiTCP:"$1" -sTCP:LISTEN 2>/dev/null || true; }
port_free() { [[ -z "$(port_pids "$1")" ]]; }
check_port_free() {
  if ! port_free "$1"; then
    echo "Port $1 already in use; refusing to start $2:" >&2
    lsof -nP -iTCP:"$1" -sTCP:LISTEN >&2 || true
    exit 1
  fi
}
check_dir() { [[ -f "$1/package.json" ]] || { echo "Missing package.json: $1" >&2; exit 1; }; }
# For macOS: recursively signal descendants, then the tracked launcher.
stop_tracked() {
  local name="$1" file="$STATE_DIR/$1.pid" pid child
  if [[ ! -f "$file" ]]; then echo "$name: no tracked PID"; return; fi
  pid="$(cat "$file")"
  if ! kill -0 "$pid" 2>/dev/null; then rm -f "$file"; echo "$name: already stopped"; return; fi
  stop_tree "$pid"
  rm -f "$file"
  echo "$name: stop signal sent (launcher PID $pid)"
}
stop_tree() {
  local parent="$1" child
  while IFS= read -r child; do
    [[ -n "$child" ]] && stop_tree "$child"
  done < <(pgrep -P "$parent" 2>/dev/null || true)
  kill -TERM "$parent" 2>/dev/null || true
}
tracked_running() {
  local file="$STATE_DIR/$1.pid" pid
  [[ -f "$file" ]] || return 1
  pid="$(cat "$file")"
  kill -0 "$pid" 2>/dev/null
}
