{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"
  force_delete         = !var.deletion_protection

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = var.project_name }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# --- App Runner VPC connectivity ---
# Allows App Runner instances to reach the private RDS instance.
# egress_type = "DEFAULT" means internet-bound traffic still exits via App Runner's
# managed infrastructure (no NAT gateway needed for S3, Secrets Manager, etc.).

resource "aws_security_group" "app_runner" {
  name        = "${var.project_name}-app-runner"
  description = "App Runner VPC connector outbound"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-app-runner" }
}

resource "aws_apprunner_vpc_connector" "main" {
  vpc_connector_name = var.project_name
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_groups    = [aws_security_group.app_runner.id]

  tags = { Name = var.project_name }
}

resource "aws_apprunner_service" "app" {
  service_name = var.project_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr.arn
    }

    image_repository {
      image_identifier      = "${aws_ecr_repository.app.repository_url}:latest"
      image_repository_type = "ECR"

      image_configuration {
        port = "8080"

        runtime_environment_variables = {
          DJANGO_SETTINGS_MODULE  = "{{ cookiecutter.project_slug }}.settings.aws"
          ALLOWED_HOSTS           = var.domain != "" ? var.domain : "*"
          AWS_REGION              = var.region
          AWS_STORAGE_BUCKET_NAME = aws_s3_bucket.media.id
          MIGRATE_ON_STARTUP      = "0"
        }

        runtime_environment_secrets = {
          DATABASE_URL = aws_secretsmanager_secret.database_url.arn
          SECRET_KEY   = aws_secretsmanager_secret.secret_key.arn
        }
      }
    }

    auto_deployments_enabled = false
  }

  network_configuration {
    egress_configuration {
      egress_type       = "DEFAULT"
      vpc_connector_arn = aws_apprunner_vpc_connector.main.arn
    }
  }

  instance_configuration {
    cpu               = var.apprunner_cpu
    memory            = var.apprunner_memory
    instance_role_arn = aws_iam_role.apprunner.arn
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = { Name = var.project_name }

  lifecycle {
    ignore_changes = [
      source_configuration[0].image_repository[0].image_identifier,
      source_configuration[0].image_repository[0].image_configuration[0].runtime_environment_variables,
      source_configuration[0].image_repository[0].image_configuration[0].runtime_environment_secrets,
    ]
  }
}

# --- ECS Fargate cluster and task for database migrations ---
# Migrations run as a one-off Fargate task in the deploy pipeline (before App Runner
# is updated), so the database schema is always ready before new code starts serving.
# The task runs in public subnets with a public IP so it can reach ECR and AWS APIs
# without a NAT gateway.

resource "aws_ecs_cluster" "migrate" {
  name = "${var.project_name}-migrate"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = { Name = "${var.project_name}-migrate" }
}

resource "aws_ecs_task_definition" "migrate" {
  family                   = "${var.project_name}-migrate"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.apprunner.arn

  container_definitions = jsonencode([{
    name    = "migrate"
    image   = "${aws_ecr_repository.app.repository_url}:latest"
    command = ["python", "manage.py", "migrate", "--noinput"]
    environment = [
      { name = "DJANGO_SETTINGS_MODULE",  value = "{{ cookiecutter.project_slug }}.settings.aws" },
      { name = "AWS_REGION",              value = var.region },
      { name = "AWS_STORAGE_BUCKET_NAME", value = aws_s3_bucket.media.id },
    ]
    secrets = [
      { name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.database_url.arn },
      { name = "SECRET_KEY",   valueFrom = aws_secretsmanager_secret.secret_key.arn },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.project_name}/migrate"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "migrate"
        "awslogs-create-group"  = "true"
      }
    }
  }])

  tags = { Name = "${var.project_name}-migrate" }
}
{% endif -%}
