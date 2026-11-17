#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
check_dir "$BACKEND_DIR"
check_dir "$STOREFRONT_DIR"
if [[ "${AUTO_START_POSTGRES:-1}" == 1 ]]; then "$SCRIPT_DIR/start-postgres.sh"; fi
if ! pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
  echo "PostgreSQL unavailable on localhost:$PG_PORT" >&2
  exit 1
fi
if tracked_running backend; then
  echo "Backend already started by this manager (PID $(cat "$STATE_DIR/backend.pid"))"
else
  check_port_free "$BACKEND_PORT" 'Medusa backend'
  echo "Starting Medusa backend on port $BACKEND_PORT..."
  ( cd "$BACKEND_DIR" && PORT="$BACKEND_PORT" bash -lc "${BACKEND_START_COMMAND:-npm run dev}" ) >"$STATE_DIR/backend.log" 2>&1 &
  echo "$!" > "$STATE_DIR/backend.pid"
fi
if tracked_running storefront; then
  echo "Storefront already started by this manager (PID $(cat "$STATE_DIR/storefront.pid"))"
else
  check_port_free "$STOREFRONT_PORT" 'Next.js storefront'
  echo "Starting storefront on port $STOREFRONT_PORT..."
  ( cd "$STOREFRONT_DIR" && PORT="$STOREFRONT_PORT" NEXT_PUBLIC_MEDUSA_BACKEND_URL="http://localhost:$BACKEND_PORT" bash -lc "${STOREFRONT_START_COMMAND:-npx --no-install next dev -p 9900}" ) >"$STATE_DIR/storefront.log" 2>&1 &
  echo "$!" > "$STATE_DIR/storefront.pid"
fi
printf '\nBackend/Admin: http://localhost:%s  /  http://localhost:%s/app\nStorefront: http://localhost:%s\nLogs: %s/{backend,storefront}.log\n' "$BACKEND_PORT" "$BACKEND_PORT" "$STOREFRONT_PORT" "$STATE_DIR"
echo 'Checking services (startup can take a little while)...'
for i in 1 2 3 4 5 6 7 8; do
  if curl -fsS --max-time 2 "http://localhost:$BACKEND_PORT/health" >/dev/null 2>&1 && curl -sS --max-time 2 -o /dev/null "http://localhost:$STOREFRONT_PORT" 2>/dev/null; then break; fi
  sleep 2
done
"$SCRIPT_DIR/status.sh"
