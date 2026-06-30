output "target_group_arn" {
  description = "ALB target group ARN for ECS"
  value       = aws_lb_target_group.webapp.arn
}

output "alb_listener_http_arn" {
  value = aws_lb_listener.http.arn
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the security group attached to the ALB"
}