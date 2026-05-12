{% if cookiecutter.use_custom_user_model == "yes" -%}
"""
Users app configuration.
"""
from django.apps import AppConfig


class UsersConfig(AppConfig):
    """Configuration for the users app."""
    default_auto_field = 'django.db.models.BigAutoField'
    name = '{{ cookiecutter.project_slug }}.users'
    verbose_name = 'Users'
{% endif -%}
