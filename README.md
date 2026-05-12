# Django + OpenTofu Cookiecutter Template

A modern, production-ready Django 6 project template with cloud infrastructure as code using OpenTofu (Terraform fork).

## Features

- **Django 6** with Python 3.14
- **uv** for fast dependency management
- **AlpineJS** and **HTMX** for modern frontend interactivity
- **CSS Framework** options:
  - **Bootstrap 5** with django-crispy-forms and crispy-bootstrap5
  - **None** for custom styling
- **OpenTofu** infrastructure modules for:
  - **GCP**: Cloud Run, Cloud SQL PostgreSQL, Cloud Storage, Secret Manager
  - **AWS**: App Runner, RDS PostgreSQL, S3, Secrets Manager
- **Custom User Model** (optional) with migration guide for existing projects
- **Email backends**: Mailgun, AWS SES, or console
- **Sentry** integration for error tracking
- **GitHub Actions** CI/CD workflows
- **Docker** with multi-stage builds optimized for uv
- **Ruff** for linting and formatting
- **pytest** with coverage reporting

## Prerequisites

- Python 3.14+
- [uv](https://github.com/astral-sh/uv) installed globally
- [cruft](https://cruft.github.io/cruft/) for template management
- [PostgreSQL](https://www.postgresql.org/download/) for local development

## Installation

Install cruft globally using uv:

```bash
uv tool install cruft
```

## Usage

### Create a New Project

```bash
cruft create https://github.com/mpkasp/cookiecutter-django-tofu
```

Answer the prompts:
- **project_name**: Your project name (e.g., "My Django Project")
- **cloud_provider**: Choose `gcp`, `aws`, or `both`
- **use_custom_user_model**: Choose `yes` to include custom user model
- **css_framework**: Choose `bootstrap5` for Bootstrap 5 with crispy-forms, or `none` for no CSS framework
- **use_sentry**: Choose `yes` to enable Sentry integration
- **email_backend**: Choose `mailgun`, `ses`, or `console`

### Local Development

```bash
cd your_project_name

# Install dependencies (including dev dependencies)
uv sync --group dev

# Copy environment file
cp .env.example .env

# Edit .env with your local settings

# Create initial migrations (if using custom user model)
uv run python manage.py makemigrations

# Run migrations
uv run python manage.py migrate

# Create superuser
uv run python manage.py createsuperuser

# Run development server
uv run python manage.py runserver
```

### Running Tests

```bash
# Run tests with coverage
uv run pytest

# Run linting
uv run ruff check .

# Run formatting
uv run ruff format .
```

### Deploy Infrastructure

#### GCP Deployment

```bash
cd infra/gcp

# Initialize OpenTofu
tofu init

# Plan infrastructure
tofu plan \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image=YOUR_IMAGE_URL"

# Apply infrastructure
tofu apply \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image=YOUR_IMAGE_URL"
```

#### AWS Deployment

```bash
cd infra/aws

# Initialize OpenTofu
tofu init

# Plan infrastructure
tofu plan \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image=YOUR_ECR_IMAGE_URL"

# Apply infrastructure
tofu apply \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image=YOUR_ECR_IMAGE_URL"
```

## Updating Your Project from Template

When the template is updated, you can sync your project:

```bash
cd your_project_name
cruft update
```

Cruft will show you the changes and allow you to merge them into your project.

## Project Structure

```
your_project/
├── .github/
│   └── workflows/          # CI/CD workflows
├── infra/
│   ├── gcp/               # GCP OpenTofu module
│   └── aws/               # AWS OpenTofu module
├── your_project/
│   ├── settings/          # Django settings (base, local, production, gcp, aws)
│   ├── users/             # Custom user model (optional)
│   ├── wsgi.py
│   ├── asgi.py
│   └── urls.py
├── Dockerfile             # Multi-stage Docker build with uv
├── pyproject.toml         # Project dependencies and configuration
├── manage.py
└── .env.example
```

## Custom User Model Migration

If you want to apply the custom user model to an existing project, see `MIGRATION_GUIDE.md` in your generated project.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License
