#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
stop_tracked storefront
stop_tracked backend
echo 'PostgreSQL left running. Use scripts/stop-postgres.sh to stop it explicitly.'
