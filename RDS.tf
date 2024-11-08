//Crear SG para PostgreSQL
resource "aws_security_group" "SG-PSQL" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "SG-PSQL-Lab4"
  })
}

//Crear el grupo de subredes para PostgreSQL
resource "aws_db_subnet_group" "RDS-subnet" {
  name       = "rds_subnet"
  subnet_ids = module.vpc.private_subnets

  tags = merge(var.tags, {
    Name = "RDS-subnet-Lab4"
  })
}

//Crear la Base de Datos de PostgreSQL
resource "aws_db_instance" "PSQL-Lab4" {
  identifier             = "psql-lab4"
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.RDS-subnet.name
  vpc_security_group_ids = [aws_security_group.SG-PSQL.id]
  skip_final_snapshot    = true

  //Credenciales de la Base de Datos
  db_name  = "drupaldb"
  username = "postgres"
  password = "password1.2.3.4."

  //Configurar Backups
  backup_retention_period = 7
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"

  //Añadir timeouts más largos
  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }

  //Deshabilitar actualizaciones automáticas menores
  auto_minor_version_upgrade = false

  tags = merge(var.tags, {
    Name = "PostgreSQL-Lab4"
  })
}