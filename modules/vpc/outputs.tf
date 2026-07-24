# modules/vpc/outputs.tf

# ===================================================
# VPC
# ===================================================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

# ===================================================
# Public Subnet
# ===================================================
output "public_subnet_1a_id" {
  description = "The ID of the public subnet in 1a"
  value       = aws_subnet.public_1a.id
}

output "public_subnet_1c_id" {
  description = "The ID of the public subnet in 1c"
  value       = aws_subnet.public_1c.id
}

# ===================================================
# Private Subnet
# ===================================================
output "private_app_subnet_1a_id" {
  description = "The ID of the private app subnet in 1a"
  value       = aws_subnet.private_app_1a.id
}

output "private_app_subnet_1c_id" {
  description = "The ID of the private app subnet in 1c"
  value       = aws_subnet.private_app_1c.id
}

# ===================================================
# Security Group
# ===================================================
output "default_security_group_id" {
  value       = aws_vpc.main.default_security_group_id
  description = "The ID of the default security group for the VPC"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the security group attached to the ALB"
}

output "bastion_sg_id" {
  description = "The ID of the Bastion Server"
  value = aws_security_group.bastion_sg.id
}

output "app_sg_id" {
  value       = aws_security_group.app_sg.id
  description = "The ID of the security group for the app"
}

# ===================================================
# Endpoint
# ===================================================
output "ecr_api_endpoint_id" {
  description = "The ID of the ECR API VPC Endpoint"
  value       = aws_vpc_endpoint.ecr_api.id
}

output "ecr_dkr_endpoint_id" {
  description = "The ID of the ECR DKR VPC Endpoint"
  value       = aws_vpc_endpoint.ecr_dkr.id
}

output "s3_endpoint_id" {
  description = "The ID of the S3 VPC Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

# ===========================================================
# Unused Variables (Currently not used since RDS was removed)
# ===========================================================
output "private_db_subnet_1a_id" {
  description = "The ID of the private db subnet in 1a"
  value       = aws_subnet.private_db_1a.id
}

output "private_db_subnet_1c_id" {
  description = "The ID of the private db subnet in 1c"
  value       = aws_subnet.private_db_1c.id
}

output "db_security_group_id" {
  description = "The ID of the security group for RDS"
  value       = aws_security_group.db_sg.id
}
