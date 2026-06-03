output "db_security_group_id" {
  description = "The ID of the security group for RDS"
  value       = aws_security_group.db_sg.id
}