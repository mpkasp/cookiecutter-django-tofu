{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
locals {
  # Use the cross-project connection name when provided (dev->prod sharing),
  # otherwise the instance created below (prod only).
  cloud_sql_connection_name = (
    var.cloud_sql_connection_name != ""
    ? var.cloud_sql_connection_name
    : one(google_sql_database_instance.prod[*].connection_name)
  )
}

# Cloud SQL is only created in the primary (prod) environment.
resource "google_sql_database_instance" "prod" {
  count = var.is_primary ? 1 : 0

  project          = var.project_id
  name             = "${var.project_name}-db"
  region           = var.region
  database_version = "POSTGRES_16"

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_SSD"
    disk_size         = 10
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      location                       = "us"
      start_time                     = "07:00"
      transaction_log_retention_days = 7
      point_in_time_recovery_enabled = true

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = "projects/${var.project_id}/global/networks/default"
    }

    maintenance_window {
      day  = 7
      hour = 5
    }
  }

  deletion_protection = true

  depends_on = [google_project_service.enabled]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_sql_database" "main" {
  count    = var.is_primary ? 1 : 0
  project  = var.project_id
  name     = var.database_name
  instance = one(google_sql_database_instance.prod[*].name)
}

resource "google_sql_user" "main" {
  count    = var.is_primary ? 1 : 0
  project  = var.project_id
  name     = var.database_user
  instance = one(google_sql_database_instance.prod[*].name)
  password = var.database_password
}

# Grant the dev project's compute SA access to the prod Cloud SQL instance.
# Requires the Tofu SA to have roles/resourcemanager.projectIamAdmin on the prod
# project — grant this once manually before applying the dev config.
resource "google_project_iam_member" "cross_project_sql_client" {
  count = !var.is_primary && var.cloud_sql_project_id != "" ? 1 : 0

  project = var.cloud_sql_project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${local.compute_sa}"

  depends_on = [google_project_service.enabled]
}
{% endif -%}
