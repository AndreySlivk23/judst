resource "aws_cloudwatch_metric_alarm" "cpu_over_threshold" {
  alarm_name          = "jitbit-rds-cpu-threshold"
  alarm_description   = "Triggers alarm if RDS CPU crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "80"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "ram_over_threshold" {
  alarm_name          = "jitbit-rds-ram-threshold"
  alarm_description   = "Triggers alarm if RDS RAM crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "10"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "800000000"
  treat_missing_data  = "missing"
  comparison_operator = "LessThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "read_latency_over_threshold" {
  alarm_name          = "jitbit-rds-read-latency-threshold"
  alarm_description   = "Triggers alarm if RDS read latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "write_latency_over_threshold" {
  alarm_name          = "jitbit-rds-write-latency-threshold"
  alarm_description   = "Triggers alarm if RDS write latency crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "5"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "db_connections_over_threshold" {
  alarm_name          = "jitbit-rds-db-connections-threshold"
  alarm_description   = "Triggers alarm if RDS database connections crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = "60"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "100"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "db_queue_depth_over_threshold" {
  alarm_name          = "jitbit-rds-db-queue-depth-threshold"
  alarm_description   = "Triggers alarm if RDS database queue depth crosses a threshold"
  namespace           = "AWS/RDS"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  period              = "300"
  evaluation_periods  = "5"
  alarm_actions       = [aws_sns_topic.jitbit_alerting.arn]
  ok_actions          = [aws_sns_topic.jitbit_alerting.arn]
  threshold           = "60"
  treat_missing_data  = "missing"
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    DBInstanceIdentifier = "${local.application_name}-${local.environment}-database"
  }

  tags = merge(
    local.tags,
    {
      Name = local.application_name
    }
  )
}
