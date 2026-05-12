{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
data "google_project" "this" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.this.number
  compute_sa     = "${data.google_project.this.number}-compute@developer.gserviceaccount.com"

  enabled_apis = toset([
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "vpcaccess.googleapis.com",
  ])
}

resource "google_project_service" "enabled" {
  for_each = local.enabled_apis

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Service account used by GitHub Actions via Workload Identity Federation.
resource "google_service_account" "gh_actions" {
  project      = var.project_id
  account_id   = "gh-actions"
  display_name = "gh-actions"
  description  = "GitHub Actions service account for Workload Identity Federation."
}

# Grant the compute SA (used by Cloud Run) access to the django_settings secret.
resource "google_secret_manager_secret_iam_member" "compute_sa_settings" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.django_settings.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${local.compute_sa}"
}

resource "google_storage_bucket_iam_member" "compute_sa_storage" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${local.compute_sa}"
}
{% endif -%}
