# =================================================================
# 1. 共通データ・リソース
# =================================================================

# 最新の Amazon Linux 2023 AMI を自動取得
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-minimal-*-x86_64"]
  }
}

# =================================================================
# 2. IAMロール
# =================================================================

# SSM接続用のIAMロールとプロファイル
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

# ECRにプッシュできる権限
resource "aws_iam_role_policy_attachment" "bastion_ecr_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
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

# =================================================================
# 3. セキュリティグループの定義
# =================================================================

# 踏み台サーバ用（SSM対応版）
resource "aws_security_group" "bastion_sg" {
  name        = "standard-bastion-sg"
  description = "Security group for bastion server using SSM"
  vpc_id      = var.vpc_id

ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # 検証が終わったら消すので、今はこれで確実に開けます
  }

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

# 1. Web/APサーバ用
resource "aws_security_group" "app_sg" {
  name        = "standard-app-sg"
  description = "Security group for internal Web/AP server"
  vpc_id      = var.vpc_id

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

# RDS用（Appサーバからの通信のみ許可）
resource "aws_security_group" "db_sg" {
  name        = "standard-db-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

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

# =================================================================
# 4. サーバー本体の定義
# =================================================================

# 踏み台サーバ
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_1a_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  # 起動時に自動でDockerをインストールして動かす
user_data = <<-EOF
            #!/bin/bash
            dnf update -y
            dnf install -y docker git
            systemctl start docker
            systemctl enable docker
            usermod -aG docker ec2-user
            EOF

  tags = {
    Name = "standard-bastion-ec2"
  }
}

# Web/APサーバ
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = var.private_app_subnet_1a_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  tags = {
    Name = "standard-app-ec2"
  }
}