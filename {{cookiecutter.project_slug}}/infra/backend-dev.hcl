{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
prefix = "{{ cookiecutter.project_slug }}/dev"
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" -%}
key = "{{ cookiecutter.project_slug }}/dev/terraform.tfstate"
{% endif -%}
