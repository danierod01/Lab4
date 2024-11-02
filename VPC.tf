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

  tags = {
    Name  = "VPC-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}