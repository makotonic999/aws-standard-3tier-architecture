# modules/monitoring/variables.tf

variable "notification_email" {
  description = "Email address for CloudWatch Alarm notifications"
  type        = string
}

# ALB
variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  type        = string
}

# ECS
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
}

# RDS
variable "db_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
}
