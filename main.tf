# VPCを作る
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "standard-3tier-vpc"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

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

  # デフォルトルート
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "standard-public-rt"
  }
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
  cidr_block        = "10.0.20.0/24"
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

# セキュリティグループ（SSM対応版）
resource "aws_security_group" "bastion_sg" {
  name        = "standard-bation-sg"
  description = "Security group for bation server using SSM"
  vpc_id      = aws_vpc.main.id

  # インバウンドルール:【完全に空】

  # アウトバウンドルール:SSmの管理画面と通信するために、外への出口だけ開けておく
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # すべての通信を許可
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "standard-bation-sg"
  }
}