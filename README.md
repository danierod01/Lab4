Terraform AWS Lab - Infraestructura como Código

Este proyecto utiliza Terraform para provisionar infraestructura completa en Amazon Web Services (AWS) de forma automatizada, segura y escalable. Forma parte de un laboratorio avanzado de despliegue de servicios cloud bajo el enfoque de Infrastructure as Code (IaC).

Tecnologías utilizadas
Terraform v1.7.0 o superior
AWS Provider v5.35.0
Amazon Web Services (AWS)
IDE: Visual Studio Code / Terraform CLI

Recursos AWS desplegados
Este script despliega los siguientes recursos:
-	VPC y peering de VPCs
-	Instancias EC2 con Auto Scaling y ALB
-	RDS (Relational Database Service)
-	ElastiCache para caching
-	EFS (Elastic File System)
-	S3 buckets
-	CloudFront + Route 53
-	IAM roles y políticas
-	CloudWatch y SNS para monitoreo y alertas
-	KMS para cifrado de datos

Cómo usar este proyecto
1.	Clonar el repositorio

	git clone https://github.com/danierod01/Lab4.git
	cd Lab4

2.	Configurar tus credenciales de AWS
Puedes exportarlas en tu terminal o usar un perfil configurado con aws configure.

	export AWS_ACCESS_KEY_ID=your_key
	export AWS_SECRET_ACCESS_KEY=your_secret

3.	Inicializar Terraform

	terraform init

4.	Ver plan de ejecución

	terraform plan

5.	Aplicar los cambios

	terraform apply

6.	(Opcional) Destruir al infraestructura

	terraform destroy


Estructura del repositorio
Archivo/Carpeta  	Descripción
ALB.tf	           Define un Application Load Balancer para distribuir tráfico entre instancias.
ASG.tf	           Configura un Auto Scaling Group para escalar dinámicamente EC2.
CloudWatch.tf     Crea alarmas y métricas con CloudWatch para monitoreo.
EFS.tf	           Implementa un Elastic File System compartido entre instancias.
Elasticache.tf	   Crea un clúster de ElastiCache para almacenamiento en caché.
IAM.tf	           Define roles y políticas de acceso (IAM) necesarios.
RDS.tf	           Despliega una base de datos RDS para almacenamiento estructurado.
Route53.tf        Gestiona registros DNS a través de Route 53.
SNS.tf	           Configura un topic de SNS para notificaciones y alertas.
VPC Peering.tf	   Establece peering entre VPCs para comunicación privada.
VPC.tf	           Crea una VPC principal con subredes, tablas de ruteo y gateways.
Variables.tf      Define variables de entrada reutilizables en el proyecto.
providers.tf	     Configura el proveedor de AWS necesario para Terraform.
s3.tf	            Crea buckets de S3 para almacenamiento u otros propósitos.

Carpetas adicionales
Carpeta	          Descripción
KMS/	             Define recursos del servicio de cifrado KMS.
cloudfront/	      Configura una distribución de CloudFront para entrega optimizada de contenido.
user_data/	       Contiene scripts para la configuración automática de instancias EC2 al iniciar.
Certificados/	    Almacena certificados o configuraciones relacionadas con seguridad y cifrado TLS/SSL.

Archivos adicionales
Archivo	          Descripción
.gitignore	       Archivos y carpetas excluidos del control de versiones.
Diagrama_Lab4.pdf	Diagrama visual de la arquitectura desplegada.
imagen.jpg	       Imagen usada para el contenedor S3.
README.md	        Este archivo, con toda la documentación del proyecto.

Consideraciones
Asegúrate de contar con permisos adecuados en tu cuenta AWS.
No subas claves de acceso ni archivos sensibles (terraform.tfvars, .tfstate, etc.).
Puedes usar backend remoto (ej. S3 + DynamoDB) para almacenar el estado en producción.
	
Contribuciones
Contribuciones, ideas y sugerencias son bienvenidas. ¡No dudes en abrir un pull request o issue!

Licencia
Este proyecto está bajo la licencia MIT. Consulta e	l archivo LICENSE para más detalles.
de datos y la página web, y no daba ningún resultado positivo.



