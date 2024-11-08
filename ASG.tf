
//Crear Security Group de las instancias
resource "aws_security_group" "SG-instancias" {
  name        = "SG-instancias"
  description = "Security Group de instancias"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_externo_sg.id]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.SG-EFS.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_externo_sg.id]
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.SG-PSQL.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "SG-Instancias-Lab4"
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

  image_id          = "ami-0aa516a66ab111371"
  instance_type     = "t2.micro"
  ebs_optimized     = true
  enable_monitoring = true
  security_groups   = [aws_security_group.SG-instancias.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash -e

    # 1. Montar el EFS si no está montado
    if ! mountpoint -q "/mnt/efs"; then
      echo "EFS no está montado en /mnt/efs, montándolo..."
      sudo mkdir -p "/mnt/efs"
      sudo mount -t nfs4 efs.dns_name:/ /mnt/efs
    else
      echo "EFS ya está montado en /mnt/efs"
    fi

    # 2. Verificar y crear carpeta /mnt/efs/drupal si no existe
    if [ ! -d "/mnt/efs/drupal/" ]; then
      echo "Directorio /mnt/efs/drupal/ no existe. Creándolo..."
      sudo mkdir -p "/mnt/efs/drupal/"
    fi

    # 3. Verificar y copiar contenido si /mnt/efs/drupal está vacío (y evitar sobrescribir)
    if [ -d "/var/www/html/drupal" ] && [ -z "$(ls -A "/mnt/efs/drupal")" ]; then
      echo "Copiando contenido de /var/www/html/drupal a /mnt/efs/drupal..."
      sudo cp -R "/var/www/html/drupal/"* "/mnt/efs/drupal"
    else
      echo "/mnt/efs/drupal ya tiene contenido; no se realiza la copia."
    fi

    # 4. Crear carpeta de respaldo y mover la instalación actual de Drupal si existe
    if [ -d "/var/www/html/drupal" ]; then
      echo "Creando respaldo en /var/www/html_backup y moviendo /var/www/html/drupal..."
      sudo mkdir -p "/var/www/html_backup"
      sudo mv "/var/www/html/drupal" "/var/www/html_backup"
    fi  

    # 5. Crear enlace simbólico desde /var/www/html/drupal a /mnt/efs/drupal
    if [ ! -L "/var/www/html/drupal" ]; then
      echo "Creando enlace simbólico entre /var/www/html/drupal y /mnt/efs/drupal..."
      sudo ln -s "/mnt/efs/drupal" "/var/www/html/drupal"
    fi  

    sudo chown -R www-data:www-data "/var/www/html/drupal/sites/default/files"
    sudo chmod -R 775 "/var/www/html/drupal/sites/default/files"

    sudo curl -o /var/www/html/drupal/.htaccess https://raw.githubusercontent.com/drupal/drupal/9.0.x/.htaccess

    sudo chown www-data:www-data /var/www/html/drupal/.htaccess
    sudo chmod 644 /var/www/html/drupal/.htaccess

    sudo -u www-data /var/www/html/drupal/vendor/bin/drush pm:enable redis -y

    # 6. Verificar si Drupal está instalado en la base de datos
      if sudo -u www-data /var/www/html/drupal/vendor/bin/drush sql:connect; then
  if ! sudo -u www-data /var/www/html/drupal/vendor/bin/drush status --field=db-status | grep -q "Connected"; then
    echo "Instalando Drupal en la base de datos..."
    sudo -u www-data/var/www/html/drupal/vendor/bin/drush site:install \
      --db-url="pgsql://postgres:password1.2.3.4.@postgresql.dns_name/drupaldb" \
      --site-name="Laboratorio 4 Daniel Muñoz" \
      --account-name="admin" \
      --account-pass="adminpassword"  -y
    # Asegurarse de que el nombre se aplique correctamente
    sudo -u www-data /var/www/html/drupal/vendor/bin/drush config-set "system.site" name "Laboratorio 4 Daniel Muñoz" -y
      else
        echo "Drupal ya está instalado en la base de datos."
      fi
    else
      echo "No se pudo conectar a la base de datos. Verificar configuración."
    fi
    sudo systemctl restart apache2

    echo "OK" > /var/www/html/drupal/health

EOF
  )

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
      traffic_source_identifier = aws_lb_target_group.tg-alb-externo.arn
      traffic_source_type       = "elbv2"
    }
  }


  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type   = "ELB"

  tags = merge(var.tags, {
    Name = "ASG-Lab4"
  })

  depends_on = [aws_lb_target_group.tg-alb-interno, aws_efs_file_system.EFS-Lab4, 
  aws_db_instance.PSQL-Lab4, aws_elasticache_replication_group.redis_lab4, aws_elasticache_cluster.memcached_lab4]
}