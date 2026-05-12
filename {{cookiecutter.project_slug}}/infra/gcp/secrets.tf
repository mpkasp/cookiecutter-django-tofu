{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
# Secret contents are managed out of band — Terraform only creates the shell.
# Populate before first deploy:
#   gcloud secrets versions add django_settings \
#     --data-file=<populated-.env-file> --project=<project-id>
#
# See .env.example for the full list of required variables.

resource "google_secret_manager_secret" "django_settings" {
  project   = var.project_id
  secret_id = "django_settings"

  replication {
    auto {}
  }

  depends_on = [google_project_service.enabled]
}
{% endif -%}
