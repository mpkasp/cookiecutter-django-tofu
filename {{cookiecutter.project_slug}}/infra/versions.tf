terraform {
  required_version = ">= 1.6.0"

  required_providers {
{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" %}
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
{% endif %}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" %}
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
{% endif %}
  }
}
