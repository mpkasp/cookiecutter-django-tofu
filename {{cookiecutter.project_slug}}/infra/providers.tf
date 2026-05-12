{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
provider "aws" {
  region = var.aws_region
}
{% endif -%}
