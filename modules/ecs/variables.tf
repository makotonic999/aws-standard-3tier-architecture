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