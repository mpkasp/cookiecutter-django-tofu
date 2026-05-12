{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
output "cloud_run_url" {
  description = "Cloud Run service URL."
  value       = google_cloud_run_v2_service.app.uri
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (project:region:instance)."
  value       = local.cloud_sql_connection_name
}

output "artifact_registry_url" {
  description = "Artifact Registry Docker repository URL."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}

output "media_bucket" {
  description = "GCS media bucket name."
  value       = google_storage_bucket.media.name
}

output "gh_actions_service_account_email" {
  description = "GitHub Actions WIF service account email."
  value       = google_service_account.gh_actions.email
}
{% endif -%}
