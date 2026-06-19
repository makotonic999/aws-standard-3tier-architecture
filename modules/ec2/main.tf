# =================================================================
# 1. 共通データソース（Goの正規表現バグを回避した完璧な動的指定）
# =================================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  # 🎯 1. まずは「al2023-ami-20」から始まる年号ベースの標準版候補を広くキャッチ
  filter {
    name   = "name"
    values = ["al2023-ami-20*-x86_64"]
  }

  # 🎯 2.【これが本命】名前に「minimal」や「ecs」が入っているものを「除外」する
  # values の先頭に「!」を付ける、あるいは通常版に必ず含まれる文字列を指定します。
  # 2026年現在のAmazon Linux 2023 標準版の決定的な特徴である「-kernel-」を条件に加えることで、
  # 「al2023-ami-minimal-20...」の形式を100%確実に検索対象から除外（スキップ）します！
  filter {
    name   = "name"
    values = ["*-kernel-6.*"] # 標準版に含まれるカーネルバージョンをピンポイント指定
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# =================================================================
# 2. IAMロール・プロファイル定義
# =================================================================

# EC2がSSM（セッションマネージャー）等と通信するための共通ロール
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

# ECRへのアクセス権限
resource "aws_iam_role_policy_attachment" "bastion_ecr_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# SSM（Session Manager）のコア権限
resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 作成したロールをEC2にアタッチできる形に変換
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "standard-bastion-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

# =================================================================
# 3. セキュリティグループ（SG）定義
# =================================================================

# 踏み台サーバー用セキュリティグループ
resource "aws_security_group" "bastion_sg" {
  name        = "standard-bastion-sg"
  description = "Security group for bastion server using SSM"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
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

# Web/APサーバー用セキュリティグループ
resource "aws_security_group" "app_sg" {
  name        = "standard-app-sg"
  description = "Security group for internal Web/AP server"
  vpc_id      = var.vpc_id

  # 踏み台SGからのすべての通信を許可
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

# RDS用セキュリティグループ
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

# =================================================================
# 4. サーバー（EC2）本体定義
# =================================================================

# 踏み台サーバー
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id # 🎯 動的一本釣り
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_1a_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_profile.name

  # 起動時に自動で通常版OSにDocker・Gitを仕込む
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

# Web/APサーバー
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