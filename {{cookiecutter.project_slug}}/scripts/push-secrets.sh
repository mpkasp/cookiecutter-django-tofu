#!/usr/bin/env bash
# Push a local .env.<environment> file to cloud secret manager(s).
#
# Usage:
#   ./scripts/push-secrets.sh dev
#   ./scripts/push-secrets.sh prod
#
# Prerequisites:
{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
#   GCP  — gcloud CLI authenticated: gcloud auth login && gcloud auth application-default login
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
#   AWS  — aws CLI authenticated with the correct account for the target environment
{% endif -%}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  echo "Usage: $0 <dev|prod>" >&2
  exit 1
fi

ENV_FILE="$ROOT/.env.$ENV"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found" >&2
  exit 1
fi

# Extract a single value from the env file (handles optional quotes).
get_var() {
  grep "^${1}=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | sed "s/^['\"]//;s/['\"]$//"
}

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
push_gcp() {
  local project_id
  if [[ "$ENV" == "prod" ]]; then
    project_id="{{ cookiecutter.gcp_project_id }}"
  else
    project_id="{{ cookiecutter.gcp_project_id }}-${ENV}"
  fi

  local secret="{{ cookiecutter.project_slug }}_settings"

  echo "GCP [$ENV]: adding version to secret '$secret' in project '$project_id' ..."
  gcloud secrets versions add "$secret" \
    --data-file="$ENV_FILE" \
    --project="$project_id"
  echo "GCP [$ENV]: done."
}

{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
push_aws() {
  local region="{{ cookiecutter.aws_region }}"
  local project="{{ cookiecutter.project_slug }}"

  local database_url secret_key
  database_url="$(get_var DATABASE_URL)"
  secret_key="$(get_var SECRET_KEY)"

  if [[ -z "$database_url" ]]; then
    echo "Warning: DATABASE_URL not found in $ENV_FILE — skipping that secret." >&2
  else
    echo "AWS [$ENV]: updating ${project}-database-url ..."
    aws secretsmanager put-secret-value \
      --secret-id "${project}-database-url" \
      --secret-string "$database_url" \
      --region "$region"
  fi

  if [[ -z "$secret_key" ]]; then
    echo "Warning: SECRET_KEY not found in $ENV_FILE — skipping that secret." >&2
  else
    echo "AWS [$ENV]: updating ${project}-secret-key ..."
    aws secretsmanager put-secret-value \
      --secret-id "${project}-secret-key" \
      --secret-string "$secret_key" \
      --region "$region"
  fi

  echo "AWS [$ENV]: done."
}

{% endif -%}
{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
push_gcp
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
push_aws
{% endif -%}
