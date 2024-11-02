//Crear SG para conexión con el EFS
resource "aws_security_group" "SG-EFS" {
  name        = "SG-EFS"
  description = "SG para EFS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "SG-EFS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear EFS a mano
resource "aws_efs_file_system" "EFS-Lab4" {
  creation_token = "efs-token"
  encrypted      = true

  tags = {
    Name  = "EFS-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear mount del efs
resource "aws_efs_mount_target" "mount-EFS" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.EFS-Lab4.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.SG-EFS.id]
}