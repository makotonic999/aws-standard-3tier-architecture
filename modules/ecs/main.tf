resource "aws_ecr_repository" "app" {
  name                 = "standard-webapp"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# 今後のECS構築（タスク定義など）でリポジトリURLを使い回せるようにoutputしておく
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

# ==============================================================================
# 1. ECSタスク実行ロール (ECSがECRからイメージをプルしたり、ログを吐くための権限)
# ==============================================================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "standard-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# AWSが用意している、ECS実行用の標準ポリシーをロールに紐付ける
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==============================================================================
# 2. ECSタスク定義 (Fargateで動かすコンテナの設計図)
# ==============================================================================
resource "aws_ecs_task_definition" "app" {
  family                   = "standard-webapp-task"
  network_mode             = "awsvpc" # Fargateは必須
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"    # 0.25 vCPU
  memory                   = "512"    # 512 MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "webapp"
      image     = "${aws_ecr_repository.app.repository_url}:latest" # 前回作ったECRのURLを自動参照！
      essential = true
      
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

# ==============================================================================
# 3. ECSクラスター (コンテナを動かす論理的な基盤)
# ==============================================================================
resource "aws_ecs_cluster" "main" {
  name = "standard-ecs-cluster"
}

# ==============================================================================
# 4. ECSサービス (設計図を元にコンテナを常時起動・管理する)
# ==============================================================================
resource "aws_ecs_service" "app" {
  name            = "standard-webapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1          # 起動するコンテナの数
  launch_type     = "FARGATE"  # サーバーレスモード

  network_configuration {
    subnets          = [var.private_app_subnet_1a_id]
    security_groups  = [var.app_sg_id]
    assign_public_ip = false # プライベート空間なのでパブリックIPは不要
  }
}