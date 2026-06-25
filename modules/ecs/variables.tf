variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "private_app_subnet_1a_id" {
  type        = string
  description = "The ID of the private app subnet for ECS tasks"
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