resource "aws_lb" "apps" {
  name               = "standard-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids # パブリックサブネットを指定
}

# ターゲットグループ（配送先リスト）
resource "aws_lb_target_group" "webapp" {
  name        = "tg-standard-webapp"
  port        = 8080 # コンテナがリッスンしているポート（必要に応じて変更）
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Fargateの場合は "ip" が必須

  health_check {
    path = "/welcome"
  }
}

# リスナー（玄関の受付窓口）
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.apps.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}

resource "aws_security_group" "alb" {
  name   = "standard-webapp-alb"
  vpc_id = var.vpc_id

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