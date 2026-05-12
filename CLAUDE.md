# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A **cookiecutter template** that generates production-ready Django 6 projects with integrated OpenTofu infrastructure for GCP (Cloud Run + Cloud SQL) or AWS (App Runner + RDS). The template directory `{{cookiecutter.project_slug}}/` contains Jinja2-style variables throughout — this is intentional and not a bug.

There are two levels to understand:
- **Template repo** (`/`): The cookiecutter template itself. No runnable Django app here.
- **Generated project** (`{{cookiecutter.project_slug}}/`): What users get after running `cookiecutter`. This is where Django commands, tests, and linting apply.

## Generating a Project

```bash
cookiecutter .
# or from GitHub
cookiecutter gh:mpkasp/cookiecutter-django-tofu
```

Template options are defined in `cookiecutter.json`. Conditional file inclusion uses `{% if cookiecutter.use_custom_user_model == 'yes' %}` hooks.

## Generated Project Commands

All commands run from the generated project root using `uv`:

```bash
uv sync --group dev         # Install all dependencies including dev
uv run python manage.py runserver
uv run python manage.py migrate
uv run python manage.py createsuperuser
```

**Testing:**
```bash
uv run pytest                          # All tests with coverage
uv run pytest path/to/test_file.py     # Single file
uv run pytest -v -k "test_name"        # Specific test, verbose
```

**Linting & formatting:**
```bash
uv run ruff check .          # Lint
uv run ruff check --fix .    # Auto-fix
uv run ruff format .         # Format
uv run ruff format --check . # Check formatting only
```

**Docker:**
```bash
docker build -t <project_slug> .
docker run -p 8000:8000 -e DATABASE_URL=... -e SECRET_KEY=... <project_slug>
```

**Infrastructure (OpenTofu):**
```bash
cd infra/gcp   # or infra/aws
tofu init
tofu plan  -var="database_password=..." -var="django_secret_key=..." -var="container_image=..."
tofu apply -var="database_password=..." -var="django_secret_key=..."  -var="container_image=..."
```

## Architecture of the Generated Project

### Settings Hierarchy

```
settings/
  base.py        # Shared: installed apps, auth, logging, static/media, django-environ
  local.py       # Dev: SQLite, dummy cache, no HTTPS
  production.py  # Shared production: security headers, HTTPS enforcement
  gcp.py         # Extends production: Cloud SQL, Cloud Storage, Secret Manager
  aws.py         # Extends production: RDS, S3
```

`DJANGO_SETTINGS_MODULE` selects the environment. Local dev uses `local.py` (SQLite — no PostgreSQL needed). Production images set it to `gcp.py` or `aws.py`.

### Conditional Features (cookiecutter.json)

| Option | Effect |
|---|---|
| `cloud_provider` | Includes `infra/gcp/`, `infra/aws/`, or both; selects CI deploy workflow |
| `use_custom_user_model` | Adds `users/` app with `AbstractUser` subclass |
| `use_email_as_username` | Swaps username for email in custom user model |
| `css_framework` | Adds `django-crispy-forms` + Bootstrap 5 if `bootstrap5` |
| `use_sentry` | Adds Sentry SDK and `SENTRY_DSN` config |
| `email_backend` | Wires Mailgun, SES, or console backend |

### Cloud Infrastructure

**GCP stack:** Cloud Run (app) + Cloud SQL PostgreSQL 16 + Cloud Storage (media) + Secret Manager + VPC + Cloud SQL Proxy sidecar

**AWS stack:** App Runner (app) + RDS PostgreSQL 16 + S3 (media) + Secrets Manager + VPC

Collectstatic and `migrate` run as **one-off jobs** (Cloud Run Job / App Runner task) before each deploy, not as part of the container startup.

### CI/CD (GitHub Actions)

- `ci.yml`: Runs ruff lint + format check + pytest on every push/PR
- `deploy-gcp.yml` / `deploy-aws.yml`: Build → push to Artifact Registry/ECR → run collectstatic job → run migrate job → deploy service

### Key Environment Variables

Local dev uses `.env` (copied from `.env.example`). Production reads from Secret Manager / Secrets Manager.

Essential variables: `SECRET_KEY`, `DEBUG`, `DATABASE_URL`, `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`

Optional: `SENTRY_DSN`, `RECAPTCHA_PUBLIC_KEY/PRIVATE_KEY`, `SOCIAL_AUTH_GOOGLE_OAUTH2_KEY/SECRET`, `MAILGUN_API_KEY`, `GS_BUCKET_NAME` / `AWS_STORAGE_BUCKET_NAME`

### Dependency Management

The generated project uses **uv** with `pyproject.toml`. Dev dependencies are in `[dependency-groups] dev`. Python version is pinned via `.python-version` (currently 3.14).
