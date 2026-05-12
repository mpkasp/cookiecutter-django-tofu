{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
resource "google_artifact_registry_repository" "app" {
  project       = var.project_id
  location      = var.region
  repository_id = var.project_name
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"

  cleanup_policy_dry_run = true

  docker_config {
    immutable_tags = false
  }

  depends_on = [google_project_service.enabled]
}

resource "google_cloud_run_v2_service" "app" {
  project             = var.project_id
  name                = var.project_name
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  template {
    service_account                  = local.compute_sa
    timeout                          = "300s"
    max_instance_request_concurrency = var.max_concurrency

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.project_name}/${var.project_name}:latest"

      ports {
        container_port = 8080
        name           = "http1"
      }

      env {
        name  = "DJANGO_SETTINGS_MODULE"
        value = "{{ cookiecutter.project_slug }}.settings.gcp"
      }

      env {
        name  = "SETTINGS_NAME"
        value = google_secret_manager_secret.django_settings.secret_id
      }

      env {
        name  = "MIGRATE_ON_STARTUP"
        value = "0"
      }

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      startup_probe {
        failure_threshold     = 1
        initial_delay_seconds = 0
        period_seconds        = 240
        timeout_seconds       = 240
        tcp_socket {
          port = 8080
        }
      }

      volume_mounts {
        mount_path = "/cloudsql"
        name       = "cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [local.cloud_sql_connection_name]
      }
    }

    vpc_access {
      egress = "PRIVATE_RANGES_ONLY"
      network_interfaces {
        network    = "default"
        subnetwork = "default"
      }
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      labels,
      template[0].labels,
      template[0].containers[0].image,
      template[0].containers[0].env,
    ]
  }

  depends_on = [
    google_project_service.enabled,
    google_secret_manager_secret_iam_member.compute_sa_settings,
  ]
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  name     = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_domain_mapping" "app" {
  count    = var.domain != "" ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.app.name
  }
}
{% endif -%}
