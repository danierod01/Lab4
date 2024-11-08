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
    Name = "SG-Cache-Lab4"
  })
}

//Crear grupo de subredes para Cache
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name       = "cache-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = merge(var.tags, {
    Name = "Cache-Subnet-Group-Lab4"
  })
}

//Crear grupo de parámetros para Redis
resource "aws_elasticache_parameter_group" "redis_params" {
  family = "redis7"
  name   = "redis-params"

  tags = merge(var.tags, {
    Name = "Redis-Params-Lab4"
  })
}

//Crear grupo de parámetros para Memcached
resource "aws_elasticache_parameter_group" "memcached_params" {
  family = "memcached1.6"
  name   = "memcached-params"

  tags = merge(var.tags, {
    Name = "Memcached-Params-Lab4"
  })
}

//Crear Redis para conexión con instancias y PostgreSQL con replicación
resource "aws_elasticache_replication_group" "redis_lab4" {
  replication_group_id       = "redis-lab4"
  description                = "Redis cluster con replicación para Lab4"
  engine                     = "redis"
  node_type                  = "cache.t3.micro"
  num_cache_clusters         = 2
  parameter_group_name       = aws_elasticache_parameter_group.redis_params.name
  port                       = 6379
  security_group_ids         = [aws_security_group.SG-Cache.id]
  subnet_group_name          = aws_elasticache_subnet_group.cache_subnet_group.name
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = merge(var.tags, {
    Name = "Redis-Lab4"
  })
}

//Crear Memcached para sesiones
resource "aws_elasticache_cluster" "memcached_lab4" {
  cluster_id           = "memcached-lab4"
  engine               = "memcached"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 2
  parameter_group_name = aws_elasticache_parameter_group.memcached_params.name
  port                 = 11211
  security_group_ids   = [aws_security_group.SG-Cache.id]
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group.name
  az_mode              = "cross-az"
  preferred_availability_zones = [
    var.availability_zones[0],
    var.availability_zones[1]
  ]

  tags = merge(var.tags, {
    Name = "Memcached-Lab4"
  })
}

