variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "private_app_subnet_1a_id" {
  type        = string
  description = "The ID of the private app subnet for ECS tasks"
}

variable "private_app_subnet_1c_id" {
  type        = string
  description = "The ID of the private app subnet in 1c"
}

variable "app_sg_id" {
  type        = string
  description = "The ID of the security group for App server / ECS tasks"
}

variable "ecr_api_endpoint_id" {
  type        = string
  description = "The ID of the ECR API VPC Endpoint"
}

variable "ecr_dkr_endpoint_id" {
  type        = string
  description = "The ID of the ECR DKR VPC Endpoint"
}

variable "s3_endpoint_id" {
  type        = string
  description = "The ID of the S3 VPC Endpoint"
}

variable "target_group_arn" {
  type        = string
  description = "ALB Target Group ARN for ECS Service"
}

variable "alb_listener_http_arn" {
  type = string
}