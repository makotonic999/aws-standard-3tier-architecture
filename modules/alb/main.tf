# ===================================================
# ALB
# ===================================================
resource "aws_lb" "apps" {
  name               = "standard-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
}

# ===================================================
# Target Group
# ===================================================
resource "aws_lb_target_group" "webapp" {
  name        = "tg-standard-webapp"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================================
# Listener
# ===================================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.apps.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp.arn
  }
}
