# ===================================================
# Target Group
# ===================================================
output "target_group_arn" {
  description = "ALB target group ARN for ECS"
  value       = aws_lb_target_group.webapp.arn
}

# ===================================================
# Listener
# ===================================================
output "alb_listener_http_arn" {
  value = aws_lb_listener.http.arn
}
