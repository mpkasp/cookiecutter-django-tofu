#!/bin/bash
set -e

# Run database migrations and cache table creation on startup.
# GCP uses Cloud Run Jobs for these steps; AWS uses an ECS Fargate task.
# Set MIGRATE_ON_STARTUP=1 only when running outside the normal deploy pipeline.
if [ "${MIGRATE_ON_STARTUP:-0}" = "1" ]; then
  python manage.py migrate --noinput
  python manage.py createcachetable {{ cookiecutter.project_slug }}_cache
fi

exec gunicorn --bind 0.0.0.0:${PORT:-8080} --workers 1 --threads 8 --timeout 0 {{ cookiecutter.project_slug }}.wsgi:application
