{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
locals {
  # Use the cross-environment endpoint when provided (dev->prod sharing),
  # otherwise the instance created below (prod only).
  rds_endpoint = (
    var.rds_endpoint != ""
    ? var.rds_endpoint
    : try("${one(aws_db_instance.prod[*].address)}:${one(aws_db_instance.prod[*].port)}", "")
  )
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = { Name = "${var.project_name}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}b"

  tags = { Name = "${var.project_name}-private-b" }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = { Name = "${var.project_name}-db" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds"
  description = "RDS PostgreSQL — allow App Runner egress only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-rds" }
}

# RDS is only created in the primary (prod) environment.
resource "aws_db_instance" "prod" {
  count = var.is_primary ? 1 : 0

  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.database_user
  password = var.database_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period = 7
  backup_window           = "07:00-08:00"
  maintenance_window      = "sun:05:00-sun:06:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-final-snapshot"
  deletion_protection       = var.deletion_protection

  tags = { Name = "${var.project_name}-db" }

  lifecycle {
    prevent_destroy = true
  }
}
# Public subnets let ECS Fargate migration tasks reach ECR and AWS APIs
# via the internet gateway, without requiring a NAT gateway.
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.101.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.102.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-b" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = var.project_name }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

{% endif -%}
