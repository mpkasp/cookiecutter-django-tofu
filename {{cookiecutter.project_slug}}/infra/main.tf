{% if cookiecutter.cloud_provider == "gcp" or cookiecutter.cloud_provider == "both" -%}
module "gcp" {
  source = "./gcp"

  project_id                = var.gcp_project_id
  region                    = var.gcp_region
  project_name              = var.project_name
  domain                    = var.domain
  media_bucket              = var.media_bucket
  is_primary                = var.is_primary
  cloud_sql_connection_name = var.cloud_sql_connection_name
  cloud_sql_project_id      = var.cloud_sql_project_id
  cors_origins              = var.cors_origins
  database_name             = var.database_name
  database_user             = var.database_user
  database_password         = var.database_password
  min_instances             = var.min_instances
  max_instances             = var.max_instances
  max_concurrency           = var.max_concurrency
  deletion_protection       = var.deletion_protection
}
{% endif -%}
{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
module "aws" {
  source = "./aws"

  region                   = var.aws_region
  project_name             = var.project_name
  domain                   = var.domain
  media_bucket             = var.media_bucket
  is_primary               = var.is_primary
  rds_endpoint             = var.rds_endpoint
  cors_origins             = var.cors_origins
  database_name            = var.database_name
  database_user            = var.database_user
  database_password        = var.database_password
  django_secret_key        = var.django_secret_key
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  apprunner_cpu            = var.apprunner_cpu
  apprunner_memory         = var.apprunner_memory
  github_repo              = var.github_repo
  deletion_protection      = var.deletion_protection
}
{% endif -%}
