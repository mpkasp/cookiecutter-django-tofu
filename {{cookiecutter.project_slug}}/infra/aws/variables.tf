{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
variable "region" {
  description = "AWS region."
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
}

variable "domain" {
  description = "Primary domain for this environment. Leave empty to skip custom domain."
  type        = string
  default     = ""
}

variable "media_bucket" {
  description = "S3 bucket name for user uploads. Must be globally unique."
  type        = string
}

variable "is_primary" {
  description = "True for prod. Gates creation of the RDS instance and state bucket."
  type        = bool
  default     = false
}

variable "rds_endpoint" {
  description = "RDS endpoint to reuse from the prod environment. Empty when is_primary=true."
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

variable "django_secret_key" {
  description = "Django SECRET_KEY."
  type        = string
  sensitive   = true
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
  description = "App Runner CPU units."
  type        = string
  default     = "1024"
}

variable "apprunner_memory" {
  description = "App Runner memory in MB."
  type        = string
  default     = "2048"
}

variable "github_repo" {
  description = "GitHub repository for OIDC trust policy (e.g. org/repo)."
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Enable deletion protection on critical resources."
  type        = bool
  default     = true
}
{% endif -%}
