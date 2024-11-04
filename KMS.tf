resource "aws_kms_key" "postgre_creds_key" {
  description = "Key de KMS para encriptar credenciales de PostgreSQL"
  tags = merge(var.tags, {
    additional_tag = "PSQL-Creds-Key-Lab4"
  })
}

resource "aws_secretsmanager_secret" "postgre_credentials" {
  name       = "postgre_credentials"
  kms_key_id = aws_kms_key.postgre_creds_key.id
  tags = merge(var.tags, {
    additional_tag = "Postgre-Creds-Lab4"
  })
}

//Para generar una contraseña para la Base de Datos de forma aleatoria
resource "random_password" "PSQL-Pass" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.postgre_credentials.id
  secret_string = jsonencode({
    username = var.PSQL-username.default
    password = random_password.PSQL-Pass.result
  })
}
