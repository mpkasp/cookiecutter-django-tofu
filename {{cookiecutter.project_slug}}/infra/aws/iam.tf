{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
# --- App Runner instance role (runtime permissions) ---

resource "aws_iam_role" "apprunner" {
  name = "${var.project_name}-apprunner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "tasks.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apprunner" {
  name = "${var.project_name}-apprunner"
  role = aws_iam_role.apprunner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.database_url.arn,
          aws_secretsmanager_secret.secret_key.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.media.arn, "${aws_s3_bucket.media.arn}/*"]
      },
    ]
  })
}

# --- App Runner ECR access role (image pull) ---

resource "aws_iam_role" "apprunner_ecr" {
  name = "${var.project_name}-apprunner-ecr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr" {
  role       = aws_iam_role.apprunner_ecr.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# --- ECS task execution role (for migration Fargate tasks) ---
# Allows ECS to pull the container image and fetch secrets on behalf of the task.

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project_name}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        aws_secretsmanager_secret.database_url.arn,
        aws_secretsmanager_secret.secret_key.arn,
      ]
    }]
  })
}

# --- GitHub Actions OIDC ---
# Allows GitHub Actions to assume the gh_actions role without long-lived credentials.
# If this provider already exists in your account (from another project), import it:
#   tofu import aws_iam_openid_connect_provider.github <existing-arn>
#
# AWS automatically validates OIDC tokens from known providers (including GitHub Actions),
# so the thumbprint list is not actually verified. A placeholder value is required by the
# provider but is ignored by AWS for token.actions.githubusercontent.com.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"]
}

resource "aws_iam_role" "gh_actions" {
  name = "${var.project_name}-gh-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = (
            var.github_repo != "" ? "repo:${var.github_repo}:*" : "*"
          )
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "gh_actions" {
  name = "${var.project_name}-gh-actions"
  role = aws_iam_role.gh_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["apprunner:StartDeployment", "apprunner:DescribeService", "apprunner:ListServices"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ec2:DescribeSubnets", "ec2:DescribeSecurityGroups"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:RunTask", "ecs:DescribeTasks", "ecs:StopTask"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = [aws_iam_role.ecs_execution.arn, aws_iam_role.apprunner.arn]
      },
    ]
  })
}
{% endif -%}
