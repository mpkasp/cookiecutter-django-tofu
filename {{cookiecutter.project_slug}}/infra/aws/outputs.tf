{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
output "apprunner_url" {
  description = "App Runner service URL."
  value       = aws_apprunner_service.app.service_url
}

output "apprunner_service_arn" {
  description = "App Runner service ARN."
  value       = aws_apprunner_service.app.arn
}

output "ecr_repository_url" {
  description = "ECR repository URL for Docker images."
  value       = aws_ecr_repository.app.repository_url
}

output "rds_endpoint" {
  description = "RDS endpoint — use as rds_endpoint in dev.tfvars to share this instance."
  value       = local.rds_endpoint
}

output "media_bucket" {
  description = "S3 media bucket name."
  value       = aws_s3_bucket.media.id
}

output "gh_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — set as AWS_ROLE_TO_ASSUME in GH Actions."
  value       = aws_iam_role.gh_actions.arn
}
output "ecs_migrate_cluster" {
  description = "ECS cluster name for migration tasks — set as AWS_ECS_MIGRATE_CLUSTER in GH Actions."
  value       = aws_ecs_cluster.migrate.name
}

output "ecs_migrate_task_definition" {
  description = "ECS task definition family for migrations — set as AWS_ECS_MIGRATE_TASK_DEFINITION in GH Actions."
  value       = aws_ecs_task_definition.migrate.family
}

output "private_subnet_ids" {
  description = "Private subnet IDs (comma-separated) — set as AWS_PRIVATE_SUBNET_IDS in GH Actions."
  value       = join(",", [aws_subnet.private_a.id, aws_subnet.private_b.id])
}

output "app_runner_security_group_id" {
  description = "App Runner security group ID — set as AWS_APP_RUNNER_SG_ID in GH Actions."
  value       = aws_security_group.app_runner.id
}

{% endif -%}
