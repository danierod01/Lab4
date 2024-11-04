locals {
  s3_bucket_arn = aws_s3_bucket.s3-lab4.arn
}

# Crear bucket S3
resource "aws_s3_bucket" "s3-lab4" {
  bucket = "s3-lab4"

  tags = {
    Name  = "s3-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "access-block" {
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
resource "aws_s3_object" "imagen" {
  bucket       = aws_s3_bucket.s3-lab4.id
  key          = "imagen.jpg"
  source       = "ruta/a/tu/imagen.jpg"
  content_type = "image/jpeg"
}

# Política de bucket para CloudFront
resource "aws_s3_bucket_policy" "cloudfront_policy" {
  bucket = aws_s3_bucket.s3-lab4.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.s3-lab4.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.CDN-Lab4.arn
          }
        }
      }
    ]
  })
}

# Crear distribución CloudFront
resource "aws_cloudfront_distribution" "CDN-Lab4" {
  origin {
    domain_name              = aws_s3_bucket.s3-lab4.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.default.id
    origin_id                = aws_s3_bucket.s3-lab4.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "imagen.jpg"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3-lab4.id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name  = "CDN-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

# Crear Origin Access Control para CloudFront
resource "aws_cloudfront_origin_access_control" "default" {
  name                              = "s3-lab4-oac"
  description                       = "Origin Access Control para s3-lab4"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

