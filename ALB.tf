//Crear Security Group del NLB
resource "aws_security_group" "alb_externo_sg" {
  name        = "alb_externo_sg"
  description = "Security Group del ALB externo"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/16"]
  }

  tags = merge(var.tags, {
    Name = "SG-ALB-Externo-Lab4"
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Security Group del ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_externo_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.16.0.0/16"]
  }

  tags = merge(var.tags, {
    Name = "SG-ALB-Lab4"
  })
}

//Crear un NLB externo  
resource "aws_lb" "alb-externo-lab4" {
  name               = "alb-externo-lab4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_externo_sg.id]
  subnets            = module.vpc.public_subnets
  
  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "ALB-Externo-Lab4"
  })

  depends_on = [module.vpc]
}

//Crear ACM para SSL
resource "aws_acm_certificate" "certificado-SSL" {
  certificate_body = file("./Certificados/Certificado.pem")
  private_key      = file("./Certificados/Key.pem")

  tags = merge(var.tags, {
    Name = "ACM-Lab4"
  })

}

//Crear Target Group para el ALB externo
resource "aws_lb_target_group" "tg-alb-externo" {
  name        = "tg-alb-externo"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    healthy_threshold   = 2
    interval            = 30
    matcher            = "200"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "TG-ALB-Externo-Lab4"
  })
}

//Crear listener HTTPS para el ALB externo
resource "aws_lb_listener" "listener-https-externo" {
  load_balancer_arn = aws_lb.alb-externo-lab4.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.certificado-SSL.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-alb-externo.arn
  }


  tags = merge(var.tags, {
    Name = "Listener-HTTPS-Externo-Lab4"
  })
}

//Crear listener HTTP para el ALB externo
resource "aws_lb_listener" "listener-http-externo" {
  load_balancer_arn = aws_lb.alb-externo-lab4.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" 
    }
  }

  tags = merge(var.tags, {
    Name = "Listener-HTTP-Externo-Lab4"
  })
}


// Crear ALB interno
resource "aws_lb" "alb-interno-lab4" {
  name               = "alb-interno-lab4"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.vpc.private_subnets

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name = "ALB-Interno-Lab4"
  })

  depends_on = [module.vpc]
}

// Crear Target Group para el ALB interno
resource "aws_lb_target_group" "tg-alb-interno" {
  name     = "tg-alb-interno"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/health"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "TG-ALB-Interno-Lab4"
  })
}

// Crear listener HTTP para el ALB interno
resource "aws_lb_listener" "listener-http-interno" {
  load_balancer_arn = aws_lb.alb-interno-lab4.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg-alb-interno.arn
  }

  tags = merge(var.tags, {
    Name = "Listener-HTTP-Interno-Lab4"
  })
}