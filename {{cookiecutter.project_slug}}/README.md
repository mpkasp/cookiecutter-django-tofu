# {{ cookiecutter.project_name }}

{{ cookiecutter.description }}

## Tech Stack

- **Django 6.0** with Python {{ cookiecutter.python_version }}
- **PostgreSQL 16** database
- **uv** for dependency management
{% if cookiecutter.cloud_provider == "gcp" -%}
- **GCP**: Cloud Run, Cloud SQL, Cloud Storage
{% elif cookiecutter.cloud_provider == "aws" -%}
- **AWS**: App Runner, RDS, S3
{% else -%}
- **Multi-cloud**: GCP (Cloud Run, Cloud SQL, Cloud Storage) and AWS (App Runner, RDS, S3)
{% endif -%}
{% if cookiecutter.use_sentry == "yes" -%}
- **Sentry** for error tracking
{% endif -%}
{% if cookiecutter.email_backend == "mailgun" -%}
- **Mailgun** for email delivery
{% elif cookiecutter.email_backend == "ses" -%}
- **AWS SES** for email delivery
{% endif -%}

## Local Development Setup

### Prerequisites

- Python {{ cookiecutter.python_version }}+
- [uv](https://github.com/astral-sh/uv)

Local development uses SQLite — no PostgreSQL installation needed.

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd {{ cookiecutter.project_slug }}
```

2. Install dependencies (including dev dependencies):
```bash
uv sync --group dev
```

3. Set up environment variables:
```bash
cp .env.example .env
```
Minimum changes for local development:
- `SECRET_KEY` — run `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"` and paste the result
{% if cookiecutter.email_backend == "mailgun" -%}
- `MAILGUN_API_KEY` and `MAILGUN_SENDER_DOMAIN` — from your Mailgun dashboard
{% elif cookiecutter.email_backend == "ses" -%}
- AWS credentials — configure `~/.aws/credentials` or set `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
{% endif -%}
- `SOCIAL_AUTH_GOOGLE_OAUTH2_KEY` / `_SECRET` — only needed if enabling Google login; leave blank to skip
- Everything else can stay as-is for local SQLite development

4. Create initial migrations and run migrations:
```bash
{% if cookiecutter.use_custom_user_model == "yes" -%}
# Create initial migrations for custom user model
uv run python manage.py makemigrations
{% endif -%}
# Apply migrations
uv run python manage.py migrate
```

6. Create a superuser:
```bash
uv run python manage.py createsuperuser
```

7. Run the development server:
```bash
uv run python manage.py runserver
```

Visit http://localhost:8000 to see your application.

## Running Tests

```bash
# Run all tests with coverage
uv run pytest

# Run specific test file
uv run pytest path/to/test_file.py

# Run with verbose output
uv run pytest -v
```

## Code Quality

```bash
# Run linting
uv run ruff check .

# Auto-fix linting issues
uv run ruff check --fix .

# Check formatting
uv run ruff format --check .

# Apply formatting
uv run ruff format .
```

## Docker

Build and run with Docker:

```bash
# Build image
docker build -t {{ cookiecutter.project_slug }} .

# Run container
docker run -p 8000:8000 \
  -e DATABASE_URL=your_database_url \
  -e SECRET_KEY=your_secret_key \
  {{ cookiecutter.project_slug }}
```

## Deployment

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
### Deploy to GCP

1. Set up GCP project and enable required APIs:
   - Cloud Run API
   - Cloud SQL Admin API
   - Secret Manager API
   - Artifact Registry API

2. Deploy infrastructure with OpenTofu (creates Cloud SQL, GCS bucket, Artifact Registry):
```bash
cd infra/gcp
tofu init
tofu apply \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image={{ cookiecutter.gcp_region }}-docker.pkg.dev/{{ cookiecutter.gcp_project_id }}/{{ cookiecutter.project_slug }}/{{ cookiecutter.project_slug }}:latest"
```

3. Create the Secret Manager secret from your populated `.env`:
```bash
cp .env.example .env
# Fill in .env with real values, then:
gcloud secrets create {{ cookiecutter.project_slug }}_settings \
  --data-file=.env \
  --project={{ cookiecutter.gcp_project_id }}
```

   Key values to set in `.env` before creating the secret:
   - `DB_HOST`: `/cloudsql/{{ cookiecutter.gcp_project_id }}:{{ cookiecutter.gcp_region }}:{{ cookiecutter.database_name }}`
   - `ALLOWED_HOSTS`: your custom domain, e.g. `example.com` (the `*.run.app` URL is added automatically)
   - `CSRF_TRUSTED_ORIGINS`: `https://example.com`
   - `GS_BUCKET_NAME`: `{{ cookiecutter.project_slug }}-media` (must match the bucket Tofu created)

4. Push your first image and deploy via GitHub Actions, or manually:
```bash
gcloud builds submit --tag {{ cookiecutter.gcp_region }}-docker.pkg.dev/{{ cookiecutter.gcp_project_id }}/{{ cookiecutter.project_slug }}/{{ cookiecutter.project_slug }}:latest
```

5. After the first deploy, add `CLOUDRUN_SERVICE_URL` to your secret so the `*.run.app` URL is trusted:
```bash
# Get the URL from Cloud Run console or:
gcloud run services describe {{ cookiecutter.project_slug }} --region {{ cookiecutter.gcp_region }} --format "value(status.url)"
# Then update the secret:
gcloud secrets versions add {{ cookiecutter.project_slug }}_settings --data-file=.env
```

{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
### Deploy to AWS

1. Set up AWS account and configure credentials

2. Create ECR repository:
```bash
aws ecr create-repository --repository-name {{ cookiecutter.project_slug }} --region {{ cookiecutter.aws_region }}
```

3. Build and push Docker image:
```bash
aws ecr get-login-password --region {{ cookiecutter.aws_region }} | docker login --username AWS --password-stdin <account-id>.dkr.ecr.{{ cookiecutter.aws_region }}.amazonaws.com
docker build -t {{ cookiecutter.project_slug }} .
docker tag {{ cookiecutter.project_slug }}:latest <account-id>.dkr.ecr.{{ cookiecutter.aws_region }}.amazonaws.com/{{ cookiecutter.project_slug }}:latest
docker push <account-id>.dkr.ecr.{{ cookiecutter.aws_region }}.amazonaws.com/{{ cookiecutter.project_slug }}:latest
```

4. Deploy infrastructure with OpenTofu:
```bash
cd infra/aws
tofu init
tofu apply \
  -var="database_password=YOUR_DB_PASSWORD" \
  -var="django_secret_key=YOUR_SECRET_KEY" \
  -var="container_image=<account-id>.dkr.ecr.{{ cookiecutter.aws_region }}.amazonaws.com/{{ cookiecutter.project_slug }}:latest"
```

{% endif -%}
## Environment Variables

Key environment variables (see `.env.example` for full list):

- `SECRET_KEY`: Django secret key (required)
- `ALLOWED_HOSTS`: Comma-separated allowed hosts; add your custom domain for production
{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
- `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`: Cloud SQL connection (GCP uses these, not `DATABASE_URL`)
- `CLOUDRUN_SERVICE_URL`: Auto-appended to `ALLOWED_HOSTS`/`CSRF_TRUSTED_ORIGINS`; add after first deploy
- `GS_BUCKET_NAME`: GCS bucket name for static/media files
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
- `DATABASE_URL`: RDS PostgreSQL connection string
- `AWS_STORAGE_BUCKET_NAME`: S3 bucket for static/media files
{% endif %}
{% if cookiecutter.use_sentry == "yes" -%}
- `SENTRY_DSN`: Sentry DSN for error tracking
{% endif -%}
{% if cookiecutter.email_backend == "mailgun" -%}
- `MAILGUN_API_KEY`: Mailgun API key
- `MAILGUN_SENDER_DOMAIN`: Mailgun sender domain
{% elif cookiecutter.email_backend == "ses" -%}
- `AWS_REGION`: AWS region for SES
{% endif -%}

## Project Structure

```
{{ cookiecutter.project_slug }}/
├── .github/workflows/     # CI/CD workflows
├── infra/                 # Infrastructure as code
│   ├── gcp/              # GCP OpenTofu module
│   └── aws/              # AWS OpenTofu module
├── {{ cookiecutter.project_slug }}/
│   ├── settings/         # Django settings
│   │   ├── base.py       # Base settings
│   │   ├── local.py      # Local development
│   │   ├── production.py # Production base
│   │   ├── gcp.py        # GCP-specific
│   │   └── aws.py        # AWS-specific
{% if cookiecutter.use_custom_user_model == "yes" -%}
│   ├── users/            # Custom user model
{% endif -%}
│   ├── wsgi.py
│   ├── asgi.py
│   └── urls.py
├── static/               # Static files
├── templates/            # Django templates
├── Dockerfile
├── pyproject.toml
└── manage.py
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## License

{{ cookiecutter.project_name }} - All rights reserved
