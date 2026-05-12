{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
resource "aws_secretsmanager_secret" "database_url" {
  name                    = "${var.project_name}-database-url"
  recovery_window_in_days = var.deletion_protection ? 30 : 0

  tags = { Name = "${var.project_name}-database-url" }
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id     = aws_secretsmanager_secret.database_url.id
  secret_string = "postgres://${var.database_user}:${var.database_password}@${local.rds_endpoint}/${var.database_name}"
}

resource "aws_secretsmanager_secret" "secret_key" {
  name                    = "${var.project_name}-secret-key"
  recovery_window_in_days = var.deletion_protection ? 30 : 0

  tags = { Name = "${var.project_name}-secret-key" }
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = var.django_secret_key
}
{% endif -%}
