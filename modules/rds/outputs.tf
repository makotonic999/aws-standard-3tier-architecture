# modules/rds/outputs.tf

output "db_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.mysql.address
}

output "db_identifier" {
  value = aws_db_instance.mysql.identifier
}
