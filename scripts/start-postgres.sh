#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
  echo "PostgreSQL already responding on localhost:$PG_PORT"
  exit 0
fi
command -v brew >/dev/null || { echo 'Homebrew not found' >&2; exit 1; }
echo "Starting Homebrew $PG_SERVICE ..."
brew services start "$PG_SERVICE"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
    echo "PostgreSQL ready on port $PG_PORT"
    exit 0
  fi
  sleep 2
done
echo "PostgreSQL did not become ready. Check: brew services list" >&2
exit 1
