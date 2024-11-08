// Crear el tema SNS para las alertas
resource "aws_sns_topic" "alertas" {
  name = "alertas-lab4"

  tags = merge(var.tags, {
    Name = "SNS-Alertas-Lab4"
  })
}

// Crear la política del tema SNS
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.alertas.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.alertas.arn
      }
    ]
  })
} 