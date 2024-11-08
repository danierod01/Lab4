# Crear VPC de backup
resource "aws_vpc" "backup" {
  cidr_block = "172.31.0.0/16"  // Asegúrate de que no se solape con la VPC principal
  
  tags = merge(var.tags, {
    Name = "VPC-Backup-Lab4"
  })
}

# Crear subnet privada para backup
resource "aws_subnet" "backup_private" {
  vpc_id     = aws_vpc.backup.id
  cidr_block = "172.31.1.0/24"
  
  tags = merge(var.tags, {
    Name = "Subnet-Backup-Private-Lab4"
  })
}

# Crear VPC Peering
resource "aws_vpc_peering_connection" "main_to_backup" {
  peer_vpc_id = aws_vpc.backup.id
  vpc_id      = module.vpc.vpc_id
  auto_accept = true

  tags = merge(var.tags, {
    Name = "VPC-Peering-Lab4"
  })
}

# Crear route table para la VPC de backup
resource "aws_route_table" "backup-route-table" {
  vpc_id = aws_vpc.backup.id

  route {
    cidr_block                = module.vpc.vpc_cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.main_to_backup.id
  }

  tags = merge(var.tags, {
    Name = "RT-Backup-Lab4"
  })
}

# Añadir rutas en las route tables privadas de la VPC principal
resource "aws_route" "main_to_backup_private1-Lab4" {
  route_table_id            = module.vpc.private_route_table_ids[0]
  destination_cidr_block    = aws_vpc.backup.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_backup.id
}

resource "aws_route" "main_to_backup_private2-Lab4" {
  route_table_id            = module.vpc.private_route_table_ids[1]
  destination_cidr_block    = aws_vpc.backup.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main_to_backup.id
}

# Asociar la subnet de backup con su route table
resource "aws_route_table_association" "backup-Lab4" {
  subnet_id      = aws_subnet.backup_private.id
  route_table_id = aws_route_table.backup-route-table.id
}

# Generar sufijo aleatorio para nombres únicos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Crear bucket S3 para backup
resource "aws_s3_bucket" "drupal_backup" {
  bucket = "drupal-backup-lab4-${random_string.suffix.result}"
  
  tags = merge(var.tags, {
    Name = "S3-Drupal-Backup-Lab4"
  })
}

# Configurar encriptación del bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "drupal_backup_encryption" {
  bucket = aws_s3_bucket.drupal_backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "drupal_backup_public_access" {
  bucket = aws_s3_bucket.drupal_backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}