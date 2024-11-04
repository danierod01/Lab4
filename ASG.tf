
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
  
  tags = merge(var.tags, {
    additional_tag = "SG-Instancias-Lab4"
  })
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

  image_id          = "ami-0866a3c8686eaeeba"
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

              # Actualizar paquetes y el sistema
              sudo apt update -y
              sudo apt upgrade -y
              

              # Instalar los recursos necesarios para montar el EFS, servidor Apache, PHP, y las extensiones que son necesarias para drupal
              sudo apt install -y amazon-efs-utils nfs-utils -y apache2 php libapache2-mod-php php-cli php-curl php-gd php-xml php-mbstring php-zip php-json php-pgsql 

              # Instalar cliente CLI de AWS
              sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo unzip awscliv2.zip
              sudo ./aws/install

              # Habilitar apache
              sudo systemctl enable apache2
              sudo systemctl start apache2

              # Obtener las credenciales de la Base de Datos PostgreSQL
              SECRET_NAME="postgre_credentials"
              REGION="us-east-1"

              DB_CREDS=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)
              DB_USERNAME=$(echo $DB_CREDS | jq -r .username)
              DB_PASSWORD=$(echo $DB_CREDS | jq -r .password)

              # Instalación de drupal

              # Instalar el cliente de PostgreSQL
              sudo apt install -y postgresql-client

              # Habilitar el módulo rewrite de Apache para que funcione con Drupal
              sudo a2enmod rewrite

              # Descargar Drupal y descomprimir en /var/www/html/drupal
              sudo cd /tmp
              curl -sSL https://www.drupal.org/download-latest/tar.gz -o drupal.tar.gz
              sudo tar -xzf drupal.tar.gz
              sudo mv drupal-* /var/www/html/drupal

              # Configurar permisos para que Apache pueda acceder a los archivos de Drupal
              sudo chown -R www-data:www-data /var/www/html/drupal
              sudo chmod -R 755 /var/www/html/drupal

              # Crear un archivo de configuración Virtual Host para Drupal
              sudo cat <<EOF | sudo tee /etc/apache2/sites-available/drupal.conf
              <VirtualHost *:80>
                  ServerAdmin admin@example.com
                  DocumentRoot /var/www/html/drupal
                  ServerName alb.lab4_internal

                  <Directory /var/www/html/drupal>
                      AllowOverride All
                      Require all granted
                  </Directory>

                  ErrorLog \${APACHE_LOG_DIR}/drupal_error.log
                  CustomLog \${APACHE_LOG_DIR}/drupal_access.log combined
              </VirtualHost>
              EOF>>

              # Habilitar el nuevo sitio en Apache
              sudo a2ensite drupal.conf

              # Reiniciar Apache para aplicar cambios
              sudo systemctl restart apache2

              # Crear archivo settings.php para Drupal con configuración para PostgreSQL
              sudo cd /var/www/html/drupal/sites/default
              sudo cp default.settings.php settings.php

              # Se hace a apache el propietario del archivo
              sudo chown -R www-data:www-data /var/www/html/drupal/sites/default/settings.php

              # Darle permisos de lectura y escritura
              sudo chmod 666 /var/www/html/drupal/sites/default/settings.php

              # Se crea el directorio /Files
              sudo mkdir files

              # Se hace a apache propietario de la carpeta files
              sudo chown -R www-data:www-data /var/www/html/drupal/sites/default/files

              # Se le da permisos de todo al propietario, y a otros de lectura y escritura
              sudo chmod -R 755 /var/www/html/drupal/sites/default/files

              # Se crea la carpeta translations
              sudo mkdir /var/www/html/drupal/sites/default/files/translations

              # Cambiar el propietario de la carpeta y su contenido a www-data
              sudo chown -R www-data:www-data /var/www/html/drupal/sites/default/files/translations

              # Asignar permisos 755 a la carpeta translations
              sudo chmod 755 /var/www/html/drupal/sites/default/files/translations

              # Asignar permisos 644 a todos los archivos dentro de translations
              sudo find /var/www/html/drupal/sites/default/files/translations -type f -exec chmod 644 {} \;

            # Asegurarse de que todas las subcarpetas dentro de translations tengan permisos 755
            sudo find /var/www/html/drupal/sites/default/files/translations -type d -exec chmod 755 {} \;

                cat <<EOT >> /var/www/html/sites/default/settings.php

                \$databases['default']['default'] = array (
                  'driver' => 'pgsql',
                  'database' => 'mydb',
                  'username' => '$DB_USERNAME',
                  'password' => '$DB_PASSWORD',
                  'host' => 'db.internal.example.com',  # Reemplaza con el endpoint DNS interno de RDS
                  'port' => '5432',
                  'prefix' => '',
                );

                EOT

                
                sudo mkdir -p /mnt/efs

                mount -t efs -o tls ${aws_efs_file_system.EFS-Lab4.id}:/ /mnt/efs

                # Añadir el EFS al /etc/fstab para montaje automático en reinicios
                echo "${aws_efs_file_system.EFS-Lab4.id}:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab

                

                # Añadir el DNS interno del endpoint de la DB como host
                DB_HOST="postgresql.lab4.internal"

                # Usar el endpoint de la VPC con DNS interno para conectar con el S3
                S3_ENDPOINT="s3.lab4.internal"

                # Crear un archivo de estado para la salud de las instancias
                sudo echo "OK" > /var/www/html/health
                EOF
  )

  tags = merge(var.tags, {
    additional_tag = "ASG-Lab4"
  })

  depends_on = [aws_lb_target_group.tg-alb]
}