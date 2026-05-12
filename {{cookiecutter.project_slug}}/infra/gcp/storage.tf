{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
resource "google_storage_bucket" "media" {
  project                  = var.project_id
  name                     = var.media_bucket
  location                 = "US"
  storage_class            = "STANDARD"
  force_destroy            = false
  public_access_prevention = "inherited"

  cors {
    max_age_seconds = 3600
    method          = ["GET", "HEAD", "OPTIONS"]
    origin          = length(var.cors_origins) > 0 ? var.cors_origins : ["*"]
    response_header = ["Content-Type", "x-goog-resumable"]
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }
}

# Tofu state bucket — only created in prod (is_primary=true).
# Used after bootstrapping to store remote state.
resource "google_storage_bucket" "tofu_state" {
  count = var.is_primary ? 1 : 0

  project                     = var.project_id
  name                        = "{{ cookiecutter.project_slug }}-tofu-state"
  location                    = upper(var.region)
  storage_class               = "STANDARD"
  force_destroy               = false
  public_access_prevention    = "inherited"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800
  }

  lifecycle {
    prevent_destroy = true
  }
}
{% endif -%}
