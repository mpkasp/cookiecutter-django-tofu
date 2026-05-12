{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
gcp_project_id = "{{ cookiecutter.gcp_project_id }}-dev"
gcp_region     = "{{ cookiecutter.gcp_region }}"
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
aws_region     = "{{ cookiecutter.aws_region }}"
{% endif -%}

domain       = "dev.example.com"
media_bucket = "{{ cookiecutter.project_slug }}-dev-media"
is_primary   = false

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
# Uncomment to share prod's Cloud SQL instance:
# cloud_sql_connection_name = "<prod-project>:<region>:<instance>"
# cloud_sql_project_id      = "<prod-project-id>"
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
# Uncomment to share prod's RDS instance:
# rds_endpoint = "<prod-rds-endpoint>"
{% endif -%}

# Sensitive vars are passed via GH Actions secrets, not committed here:
# database_password = "..."
# django_secret_key = "..."
