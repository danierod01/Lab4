//Crear Security Group del ALB
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
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
resource "aws_lb" "alb-lab4" {
  name               = "alb-lab4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name  = "alb-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear el Target Group
resource "aws_lb_target_group" "tg-alb" {
  name     = "tg-alb"
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

//Crear ACM para SSL
resource "aws_acm_certificate" "certificado-SSL" {
  certificate_body = file("./Certificados/Certificado.pem")
  private_key      = file("./Certificados/Key.pem")

  tags = {
    Name  = "Certificado SSL"
    Env   = "Lab4"
    Owner = "Dani"
  }

}

//Crear el listener para HTTPS del Target Group
resource "aws_lb_listener" "listener-https" {
  load_balancer_arn = aws_lb.alb-lab4.arn
  port              = 443
  protocol          = "HTTPS"

  # Asociar el certificado ACM al listener
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.certificado-SSL.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-alb.arn
  }

  tags = {
    Name  = "Listener-HTTPS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}
