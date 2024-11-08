# Crear bucket S3
resource "aws_s3_bucket" "s3-lab4" {
  bucket = "s3-lab4-imagenes"

  tags = merge(var.tags, {
    Name = "S3-Lab4"
  })
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.s3-lab4.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Habilitar versionado
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.s3-lab4.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Subir imagen al bucket
resource "aws_s3_object" "objeto-imagen" {
  bucket       = aws_s3_bucket.s3-lab4.id
  key          = "imagen.jpg"
  source       = "${path.module}/imagen.jpg"
  content_type = "image/jpeg"

  tags = merge(var.tags, {
    Name = "Imagen-Lab4"
  })
}

# Política de bucket para permitir acceso desde las instancias EC2 del ASG
resource "aws_s3_bucket_policy" "asg_policy" {
  bucket = aws_s3_bucket.s3-lab4.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowASGAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_iam_role.rol_SSM.arn
        }
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.s3-lab4.arn,
          "${aws_s3_bucket.s3-lab4.arn}/*"
        ]
      }
    ]
  })
}

# Crear política para acceso de CloudFront a S3
resource "aws_iam_policy" "cloudfront_s3_policy" {
  name        = "CloudFront-S3-Access-Policy"
  description = "Política para permitir acceso de CloudFront a S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.s3-lab4.arn}/*",
          aws_s3_bucket.s3-lab4.arn
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "CloudFront-S3-Policy-Lab4"
  })
}

