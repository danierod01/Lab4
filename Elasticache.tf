//Crear SG para Redis y Memcached
resource "aws_security_group" "SG-Cache" {
  vpc_id = module.vpc.vpc_id
  
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.SG-instancias.id, aws_security_group.SG-PSQL.id]
  }

  ingress {
    from_port       = 11211
    to_port         = 11211
    protocol        = "tcp"
    security_groups = [aws_security_group.SG-instancias.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    additional_tag = "SG-Cache-Lab4"
  })
}

//Crear grupo de subredes para Cache
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "cache-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(var.tags, {
    additional_tag = "Cache-Subnet-Group-Lab4"
  })
}

//Crear grupo de parámetros para Redis
resource "aws_elasticache_parameter_group" "redis_params" {
  family = "redis7"
  name   = "redis-params"

  tags = merge(var.tags, {
    additional_tag = "Redis-Params-Lab4"
  })
}

//Crear grupo de parámetros para Memcached
resource "aws_elasticache_parameter_group" "memcached_params" {
  family = "memcached1.6"
  name   = "memcached-params"

  tags = merge(var.tags, {
    additional_tag = "Memcached-Params-Lab4"
  })
}

//Crear Redis para conexión con instancias y PostgreSQL
resource "aws_elasticache_cluster" "redis_lab4" {
  cluster_id           = "redis_lab4"
  engine              = "redis"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 2
  parameter_group_name = aws_elasticache_parameter_group.redis_params.name
  port                = 6379
  security_group_ids  = [aws_security_group.SG-Cache.id]
  subnet_group_name   = aws_elasticache_subnet_group.cache_subnet_group.name
  availability_zone   = var.availability_zones[0]

  tags = merge(var.tags, {
    additional_tag = "Redis-Lab4"
  })
}

//Crear Memcached para sesiones
resource "aws_elasticache_cluster" "memcached_lab4" {
  cluster_id           = "memcached_lab4"
  engine              = "memcached"
  node_type           = "cache.t3.micro"
  num_cache_nodes     = 2
  parameter_group_name = aws_elasticache_parameter_group.memcached_params.name
  port                = 11211
  security_group_ids  = [aws_security_group.SG-Cache.id]
  subnet_group_name   = aws_elasticache_subnet_group.cache_subnet_group.name
  az_mode             = "cross-az"
  preferred_availability_zones = var.availability_zones

  tags = merge(var.tags, {
    additional_tag = "Memcached-Lab4"
  })
}

