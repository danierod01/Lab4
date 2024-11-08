//Crear la zona alojada para el Route 53
resource "aws_route53_zone" "dns_name" {
  name = "dns_name"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

//Crear el registro de DNS para el endpoint de la Base de Datos PostgreSQL
resource "aws_route53_record" "postgresql" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "postgresql"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.PSQL-Lab4.address]
}

resource "aws_route53_record" "redis" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "redis"
  type    = "CNAME"
  ttl     = 300
  records = [aws_elasticache_replication_group.redis_lab4.primary_endpoint_address]
}

resource "aws_route53_record" "memcached" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "memcached"
  type    = "CNAME"
  ttl     = 300
  records = [aws_elasticache_cluster.memcached_lab4.cluster_address]
}
/*
//Crear el registro de DNS para el ALB
resource "aws_route53_record" "alb" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "alb"
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.alb_interno.dns_name]
}

//Crear el registro de DNS para el endpoint de S3
resource "aws_route53_record" "s3_endpoint" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "s3.lab4_internal"
  type    = "CNAME"
  ttl     = 300
  records = ["s3.${data.aws_region.current.name}.amazonaws.com"]
}*/

//Crear el registro de DNS para el endpoint del EFS
resource "aws_route53_record" "efs" {
  zone_id = aws_route53_zone.dns_name.id
  name    = "efs"
  type    = "CNAME"
  ttl     = 300
  records = [aws_efs_file_system.EFS-Lab4.dns_name]
}

