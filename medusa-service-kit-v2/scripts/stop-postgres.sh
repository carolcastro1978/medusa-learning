#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
echo "Stopping Homebrew $PG_SERVICE (may affect other projects using it)..."
brew services stop "$PG_SERVICE"
