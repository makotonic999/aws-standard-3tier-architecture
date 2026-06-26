# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "standard-3tier-vpc"
  }
}

# Subnet
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "standard-public_1a"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "standard-igw"
  }
}

# Route Table
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

# Route Table Association
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

# Issue #3: プライベートサブネット (App / DB)

# 1. アプリ (AP) 用サブネット
resource "aws_subnet" "private_app_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "standard-private-app-1a"
  }
}

# 2. データベース (DB) 用サブネット
resource "aws_subnet" "private_db_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "standard-private-db-1a"
  }
}

# 3. プライベート用ルートテーブル
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "standard-private-rt"
  }
}

# 4. ルートテーブルの紐づけ (App)
resource "aws_route_table_association" "private_app_1a" {
  subnet_id      = aws_subnet.private_app_1a.id
  route_table_id = aws_route_table.private.id
}

# 5. ルートテーブルの紐づけ (DB)
resource "aws_route_table_association" "private_db_1a" {
  subnet_id      = aws_subnet.private_db_1a.id
  route_table_id = aws_route_table.private.id
}

# Issue #7: データベース（RDS MySQL）の構築
# 1. マルチAZ要件を満たすため、別AZ（1c）にDB用サブネットを追加
resource "aws_subnet" "private_db_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.31.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "standard-private-db-1c"
  }
}

resource "aws_route_table_association" "private_db_1c" {
  subnet_id      = aws_subnet.private_db_1c.id
  route_table_id = aws_route_table.private.id
}

# VPCエンドポイント専用のセキュリティグループ（VPC内部からの443通信を許可）
resource "aws_security_group" "vpc_endpoint" {
  name        = "standard-vpc-endpoint-sg"
  description = "Allow HTTPS inbound traffic from VPC"
  vpc_id      = aws_vpc.main.id

  # インバウンド（入ってくる通信）: VPC内のセグメント全体から443番ポートへのアクセスを許可
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  # アウトバウンド（出ていく通信）: 基本全開
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

# ECR API 用のVPCエンドポイント
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  
  # プライベートサブネットを紐付ける
  subnet_ids          = [aws_subnet.private_app_1a.id]
  
  # セキュリティグループ
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  private_dns_enabled = true

  tags = {
    Name = "ecs-standard-ecr-api-endpoint"
  }
}

# ECR DKR 用のVPCエンドポイント（実際のイメージをダウンロードする通路）
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

# CloudWatch Logs 用のVPCエンドポイント（ログを送り出す通路）
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

# 4. Amazon S3 用のVPCエンドポイント（ECRのデータ実体を取りに行く通路）
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway" 
  route_table_ids   = [aws_route_table.private.id] 
}