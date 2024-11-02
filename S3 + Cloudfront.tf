locals {
  s3_bucket_arn = aws_s3_bucket.s3-lab4.arn
}

resource "aws_s3_bucket" "s3-lab4" {
  bucket = "s3-lab4-dani-2024"

  tags = {
    name  = "s3-Lab4"
    env   = "Lab4"
    owner = "Dani"
  }
}

resource "aws_s3_bucket_website_configuration" "blog" {
  bucket = aws_s3_bucket.s3-lab4.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.s3-lab4.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.s3-lab4.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "PublicReadGetObject",
        Effect = "Allow"
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        },
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.s3-lab4.arn}",
          "${aws_s3_bucket.s3-lab4.arn}/*" //Acceso a objetos dentros del bucket
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" : "arn:aws:cloudfront::111122223333:distribution/<CloudFront distribution ID>"
          }
        }
      }
    ]
  })
}

resource "aws_s3_object" "object-Lab4" {
  bucket       = aws_s3_bucket.s3-lab4.id
  key          = "index-html"
  source       = "index.html"
  content_type = "text/html"
}


resource "aws_s3_bucket_versioning" "versioning-lab4" {
  bucket = aws_s3_bucket.s3-lab4.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_cloudfront_distribution" "CDN-Lab4" {
  origin {
    domain_name = aws_s3_bucket.s3-lab4.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.s3-lab4.id
  }
  enabled             = true
  default_root_object = "index.html"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3-lab4.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["ES ", "US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}