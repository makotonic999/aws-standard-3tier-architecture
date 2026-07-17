# modules/monitoring/main.tf

# ===================================================
# SNS Topic
# ===================================================
resource "aws_sns_topic" "alarm" {
  name = "standard-cloudwatch-alarm-topic"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# ===================================================
# ALB Alarms
# ===================================================
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "standard-alb-5xx-rate-high"
  alarm_description   = "ALB 5XX error rate exceeded 5%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5

  metric_query {
    id          = "error_rate"
    expression  = "errors / requests * 100"
    label       = "5XX Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
        TargetGroup  = var.target_group_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
        TargetGroup  = var.target_group_arn_suffix
      }
    }
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "standard-alb-latency-high"
  alarm_description   = "ALB average latency exceeded 1 second"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  period              = 60
  statistic           = "Average"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}

# ===================================================
# ECS Alarms
# ===================================================
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "standard-ecs-cpu-high"
  alarm_description   = "ECS CPU utilization exceeded 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  period              = 60
  statistic           = "Average"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  alarm_name          = "standard-ecs-memory-high"
  alarm_description   = "ECS memory utilization exceeded 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  period              = 60
  statistic           = "Average"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}

# ===================================================
# RDS Alarms
# ===================================================
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "standard-rds-cpu-high"
  alarm_description   = "RDS CPU utilization exceeded 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 80
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  period              = 60
  statistic           = "Average"
  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "standard-rds-storage-low"
  alarm_description   = "RDS free storage space is below 5GB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 5000000000 # 5GB in bytes
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  period              = 60
  statistic           = "Average"
  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]
}
