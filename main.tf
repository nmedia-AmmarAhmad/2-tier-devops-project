provider "aws" {
  region = "us-east-1"
}

# 1. ECR Repository (Where your Docker images will live)
resource "aws_ecr_repository" "app_repo" {
  name         = "ammar-app-repo"
  force_delete = true
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "ammar-fargate-cluster"
}

# 3. IAM Role for ECS to work
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ammar-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 4. SNS Topic for Notifications
resource "aws_sns_topic" "updates" {
  name = "ammar-pipeline-alerts"
}

# Add this to the bottom of main.tf
output "sns_topic_arn" {
  description = "The ARN of the SNS topic for GitHub Secrets"
  value       = aws_sns_topic.updates.arn
}

output "ecr_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
