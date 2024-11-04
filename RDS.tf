//Crear SG para PostgreSQL
resource "aws_security_group" "SG-PSQL" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    additional_tag = "SG-PSQL-Lab4"
  })
}

//Crear el grupo de subredes para PostgreSQL
resource "aws_db_subnet_group" "RDS-subnet" {
  name       = "rds_subnet"
  subnet_ids = module.vpc.private_subnets

  tags = merge(var.tags, {
    additional_tag = "RDS-subnet-Lab4"
  })
}

//Conseguir la versión actual del secreto que se pide
data "aws_secretsmanager_secret_version" "PSQL-secretversion"{
  secret_id = aws_secretsmanager_secret.PSQL-secret.id
}

//Crear la Base de Datos de PostgreSQL
resource "aws_db_instance" "PSQL-Lab4" {
  identifier = "psql-lab4"
  engine = "postgres"
  engine_version = "16.4"
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  storage_type = "gp3"
  multi_az = true
  publicly_accessible = false
  db_subnet_group_name = aws_db_subnet_group.RDS-subnet.name
  vpc_security_group_ids = [aws_security_group.SG-PSQL.id]
  skip_final_snapshot = true 

  //Obtener credenciales del Secrets Manager
  username = jsondecode(data.aws_secretsmanager_secret_version.PSQL-secretversion.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.PSQL-secretversion.secret_string)["password"]

  //Configurar Backups
  backup_retention_period = 7
  backup_window = "03:00-06:00"

  tags = merge(var.tags, {
    additional_tag = "PostgreSQL-Lab4"
  })
}
