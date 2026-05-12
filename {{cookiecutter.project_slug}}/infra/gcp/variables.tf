{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region."
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
}

variable "domain" {
  description = "Primary domain. Leave empty to skip domain mapping."
  type        = string
  default     = ""
}

variable "media_bucket" {
  description = "GCS bucket name for user uploads. Must be globally unique."
  type        = string
}

variable "is_primary" {
  description = "True for prod. Gates creation of Cloud SQL, state bucket, and domain bucket."
  type        = bool
  default     = false
}

variable "cloud_sql_connection_name" {
  description = "Cross-project Cloud SQL connection name. Empty when is_primary=true."
  type        = string
  default     = ""
}

variable "cloud_sql_project_id" {
  description = "Project owning the shared Cloud SQL instance."
  type        = string
  default     = ""
}

variable "cors_origins" {
  description = "Allowed CORS origins for the media bucket."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "database_user" {
  description = "PostgreSQL user."
  type        = string
}

variable "database_password" {
  description = "PostgreSQL password."
  type        = string
  sensitive   = true
}

variable "min_instances" {
  description = "Minimum Cloud Run instances."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum Cloud Run instances."
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per instance."
  type        = number
  default     = 80
}

variable "deletion_protection" {
  description = "Enable deletion protection on critical resources."
  type        = bool
  default     = true
}
{% endif -%}
