//Crear SG para PostgreSQL
resource "aws_security_group" "SG-PSQL" {
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "SG-PSQL-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Para generar una contraseña para la Base de Datos de forma aleatoria
resource "random_password" "PSQL-Pass" {
  length  = 16
  special = true
}

//Crear el secreto para almacenar la contraseña
resource "aws_secretsmanager_secret" "PSQL-secret" {
  name = "psql-secret"
}

//Crear versión del secreto
resource "aws_secretsmanager_secret_version" "PSQL-secret-version" {
  secret_id = aws_secretsmanager_secret.PSQL-secret.id
  secret_string = jsonencode({
    username = var.PSQL-username
    password = random_password.PSQL-Pass.result
  })
}

//Crear el grupo de subredes para PostgreSQL
resource "aws_db_subnet_group" "RDS-subnet" {
  name       = "rds_subnet"
  subnet_ids = module.vpc.private_subnets

  tags = {
    name  = "RDS-subnet-Lab4"
    env   = "Lab4"
    owner = "Dani"
  }
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

  //Obtener credenciales del Secrets Manager
  username = jsondecode(data.aws_secretsmanager_secret_version.PSQL-secretversion.secret_string)["username"]
  password = jsondecode(data.aws_secretsmanager_secret_version.PSQL-secretversion.secret_string)["password"]

  //Configurar Backups
  backup_retention_period = 7
  backup_window = "03:00-06:00"

  tags = {
    name  = "PSQL-Lab4"
    env   = "Lab4"
    owner = "Dani"
  }
}
