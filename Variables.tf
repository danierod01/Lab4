//Variable para almacenar la región en la que se encuentra la arquitectura
variable "aws_region" {
  description = "La region de AWS"
  default     = "us-east-1"
}

//Variable que guarda el CIDR del VPC
variable "vpc-cidr" {
  description = "CIDR Block del VPC"
  default     = "172.16.0.0/16"
}

//Variable que guarda los CIDRs de las subredes públicas
variable "public_subnets" {
  description = "Lista de CIDR blocks de subnet publicas"
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

//Variable que guarda los CIDRs de las subredes privadas
variable "private_subnets" {
  description = "Lista de CIDR blocks de subnet privadas"
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
}

//Variable que guarda las zonas de disponibilidad donde se implementa la arquitectura
variable "availability_zones" {
  description = "Zonas de disponibilidad para las subredes"
  default     = ["us-east-1a", "us-east-1b"]
}

//Variable que habilita los NAT Gateways del VPC
variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway"
  default     = true
}

//Variable que guarda el nombre de usuario de la DB
variable "PSQL-username" {
  description = "Nombre de usuario de PSQL"
  type        = string
  default     = "dani"
}