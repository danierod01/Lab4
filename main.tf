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
//Crear SG para conexión con el EFS
resource "aws_security_group" "SG-EFS" {
  name        = "SG-EFS"
  description = "SG para EFS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "SG-EFS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear Security Group de las instancias
resource "aws_security_group" "SG-instancias" {
  name        = "SG-instancias"
  description = "Security Group de instancias"
  vpc_id      = module.vpc.default_vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = aws_security_group.SG-ALB.id
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = aws_security_group.SG-EFS.id

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "SG-Instancias-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear Security Group del ALB
resource "aws_security_group" "SG-ALB" {
  name        = "SG-ALB"
  description = "Security Group del ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }

  tags = {
    Name  = "SG-ALB-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear el Application Load Balancer
resource "aws_lb" "ALB-1" {
  name               = "ALB-1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.SG-ALB.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name  = "ALB-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear el Target Group
resource "aws_lb_target_group" "TG-ALB" {
  name     = "TG-ALB"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name  = "TG-ALB-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear ACM para ssl
resource "aws_acm_certificate" "certificado-SSL" {
  certificate_body = file("./Certificado.pem")
  private_key      = file("./Key.pem")

  tags = {
    Name  = "Certificado SSL"
    Env   = "Lab4"
    Owner = "Dani"
  }

}

//Crear el listener para HTTPS del Target Group
resource "aws_lb_listener" "listener-https" {
  load_balancer_arn = aws_lb.alb-1.arn
  port              = 443
  protocol          = "HTTPS"

  # Asociar el certificado ACM al listener
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.certificado-SSL.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TG-ALB.arn
  }

  tags = {
    Name  = "Listener-HTTPS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear EFS a mano
resource "aws_efs_file_system" "EFS-Lab4" {
  creation_token = "efs-token"
  encrypted      = true

  tags = {
    Name  = "EFS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear mount del efs
resource "aws_efs_mount_target" "mount-EFS" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.EFS-Lab4.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.SG-EFS.id]
}