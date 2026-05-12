# --- Shared ---

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "{{ cookiecutter.project_slug }}"
}

variable "domain" {
  description = "Primary domain for this environment (e.g. example.com or dev.example.com). Leave empty to skip domain mapping."
  type        = string
  default     = ""
}

variable "media_bucket" {
  description = "Storage bucket name for user uploads. Must be globally unique — set a distinct value per environment in tfvars."
  type        = string
}

variable "is_primary" {
  description = "True for the production environment. Gates creation of the database instance, state bucket, and domain bucket."
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "Allowed CORS origins for the media bucket."
  type        = list(string)
  default     = []
}

variable "database_name" {
  description = "Database name."
  type        = string
  default     = "{{ cookiecutter.database_name }}"
}

variable "database_user" {
  description = "Database user."
  type        = string
  default     = "{{ cookiecutter.project_slug }}"
}

variable "database_password" {
  description = "Database password. Pass via TF_VAR_database_password or -var flag — do not commit to tfvars."
  type        = string
  sensitive   = true
  default     = ""
}

variable "django_secret_key" {
  description = "Django SECRET_KEY. Pass via TF_VAR_django_secret_key or -var flag — do not commit to tfvars."
  type        = string
  sensitive   = true
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection on critical resources."
  type        = bool
  default     = true
}

{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
# --- GCP ---

variable "gcp_project_id" {
  description = "GCP project ID for this environment."
  type        = string
  default     = "{{ cookiecutter.gcp_project_id }}"
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
  default     = "{{ cookiecutter.gcp_region }}"
}

variable "cloud_sql_connection_name" {
  description = "Cloud SQL connection name to reuse from the prod project. Leave empty when is_primary=true."
  type        = string
  default     = ""
}

variable "cloud_sql_project_id" {
  description = "Project that owns the shared Cloud SQL instance. Required when cloud_sql_connection_name is set."
  type        = string
  default     = ""
}

variable "min_instances" {
  description = "Minimum Cloud Run instances (0 = scale to zero)."
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum Cloud Run instances."
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per Cloud Run instance."
  type        = number
  default     = 80
}
{% endif -%}

{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
# --- AWS ---

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "{{ cookiecutter.aws_region }}"
}

variable "rds_endpoint" {
  description = "RDS endpoint to reuse from the prod environment. Leave empty when is_primary=true."
  type        = string
  default     = ""
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS initial allocated storage in GB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS maximum storage for autoscaling in GB."
  type        = number
  default     = 100
}

variable "apprunner_cpu" {
  description = "App Runner CPU units (256, 512, 1024, 2048, 4096)."
  type        = string
  default     = "1024"
}

variable "apprunner_memory" {
  description = "App Runner memory in MB (512, 1024, 2048, 3072, 4096, 6144, 8192, 10240, 12288)."
  type        = string
  default     = "2048"
}

variable "github_repo" {
  description = "GitHub repository for OIDC trust policy (e.g. org/{{ cookiecutter.project_slug }})."
  type        = string
  default     = ""
}
{% endif -%}
