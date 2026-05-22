# SNS Topic for alarm notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email

}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ec2/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-logs"
  }
}

# CPU Utilisation Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when CPU exceeds 80% for 2 consecutive periods"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }
}

# Custom Disk Usage Alarm
resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${var.project_name}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DiskUsage"
  namespace           = "CustomMetrics/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when disk usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }
}

# Custom Memory Usage Alarm
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUsage"
  namespace           = "CustomMetrics/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when memory usage exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = aws_instance.main.id
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          region  = var.aws_region
          title   = "CPU Utilisation"
          metrics = [["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.main.id]]
          period  = 120
          stat    = "Average"
          view    = "timeSeries"
          annotations = {
            horizontal = []
          }
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          region  = var.aws_region
          title   = "Disk Usage"
          metrics = [["CustomMetrics/EC2", "DiskUsage", "InstanceId", aws_instance.main.id]]
          period  = 120
          stat    = "Average"
          view    = "timeSeries"
          annotations = {
            horizontal = []
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          region  = var.aws_region
          title   = "Memory Usage"
          metrics = [["CustomMetrics/EC2", "MemoryUsage", "InstanceId", aws_instance.main.id]]
          period  = 120
          stat    = "Average"
          view    = "timeSeries"
          annotations = {
            horizontal = []
          }
        }
      }
    ]
  })
}
