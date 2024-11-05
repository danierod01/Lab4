//Crear la zona alojada para el Route 53
resource "aws_route53_zone" "lab4_internal" {
  name = "lab4_internal"
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

//Crear el registro de DNS para el endpoint de la Base de Datos PostgreSQL
resource "aws_route53_record" "postgresql" {
  zone_id = aws_route53_zone.lab4_internal.id
  name    = "postgresql_lab4_internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.PSQL-Lab4.endpoint]
}

//Crear el registro de DNS para el ALB
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.lab4_internal.id
  name    = "alb_lab4_internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.alb.dns_name]
}

//Crear el registro de DNS para las instancias del ASG
resource "aws_route53_record" "asg" {
  zone_id = aws_route53_zone.lab4_internal.id
  name    = "asg_lab4_internal"
  type    = "A"

  alias {
    name                   = aws_lb.alb-lab4.dns_name
    zone_id               = aws_lb.alb-lab4.zone_id
    evaluate_target_health = true
  }
}

//Crear el registro de DNS para el endpoint de S3
resource "aws_route53_record" "s3_endpoint" {
  zone_id = aws_route53_zone.lab4_internal.id
  name    = "s3.lab4_internal"
  type    = "A"

  alias {
    name                   = "${aws_vpc_endpoint.s3-lab4.id}.s3.${data.aws_region.current.name}.vpce.amazonaws.com"
    zone_id                = "Z1AAAAAAAAAAAAA"
    evaluate_target_health = true
  }
}

//Crear el registro de DNS para el endpoint del EFS
resource "aws_route53_record" "efs" {
  zone_id = aws_route53_zone.lab4_internal.id
  name    = "efs.lab4_internal"
  type    = "CNAME"
  ttl     = 300
  records = [aws_efs_file_system.EFS-Lab4.dns_name]
}

