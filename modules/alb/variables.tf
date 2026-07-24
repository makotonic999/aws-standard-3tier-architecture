# modules/alb/variables.tf

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The IDs of the public subnets"
}

variable "alb_security_group_id" {
  type        = string
  description = "The ID of the security group attached to the ALB"
}