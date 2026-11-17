#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
if [[ -t 1 && "${NO_COLOR:-}" == "" ]]; then
  GREEN=$'\033[32m'; RED=$'\033[31m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else GREEN=''; RED=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''; fi
http_code() { curl -sS -L --max-time 3 -o /dev/null -w '%{http_code}' "$1" 2>/dev/null || true; }
service() {
  local label="$1" port="$2" url="$3" kind="$4" pids code
  pids="$(port_pids "$port" | tr '\n' ' ')"
  if [[ -z "$pids" ]]; then
    printf '  %-15s %sSTOPPED%s   port %-5s %s\n' "$label" "$RED" "$RESET" "$port" "$url"
  elif [[ "$kind" == http ]]; then
    code="$(http_code "$url")"
    if [[ "$code" =~ ^[1-4][0-9][0-9]$ ]]; then
      printf '  %-15s %sREADY%s     port %-5s HTTP %-3s  %s\n' "$label" "$GREEN" "$RESET" "$port" "$code" "$url"
    else
      printf '  %-15s %sSTARTING/ERROR%s port %-5s HTTP %-3s  %s\n' "$label" "$YELLOW" "$RESET" "$port" "${code:----}" "$url"
    fi
  else
    printf '  %-15s %sLISTENING%s port %-5s PID(s) %s\n' "$label" "$GREEN" "$RESET" "$port" "$pids"
  fi
}
printf '\n%sMedusa local services%s\n' "$BOLD" "$RESET"
printf '%s────────────────────────────────────────────────────────────────────────────%s\n' "$CYAN" "$RESET"
if pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
  printf '  %-15s %sREADY%s     port %s\n' 'PostgreSQL' "$GREEN" "$RESET" "$PG_PORT"
else
  printf '  %-15s %sSTOPPED%s   port %s\n' 'PostgreSQL' "$RED" "$RESET" "$PG_PORT"
fi
service 'Backend API' "$BACKEND_PORT" "http://localhost:$BACKEND_PORT/health" http
service 'Medusa Admin' "$BACKEND_PORT" "http://localhost:$BACKEND_PORT/app" http
service 'Storefront' "$STOREFRONT_PORT" "http://localhost:$STOREFRONT_PORT" http
printf '\n%sOther services (left untouched)%s\n' "$BOLD" "$RESET"
service 'PHP / IDE' 9000 '-' tcp
printf '\n%sManaged processes%s\n' "$BOLD" "$RESET"
for name in backend storefront; do
  if tracked_running "$name"; then printf '  %-15s PID %s\n' "$name" "$(cat "$STATE_DIR/$name.pid")";
  else printf '  %-15s not running/tracked\n' "$name"; fi
done
printf '\n%sClickable links (Cmd+click in iTerm2)%s\n' "$BOLD" "$RESET"
printf '  %shttp://localhost:%s/app%s  Admin\n' "$CYAN" "$BACKEND_PORT" "$RESET"
printf '  %shttp://localhost:%s%s      Storefront\n' "$CYAN" "$STOREFRONT_PORT" "$RESET"
printf '  %shttp://localhost:%s/health%s  Backend health\n' "$CYAN" "$BACKEND_PORT" "$RESET"
printf '\n%sLogs%s\n' "$BOLD" "$RESET"
printf '  tail -f "%s/backend.log"\n  tail -f "%s/storefront.log"\n' "$STATE_DIR" "$STATE_DIR"
printf '\n%sPostgreSQL login%s\n' "$BOLD" "$RESET"
printf '  psql -h localhost -p %s -U medusa -d medusa-medusa-learning\n\n' "$PG_PORT"
