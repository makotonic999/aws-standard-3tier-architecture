# modules/ecs/main.tf

# ===================================================
# ECR
# ===================================================
resource "aws_ecr_repository" "app" {
  name                 = "standard-webapp"
  image_tag_mutability = "MUTABLE"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ==============================================================================
# ECS Task Execution Role (Permissions for pulling ECR images & writing logs)
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

# Attach standard AWS policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ===================================================
# ECS Task Definition
# ===================================================
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
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/standard-webapp"
  retention_in_days = 7
}

# ===================================================
# ECS Cluster
# ===================================================
resource "aws_ecs_cluster" "main" {
  name = "standard-ecs-cluster"
}

# ===================================================
# ECS Service
# ===================================================
resource "aws_ecs_service" "app" {
  name            = "standard-webapp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.private_app_subnet_1a_id, var.private_app_subnet_1c_id]
    security_groups  = [var.app_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "webapp"
    container_port   = 8000
  }

  depends_on = [
    var.ecr_api_endpoint_id,
    var.ecr_dkr_endpoint_id,
    var.s3_endpoint_id,
    var.alb_listener_http_arn
  ]
}