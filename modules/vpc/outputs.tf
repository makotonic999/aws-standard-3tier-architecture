output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_1a_id" {
  description = "The ID of the public subnet in 1a"
  value       = aws_subnet.public_1a.id
}

output "public_subnet_1c_id" {
  description = "The ID of the public subnet in 1c"
  value       = aws_subnet.public_1c.id
}

output "private_app_subnet_1a_id" {
  description = "The ID of the private app subnet in 1a"
  value       = aws_subnet.private_app_1a.id
}

output "private_db_subnet_1a_id" {
  description = "The ID of the private db subnet in 1a"
  value       = aws_subnet.private_db_1a.id
}

output "private_db_subnet_1c_id" {
  description = "The ID of the private db subnet in 1c"
  value       = aws_subnet.private_db_1c.id
}

output "default_security_group_id" {
  value       = aws_vpc.main.default_security_group_id
  description = "The ID of the default security group for the VPC"
}

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