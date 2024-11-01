variable "aws_region" {
  description = "La region de AWS"
  default     = "us-east-1"
}

variable "vpc-cidr" {
  description = "CIDR Block del VPC"
  default     = "172.16.0.0/16"
}

variable "public_subnets" {
  description = "Lista de CIDR blocks de subnet publicas"
  default     = ["172.16.1.0/24", "172.16.2.0/24"]
}

variable "private_subnets" {
  description = "Lista de CIDR blocks de subnet privadas"
  default     = ["172.16.3.0/24", "172.16.4.0/24"]
}

variable "availability_zones" {
  description = "Zonas de disponibilidad para las subredes"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway"
  default     = true
}