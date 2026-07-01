# modules/ecs/outputs.tf

output "repository_url" {
  value = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}