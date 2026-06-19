output "db_security_group_id" {
  description = "The ID of the security group for RDS"
  value       = aws_security_group.db_sg.id
}

output "app_sg_id" {
  value       = aws_security_group.app_sg.id # ※もしSGの論理名が違う場合は、実際の名前に合わせてください（例: aws_security_group.standard_bastion_sg.id など）
  description = "The ID of the security group for the app/bastion"
}