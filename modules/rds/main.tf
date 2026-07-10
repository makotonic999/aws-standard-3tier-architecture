# modules/rds/main.tf

# =================================================================
# subnet group
# =================================================================

resource "aws_db_subnet_group" "mysql" {
  name       = "standard-db-subnet-group"
  subnet_ids = [var.private_db_subnet_1a_id, var.private_db_subnet_1c_id]

  tags = {
    Name = "standard-db-subnet-group"
  }
}

# =================================================================
# RDS instance
# =================================================================

resource "aws_db_instance" "mysql" {
  allocated_storage     = 20
  max_allocated_storage = 100
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  db_name               = "myappdb"
  username = var.db_username
  password = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [var.db_security_group_id]

  publicly_accessible = false
  tags = {
    Name = "standard-mysql-rds"
  }
}