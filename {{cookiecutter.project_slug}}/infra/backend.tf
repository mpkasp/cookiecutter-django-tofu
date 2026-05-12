{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
terraform {
  backend "gcs" {
    bucket = "{{ cookiecutter.project_slug }}-tofu-state"
    # prefix supplied at init time:
    #   tofu init -backend-config=backend-prod.hcl
    #   tofu init -backend-config=backend-dev.hcl
    #
    # Bootstrap: the state bucket is created by the first prod apply (is_primary=true).
    # Run the first apply with a local backend, then migrate:
    #   tofu init -migrate-state -backend-config=backend-prod.hcl
  }
}
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" -%}
terraform {
  backend "s3" {
    bucket = "{{ cookiecutter.project_slug }}-tofu-state"
    region = "{{ cookiecutter.aws_region }}"
    # key supplied at init time:
    #   tofu init -backend-config=backend-prod.hcl
    #   tofu init -backend-config=backend-dev.hcl
    #
    # Bootstrap: create the S3 bucket manually once, then run:
    #   tofu init -backend-config=backend-prod.hcl
  }
}
{% endif -%}
