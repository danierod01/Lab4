//Monitorización de instancias ASG
resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = "ASG-CPU-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Monitoriza el uso de CPU de las instancias del ASG"
  alarm_actions       = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = merge(var.tags, {
    additional_tag = "ASG-CPU-Alarm-Lab4"
  })
}

//Monitorización del ALB
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "ALB-5XX-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Monitoriza errores 5XX del ALB"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }

  tags = merge(var.tags, {
    additional_tag = "ALB-5XX-Alarm-Lab4"
  })
}

//Monitorización de PostgreSQL
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  alarm_name          = "DB-Connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Monitoriza conexiones a la base de datos"
  alarm_actions       = []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.PSQL-Lab4.id
  }

  tags = merge(var.tags, {
    additional_tag = "DB-Connections-Alarm-Lab4"
  })
}

//Monitorización de Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "Redis-CPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Monitoriza uso de CPU en Redis"
  alarm_actions       = []

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis_lab4.id
  }

  tags = merge(var.tags, {
    additional_tag = "Redis-CPU-Alarm-Lab4"
  })
}

//Monitorización de Memcached
resource "aws_cloudwatch_metric_alarm" "memcached_memory" {
  alarm_name          = "Memcached-Memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "100000000" // 100MB en bytes
  alarm_description   = "Monitoriza memoria disponible en Memcached"
  alarm_actions       = []

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.memcached_lab4.id
  }

  tags = merge(var.tags, {
    additional_tag = "Memcached-Memory-Alarm-Lab4"
  })
}

//Monitorización de EFS
resource "aws_cloudwatch_metric_alarm" "efs_storage" {
  alarm_name          = "EFS-Storage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StorageBytes"
  namespace           = "AWS/EFS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000000000" // 10GB en bytes
  alarm_description   = "Monitoriza uso de almacenamiento en EFS"
  alarm_actions       = []

  dimensions = {
    FileSystemId = aws_efs_file_system.efs_lab4.id
  }

  tags = merge(var.tags, {
    additional_tag = "EFS-Storage-Alarm-Lab4"
  })
}

//Monitorización de CloudFront
resource "aws_cloudwatch_metric_alarm" "cloudfront_errors" {
  alarm_name          = "CloudFront-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "Monitoriza tasa de errores 5XX en CloudFront"
  alarm_actions       = []

  dimensions = {
    DistributionId = aws_cloudfront_distribution.cdn.id
  }

  tags = merge(var.tags, {
    additional_tag = "CloudFront-Errors-Alarm-Lab4"
  })
}

//Monitorización de S3
resource "aws_cloudwatch_metric_alarm" "s3_size" {
  alarm_name          = "S3-Size"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400" // 24 horas
  statistic           = "Average"
  threshold           = "5000000000" // 5GB en bytes
  alarm_description   = "Monitoriza tamaño del bucket S3"
  alarm_actions       = []

  dimensions = {
    BucketName = aws_s3_bucket.bucket.id
  }

  tags = merge(var.tags, {
    additional_tag = "S3-Size-Alarm-Lab4"
  })
}
