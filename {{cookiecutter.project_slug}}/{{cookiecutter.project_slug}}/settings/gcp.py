"""
Google Cloud Platform settings for Cloud Run environments.
"""
import os
from .production import * # noqa

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
logger.info("Using Cloud-based database configuration.")

# Cloud SQL connection mapped to env vars
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': env.str("DB_HOST", ""),
        'NAME': env.str("DB_NAME", ""),
        'USER': env.str("DB_USER", ""),
        'PASSWORD': env.str("DB_PASSWORD", ""),
    },
    'readonly': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': env.str("DB_HOST", ""),
        'NAME': env.str("DB_NAME", ""),
        'USER': env.str("DB_READONLY_USER", ""),
        'PASSWORD': env.str("DB_READONLY_PASSWORD", ""),
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
        'LOCATION': '{{ cookiecutter.project_slug }}_cache',
        'OPTIONS': {
            'MAX_ENTRIES': 5000
        }
    }
}

# Override local storage with Google Cloud Storage
GS_BUCKET_NAME = env.str("GS_BUCKET_NAME", None)
GS_DEFAULT_ACL = env.str("GS_DEFAULT_ACL", 'publicRead')

if GS_BUCKET_NAME:
    GCS_STORAGE_BACKEND = "storages.backends.gcloud.GoogleCloudStorage"
    STORAGES["default"] = {
        "BACKEND": GCS_STORAGE_BACKEND,
        "OPTIONS": {"bucket_name": GS_BUCKET_NAME},
    }
    STORAGES["staticfiles"] = {
        "BACKEND": GCS_STORAGE_BACKEND,
        "OPTIONS": {"bucket_name": GS_BUCKET_NAME},
    }
    MEDIA_URL = None
    GS_QUERYSTRING_AUTH = False
    GS_DEFAULT_ACL = 'publicRead'

# Cloud Run sets PORT environment variable
CLOUDRUN_SERVICE_URL = env("CLOUDRUN_SERVICE_URL", default=None)

if CLOUDRUN_SERVICE_URL:
    logger.info(f'Cloud Run Service URL detected: {CLOUDRUN_SERVICE_URL}')
    parsed_url = urlparse(CLOUDRUN_SERVICE_URL)
    ALLOWED_HOSTS.append(parsed_url.netloc)
    CSRF_TRUSTED_ORIGINS.append(CLOUDRUN_SERVICE_URL)

PORT = int(os.environ.get('PORT', 8000))
{% endif -%}