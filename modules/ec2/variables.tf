# modules/ec2/variables.tf

variable "public_subnet_1a_id" {
  type        = string
  description = "The ID of the public subnet 1a"
}

variable "bastion_sg_id" {
  type = string
  description = "The ID of the SG for Bastion"
}

# ==================================================================
# Unused Variables (Currently not used since Web/AP EC2 was removed)
# ==================================================================
/*
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "private_app_subnet_1a_id" {
  type        = string
  description = "The ID of the private app subnet 1a"
}
*/