
//Crear Security Group de las instancias
resource "aws_security_group" "SG-instancias" {
  name        = "SG-instancias"
  description = "Security Group de instancias"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.SG-EFS.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "SG-Instancias-Lab4"
    Env   = "Lab4"
    Owner = "Dani"
  }
}

//Crear el Auto Scaling Group
module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "8.0.0"
  name    = "ASG-Lab4"


  // Creación del Launch template
  launch_template_name        = "LT-Lab4"
  launch_template_description = "Launch Template del Laboratorio 4"
  update_default_version      = true

  image_id          = "ami-06b21ccaeff8cd686"
  instance_type     = "t2.micro"
  ebs_optimized     = true
  enable_monitoring = true
  security_groups   = [aws_security_group.SG-instancias.id]

  // Creación de perfil de instancia IAM
  create_iam_instance_profile = true
  iam_role_name               = "ASG-SSM"
  iam_role_path               = "/ec2/"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  // Atachar el Target Group
   traffic_source_attachments = {
    ex-alb = {
      traffic_source_identifier = aws_lb_target_group.tg-alb.arn
      traffic_source_type      = "elbv2"
    }
  }


  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "ELB"

  user_data = base64encode(<<-EOF
              #!/bin/bash

              sudo yum update -y

              yum install -y amazon-efs-utils nfs-utils httpd

              mkdir -p /mnt/efs

              mount -t efs -o tls ${aws_efs_file_system.EFS-Lab4.id}:/ /mnt/efs

              # Añadir el EFS al /etc/fstab para montaje automático en reinicios
              echo "${aws_efs_file_system.EFS-Lab4.id}:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab

              sudo systemctl enable httpd
              sudo systemctl start httpd

              # Añadir el DNS interno del endpoint de la DB como host
              DB_HOST="postgresql.lab4.internal"

              # Usar el endpoint de la VPC con DNS interno para conectar con el S3
              S3_ENDPOINT="s3.lab4.internal"

              sudo echo "OK" > /var/www/html/health
              EOF
  )

  tags = {
    name = "ASG-1"
  }

  depends_on = [aws_lb_target_group.tg-alb]
}