#!/usr/bin/env bash
set -euo pipefail

echo "[entrypoint] init..."

export AIRFLOW_HOME="${AIRFLOW_HOME:-/opt/airflow}"
mkdir -p "${AIRFLOW_HOME}/logs" "${AIRFLOW_HOME}/plugins"

if [[ "${RUN_DB_MIGRATE:-false}" == "true" ]]; then
  echo "[entrypoint] airflow db migrate..."
  airflow db migrate
fi

echo "[entrypoint] args: $*"

# Allow shorthand: "webserver" / "scheduler"
if [[ "${1:-}" == "webserver" || "${1:-}" == "scheduler" ]]; then
  set -- airflow "$@"
fi

exec "$@"
