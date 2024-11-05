// Crear instancia en la subred privada
resource "aws_instance" "instancia" {
  ami           = "ami-0866a3c8686eaeeba"
  instance_type = "t2.micro"
  subnet_id     = module.vpc.private_subnets
  iam_instance_profile = aws_iam_instance_profile.profileSSM.name
  security_groups = [aws_security_group.SG-instancias.id]
  user_data = base64encode(<<-EOF
              #!/bin/bash

              # Actualizar paquetes y el sistema
              sudo apt update -y
              sudo apt upgrade -y
              

              # Instalar los recursos necesarios para montar el EFS, servidor Apache, PHP, y las extensiones que son necesarias para drupal
              sudo apt install -y amazon-efs-utils nfs-utils jq apache2 libapache2-mod-php php8.3 php8.3-cli php8.3-common php8.3-pgsql php8.3-zip php8.3-gd php8.3-mbstring php8.3-curl php8.3-xml php8.3-bcmath php8.3-redis postgresql-client postgresql
              
              # Instalar cliente CLI de AWS
              sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              sudo unzip awscliv2.zip
              sudo ./aws/install

              # Habilitar apache
              sudo systemctl enable apache2
              sudo systemctl start apache2

              # Obtener las credenciales de la Base de Datos PostgreSQL
              SECRET_NAME="${postgre_credentials}"
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

              # Comprobar que el Document Root es /var/www/html/drupal, y si no, cambiarlo
              if ! grep -qs "DocumentRoot /var/www/html/drupal" /etc/apache2/sites-available/000-default.conf; then sudo sed -i 's|DocumentRoot/var/www/html|DocumentRoot/var/www/html/drupal|' /etc/apache2/sites-available/000-default.conf fi
              

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
                  'database' => 'drupaldb',
                  'username' => '${DB_USERNAME}',
                  'password' => '${DB_PASSWORD}',
                  'host' => '${postgresql.lab4.internal}',  # Reemplaza con el endpoint DNS interno de RDS
                  'port' => '5432',
                  'prefix' => '',
                );

                EOT
                
                sudo mkdir -p /mnt/efs/drupal

                if ! grep -qs "${efs.lab4_internal}:/ /mnt/efs/drupal nfs4" /etc/fstab; then echo "${efs.lab4_internal}:/ /mnt/efs/drupal nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab fi
                
                sudo mount -a

                # Añadir el DNS interno del endpoint de la DB como host
                DB_HOST="${postgresql.lab4.internal}"

                # Usar el endpoint de la VPC con DNS interno para conectar con el S3
                S3_ENDPOINT="${s3.lab4.internal}"

                # Crear un archivo de estado para la salud de las instancias
                sudo echo "OK" > /var/www/html/health
                EOF
  )
  vpc_security_group_ids = [aws_security_group.instance.id]
  tags = merge(var.tags, {
    additional_tag = "Instancia-Lab4"
  })
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [aws_lb_target_group.tg-alb]
}
