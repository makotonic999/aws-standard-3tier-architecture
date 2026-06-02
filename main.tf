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

# セキュリティグループ（SSM対応版）
resource "aws_security_group" "bastion_sg" {
  name        = "standard-bastion-sg"
  description = "Security group for bastion server using SSM"
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
    Name = "standard-bastion-sg"
  }
}

# Bastion EC2
# 1. 最新の Amazon Linux 2023 AMI を自動取得
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"]
  }
}

# 2. SSM接続用のIAMロールとプロファイル
# EC2が「自分はEC2です」と名乗るためのロール
resource "aws_iam_role" "bastion_ssm_role" {
  name = "standard-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# ロールに「SSMを使ってもいい」というポリシーを付与
resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 作ったロールをEC2にはめ込める形（インスタンスプロファイル）に変換する
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "standard-bastion-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# 3. 踏み台サーバ（EC2本体）の定義
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name = "standard-bastion-ec2"
  }
}

# Issue #6: プライベートWeb/APサーバ（EC2）の構築
# 1. Web/APサーバ用のセキュリティグループ
resource "aws_security_group" "app_sg" {
  name        = "standard-app-sg"
  description = "Security group for internal Web/AP server"
  vpc_id      = aws_vpc.main.id

  # インバウンドルール
  ingress {
    description     = "Allow traffic from Bastion"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # アウトバウンドルール
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

# 2. Web/APサーバ（EC2本体）の定義
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private_app_1a.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name = "standard-app-ec2"
  }
}