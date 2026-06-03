# Issue #7: データベース（RDS MySQL）の構築
# 1. マルチAZ要件を満たすため、別AZ（1c）にDB用サブネットを追加
resource "aws_subnet" "private_db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "ap-northeast_1c"

  tags = {
    Name = "standard-private-db-1c"
  }
}

resource "aws_route_table_association" "private_db_1c" {
  subnet_id      = aws_subnet.private_db_1c.id
  route_table_id = aws_route_table.private.id
}

# 2. RDS用のSG（Appサーバからの通信のみ許可）
resource "aws_security_group" "db_sg" {
  name        = "standard-db-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow MySQL traffic from App SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "standard-db-sg"
  }
}

# 3. RDS用のサブネットグループ（1aと1cのサブネットを紐づけ）
resource "aws_db_subnet_group" "mysql" {
  name       = "standard-db-subnet-group"
  subnet_ids = [aws_subnet.private_db_1a.id, aws_subnet.private_db_1c.id]

  tags = {
    Name = "standard-db-subnet-group"
  }
}

# 4. RDSインスタンス本体の定義
resource "aws_db_instance" "mysql" {
  allocated_storage     = 20
  max_allocated_storage = 100
  engine                = "mysql"
  engine_version        = "8.0.35"
  instance_class        = "db.t3.micro"
  db_name               = "myappdb"

  # variables.tf から変数を注入
  username = var.db_username
  password = var.db_password

  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  publicly_accessible = false
  tags = {
    Name = "standard-mysql-rds"
  }
}