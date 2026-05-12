{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
# Resources are split across: app.tf, sql.tf, storage.tf, secrets.tf, iam.tf
{% endif -%}
