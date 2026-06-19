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
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}