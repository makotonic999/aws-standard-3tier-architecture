# modules/vpc/main.tf

# ===================================================
# vpc
# ===================================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "standard-3tier-vpc"
  }
}

# ===================================================
# Public Subnet
# ===================================================
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "standard-public_1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "standard-public_1c"
  }
}

# ===================================================
# Internet Gateway
# ===================================================
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "standard-igw"
  }
}

# ===================================================
# Route Table
# ===================================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "standard-public-rt"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# ===================================================
# Route Table Association
# ===================================================
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

# ===================================================
# Private Subnet
# ===================================================
resource "aws_subnet" "private_app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "standard-private-app-1a"
  }
}

resource "aws_subnet" "private_app_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "standard-private-app-1a"
  }
}


# ===================================================
# Route Table for Private Subnet
# ===================================================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "standard-private-rt"
  }
}

# ===================================================
# Route Table Associtation for Private Subnet
# ===================================================
resource "aws_route_table_association" "private_app_1a" {
  subnet_id      = aws_subnet.private_app_1a.id
  route_table_id = aws_route_table.private.id
}

# ===================================================
# Security Group
# ===================================================
# for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name        = "standard-vpc-endpoint-sg"
  description = "Allow HTTPS inbound traffic from VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "standard-vpc-endpoint-sg"
  }
}

# for ALB
resource "aws_security_group" "alb" {
  name   = "standard-webapp-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# for Bastion
resource "aws_security_group" "bastion_sg" {
  name        = "standard-bastion-sg"
  description = "Security group for bastion server using SSM"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  ingress {
    description = "Allow HTTP traffic on port 8000 from VPC"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # 誠さんのVPCのCIDR範囲（もし変えていれば合わせてください）
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "standard-bastion-sg"
  }
}

# for Web/AP (ECS)
resource "aws_security_group" "app_sg" {
  name        = "standard-app-sg"
  description = "Security group for internal Web/AP server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP traffic from ALB on port 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Allow traffic from Bastion"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "standard-app-sg"
  }
}

# ===================================================
# Endpoint
# ===================================================
# ECR API Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app_1a.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "ecs-standard-ecr-api-endpoint"
  }
}

# ECR DKR Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app_1a.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ecs-standard-ecr-dkr-endpoint"
  }
}

# CloudWatch Logs Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app_1a.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = {
    Name = "ecs-standard-logs-endpoint"
  }
}

# S3 Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway" 
  route_table_ids   = [aws_route_table.private.id] 
}

# ===========================================================
# Unused Variables (Currently not used since RDS was removed)
# ===========================================================
/*
resource "aws_subnet" "private_db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "standard-private-db-1a"
  }
}

resource "aws_route_table_association" "private_db_1a" {
  subnet_id      = aws_subnet.private_db_1a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db_1c" {
  subnet_id      = aws_subnet.private_db_1c.id
  route_table_id = aws_route_table.private.id
}

resource "aws_subnet" "private_db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "standard-private-db-1c"
  }
}

# for RDS
resource "aws_security_group" "db_sg" {
  name        = "standard-db-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

  # AppサーバーSGからのMySQL（3306）通信のみ許可
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
*/

# ===================================================
# commment outs (Web/AP)
# ===================================================
/*
# Web/AP
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id # 🎯 動的一本釣り
  instance_type          = "t3.micro"
  subnet_id              = var.private_app_subnet_1a_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name = "standard-app-ec2"
  }
}
*/