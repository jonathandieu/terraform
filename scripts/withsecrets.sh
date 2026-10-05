#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_TPL="$SCRIPT_DIR/../.env.tpl"

if [[ $# -eq 0 ]]; then
  echo "Usage: withsecrets.sh <command> [args...]" >&2
  exit 1
fi

exec op run --env-file="$ENV_TPL" -- "$@"
