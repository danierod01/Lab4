//Crear VPC con módulo
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.14.0"

  name = "VPC-Lab4"
  cidr = var.vpc-cidr

  azs                = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "VPC-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear VPC endpoint para S3
resource "aws_vpc_endpoint" "s3-lab4" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::s3-lab4-dani-2024/*",
          "arn:aws:s3:::s3-lab4-dani-2024"
        ]
      }
    ]
  })
  tags = {
    Name  = "S3-Endpoint-Lab4"
    Env   = "Lab4" 
    Owner = "Dani"
  }
}


//Asociar tablas de rutas del VPC endpoint
resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = length(module.vpc.private_route_table_ids)
  
  vpc_endpoint_id = aws_vpc_endpoint.s3-lab4.id
  route_table_id  = module.vpc.private_route_table_ids[count.index]
}
