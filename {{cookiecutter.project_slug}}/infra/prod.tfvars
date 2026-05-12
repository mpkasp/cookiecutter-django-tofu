{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
gcp_project_id = "{{ cookiecutter.gcp_project_id }}"
gcp_region     = "{{ cookiecutter.gcp_region }}"
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
aws_region     = "{{ cookiecutter.aws_region }}"
{% endif -%}

domain       = "example.com"
media_bucket = "{{ cookiecutter.project_slug }}-media"
is_primary   = true

# Sensitive vars are passed via GH Actions secrets, not committed here:
# database_password = "..."
# django_secret_key = "..."
