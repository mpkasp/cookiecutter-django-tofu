{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
# Resources are split across: app.tf, rds.tf, storage.tf, secrets.tf, iam.tf
{% endif -%}
