output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_1a_id" {
  description = "The ID of the public subnet in 1a"
  value       = aws_subnet.public_1a.id
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