# modules/ecs/outputs.tf

output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "The URL of the ECR repository"
}

output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}