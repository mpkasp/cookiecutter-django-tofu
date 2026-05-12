import io
import logging
import os
from pathlib import Path
from urllib.parse import urlparse

import environ
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
import google.auth
import google.auth.exceptions
from google.cloud import secretmanager
{% endif -%}

# --- Basic Setup and Environment Loading ---
logger = logging.getLogger(__name__)
BASE_DIR = Path(__file__).resolve().parent.parent.parent

# Setup django-environ
env = environ.Env()
env_file = BASE_DIR / '.env'

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
# Determine project ID from Google Cloud credentials
project_id = None
try:
    _, os.environ['GOOGLE_CLOUD_PROJECT'] = google.auth.default()
    project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
    logger.info(f'Project ID: {project_id}')
except (google.auth.exceptions.DefaultCredentialsError,
        google.auth.exceptions.RefreshError,
        google.auth.exceptions.TransportError,
        TypeError) as e:
    logger.warning(f'Could not determine Google Cloud Project ID: {e}')

# Load environment variables
if os.path.isfile(env_file):
    logger.info(f'Found local .env file: {env_file}')
    env.read_env(env_file)
elif project_id:
    client = secretmanager.SecretManagerServiceClient()
    settings_name = os.environ.get("SETTINGS_NAME", "{{ cookiecutter.project_slug }}_settings")
    logger.info(f'Fetching secrets from {settings_name} in project {project_id}')
    try:
        name = f"projects/{project_id}/secrets/{settings_name}/versions/latest"
        payload = client.access_secret_version(name=name).payload.data.decode("UTF-8")
        env.read_env(io.StringIO(payload))
    except Exception as e:
        logger.error(f"Error accessing secret manager: {e}")
        raise
else:
    logger.warning("No local .env or GOOGLE_CLOUD_PROJECT detected. Running with minimal environment.")
{% else %}
if os.path.isfile(env_file):
    env.read_env(env_file)
{% endif -%}

# --- Core Django Settings and Secret Variables ---
DEBUG = env.bool("DEBUG", False)
ENVIRONMENT = env.str("ENVIRONMENT", "unset")
GITHUB_SHA = env.str("GITHUB_SHA", env.str("GITHUB_SHORT_SHA", "unknown"))
LOCALHOST = env.bool("LOCALHOST", False)
SECRET_KEY = env.str("SECRET_KEY")

DOMAIN = env.str("DOMAIN", 'localhost:8000')
ROOT_DOMAIN = f'https://{DOMAIN}' if not LOCALHOST else f'http://{DOMAIN}'

ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=[])
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])

_SCHEMES = ("http://", "https://")
_normalized = []
for origin in CSRF_TRUSTED_ORIGINS:
    if not origin:
        continue
    o = origin.strip()
    if not o.startswith(_SCHEMES):
        o = f"https://{o}"
    _normalized.append(o)
CSRF_TRUSTED_ORIGINS = list(dict.fromkeys(_normalized))

if DEBUG or LOCALHOST:
    if "http://localhost:8000" not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append("http://localhost:8000")

# --- Application Configuration ---
INSTALLED_APPS = [
    '{{ cookiecutter.project_slug }}',
    
    # Django contrib apps
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.sitemaps',

    # Third-party apps
    'storages',
    'anymail',
    'social_django',
    'django_recaptcha',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'social_django.middleware.SocialAuthExceptionMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = '{{ cookiecutter.project_slug }}.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / '{{ cookiecutter.project_slug }}' / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'django.template.context_processors.media',
                'social_django.context_processors.backends',
                'social_django.context_processors.login_redirect',
            ],
        },
    },
]

WSGI_APPLICATION = '{{ cookiecutter.project_slug }}.wsgi.application'

# --- Authentication and Authorization ---
AUTHENTICATION_BACKENDS = [
    'social_core.backends.google.GoogleOAuth2',
    'django.contrib.auth.backends.ModelBackend',
]

SOCIAL_AUTH_GOOGLE_OAUTH2_KEY = env.str("SOCIAL_AUTH_GOOGLE_OAUTH2_KEY", default="")
SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET = env.str("SOCIAL_AUTH_GOOGLE_OAUTH2_SECRET", default="")
SOCIAL_AUTH_GOOGLE_OAUTH2_SCOPE = ['email', 'profile', 'https://www.googleapis.com/auth/drive']
SOCIAL_AUTH_GOOGLE_OAUTH2_AUTH_EXTRA_ARGUMENTS = {
    'access_type': 'offline',
    'approval_prompt': 'force'
}
SOCIAL_AUTH_REDIRECT_IS_HTTPS = not DEBUG
SOCIAL_AUTH_LOGIN_REDIRECT_URL = '/'
SOCIAL_AUTH_DISCONNECT_REDIRECT_URL = '/'
SOCIAL_AUTH_LOGIN_ERROR_URL = '/'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LOGIN_URL = '/login/'
LOGOUT_URL = '/logout/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/'

{% if cookiecutter.use_custom_user_model == "yes" -%}
AUTH_USER_MODEL = 'users.User'
{% endif -%}

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# --- Static and Media Files (Storage) ---
STATIC_ROOT = BASE_DIR / "static"
MEDIA_ROOT = BASE_DIR / "media"
STATIC_URL = "/static/"
MEDIA_URL = "/media/"

# Default to local file system for base/local development
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}

# --- Email and Internationalization ---
MAILGUN_API_KEY = env.str("MAILGUN_API_KEY", "")
if MAILGUN_API_KEY:
    MAILGUN_SENDER_DOMAIN = os.environ.get('MAILGUN_SENDER_DOMAIN', f'mg.{DOMAIN}')
    ANYMAIL = {
        "MAILGUN_API_KEY": MAILGUN_API_KEY,
        "MAILGUN_SENDER_DOMAIN": MAILGUN_SENDER_DOMAIN,
    }
    EMAIL_BACKEND = "anymail.backends.mailgun.EmailBackend"

DEFAULT_FROM_EMAIL = f"{{ cookiecutter.project_name }} <info@{DOMAIN}>"
SERVER_EMAIL = f"info@{DOMAIN}"
NO_REPLY_EMAIL = f"{{ cookiecutter.project_name }} <no-reply@{DOMAIN}>"
MAILGUN_DAILY_LIMIT = env.int("MAILGUN_DAILY_LIMIT", default=80)

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# --- Logging ---
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'timestamp': {
            'format': "[%(asctime)s] %(levelname)s [%(name)s.%(funcName)s:%(lineno)d] %(message)s"
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'timestamp',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}

# --- Third-party Specific Settings ---
RECAPTCHA_PUBLIC_KEY = env.str("RECAPTCHA_PUBLIC_KEY", default="")
RECAPTCHA_PRIVATE_KEY = env.str("RECAPTCHA_PRIVATE_KEY", default="")

SENTRY_DSN = env.str("SENTRY_DSN", "")
if not LOCALHOST and SENTRY_DSN and SENTRY_DSN != 'supersecretdsn':
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration(
            middleware_spans=True,
            cache_spans=True,
            signals_spans=True,
        )],
        release=GITHUB_SHA,
        environment=ENVIRONMENT,
        send_default_pii=True,
        traces_sample_rate=1.0 if DEBUG else 0.1,
        profiles_sample_rate=1.0 if DEBUG else 0.1,
    )