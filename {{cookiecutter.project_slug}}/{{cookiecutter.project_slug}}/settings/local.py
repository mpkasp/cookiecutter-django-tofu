"""
Local development settings.
"""
from .base import * # noqa

DEBUG = True
LOCALHOST = True

ALLOWED_HOSTS = ['localhost', '127.0.0.1', '[::1]']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.dummy.DummyCache',
    }
}

# --- Dev Tools (Conditional Loading) ---
# This allows the settings to work in CI environments where dev deps aren't installed.
try:
    import django_extensions  # noqa

    INSTALLED_APPS += ['django_extensions']
except ImportError:
    pass

try:
    import debug_toolbar  # noqa

    INSTALLED_APPS += ['debug_toolbar']
    MIDDLEWARE += ['debug_toolbar.middleware.DebugToolbarMiddleware']
    INTERNAL_IPS = ['127.0.0.1']
except ImportError:
    pass

EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
RECAPTCHA_TESTING = True
