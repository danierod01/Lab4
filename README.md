LEER TODO EL README POR FAVOR, PARA COMPRENDER EL CONTEXTO DEL DESARROLLO DEL LABORATORIO.

Lista de comandos usados en la terminal de VS Code para realizar la conexión con el repositorio:

git config --global user.name "danierod01"
git config --global user.email "daniel01mr@gmail.com"
git init
git add .
git commit -m "Primer commit del lab4"
git remote add origin https://github.com/danierod01/Lab4.git
git push -u origin main

Una vez hecho esto, me pide un nombre de usuario, y una contraseña, aquí he usado un token de GitHub, debido a que el anterior se caducó.

 Resumen de la Arquitectura

La infraestructura desplegada consiste en:

1 Componentes de Red
- VPC con subredes públicas y privadas
- ALB externo (público) que escucha en puertos 80/443 con redirección a HTTPS
- ALB interno (privado) que escucha en puerto 80
- CloudFront como CDN conectado al ALB interno

2 Capa de Aplicación
- Auto Scaling Group (ASG) con:
  - Mínimo 2 y máximo 3 instancias
  - Despliegue de Drupal
  - Montaje de EFS para archivos compartidos
  - Configuración de health checks

3 Capa de Datos
- Base de datos PostgreSQL para Drupal
- Redis para caché principal
- Memcached para caché de sesiones
- EFS para almacenamiento compartido de archivos

4 Monitorización
- Alarmas de CloudWatch para:
  - CPU del ASG
  - Errores 5XX del ALB
  - Conexiones a PostgreSQL 
  - CPU de Redis

5 Seguridad
- Certificados SSL/TLS para HTTPS
- Secrets Manager para credenciales de base de datos
- Security Groups específicos para cada componente
- IAM roles y políticas

6 Problemas Identificados
1. Problemas de conexión con la base de datos usando los secretos configurados
2. Problemas con CloudFront en puerto 443 a pesar de tener certificado SSL en el ALB

Hay que aclarar varios puntos:

Cuando se ejecute el código de este laboratorio de terraform, se debe esperar para que las instancias queden configuradas completamente.

Ha habido un problema al final del desarrollo del laboratorio, como bien se dice más abajo, se intenta crear un ASG con una ami personalizada la cual ha sido puesta a disposición del profesor.

Al ejecutar el user data, cloud init no lo interpreta correctamente, por lo que no se ejecuta el user data, aunque esto sí que estaba funcionando durante el desarrollo del laboratorio, y, por cuestiones de tiempo, no se ha podido solucionar. Por esta misma causa, no se podrá usar el EFS, ni se instala directamente Drupal en la Base de Datos, que era el plan inicial de este laboratorio. 

Si el profesor lo desea, puede ejecutar el user data como un script en la instancia, y así se solucionaría el problema.

A la hora de organizar el código, se ha optado por dividirlo según los servicios y recursos que se van a crear, de forma que el mismo código quede mejor estructurado y más fácil de entender. Ya que, si los archivo están en la misma carpeta, al hacer un apply, toma todos los archivos como uno solo, por lo que las referencias a los recursos de otros archivos funcionan.

Para llevar a cabo este laboratorio, se ha creado una AMI a partir de una instancia, a la cual se le han pasado todos los comandos escritos en el archivo "User_Data". Esta AMI ha sido utilizada en el Grupo de Autoscaling, el cual también tiene un user data, el cual usa una serie de condicionantes para comprobar si el efs está montado, y si no lo está, lo monta, al igual que una serie de carpetas, y también la instalación de Drupal, de forma que la primera instancia lo haga y las demás solo tengan que montar el EFS y acceder a la instalación ya creada.

Para garantizar que drush puede usarse con la caché de Redis, se usa en el user data el comando "sudo -u www-data /var/www/html/drupal/vendor/bin/drush pm:enable redis -y", esto habilita el módulo de Redis para Drupal.

Para comprobar que la caché de Redis está funcionando, se usa el comando "sudo -u www-data /var/www/html/drupal/vendor/bin/drush cr", esto limpia la caché de Drupal.

A la hora de usar los comandos del archivo user_data, había que comprobar varias cosas, como por ejemplo:

Para verificar que tanto Redis como Memcached funcionan en la web, se usan los comandos siguientes dentro de una instancia:

redis-cli -h redis.dns_name Este comando se usa para conectarse a Redis desde la terminal de la instancia.

KEYS drupal_* Una vez dentro de Redis, se usa este comando para mostrar el contenido cacheado de Drupal en Redis.

echo "stats" | nc memcached.dns_name 11211 Este comando muestra los datos de memcached, y muestra el número de conexiones y de sesiones almacenadas.

En el uso de KMS y Secrets Manager se han experimentado errores, y se ha decidido no implementarlos para poder asegurar el funcinamiento de la web, ya que al usar la siguiente configuración en settings.php no funcionaba:

<?php

require 'vendor/autoload.php';

use Aws\SecretsManager\SecretsManagerClient;
use Aws\Exception\AwsException;

$client = new SecretsManagerClient([
    'version' => 'latest',
    'region'  => 'us-east-1'  
]);

try {
    $result = $client->getSecretValue([
        'SecretId' => 'postgre-creds',  
    ]);

    $secret = json_decode($result['SecretString'], true);
    } 

catch (AwsException $e) {
    echo "Error al conseguir el secreto: " . $e->getMessage();
}

$settings['hash_salt'] = 'dqmM5gLf3L7lkxBD33Lm-18n0mLDz0p70ctH54-ywS1bvhH8WXwvppxmT52OSNQsLgw0oaO3Wg';
$settings['update_free_access'] = TRUE;
$config_directories['sync'] = '/var/www/html/drupal/config/sync';
$databases['default']['default'] = array (
'database' => 'drupaldb',
'username' => $(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_username.id} --region ${data.aws_region.current.name} --query 'SecretString' --output text),
'password' => $(aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_password.id} --region ${data.aws_region.current.name} --query 'SecretString' --output text),
'prefix' => '',
'host' => 'postgresql.dns_name',
'port' => '5432',
'driver' => 'pgsql',
'namespace' => 'Drupal\\pgsql\\Driver\\Database\\pgsql',
'autoload' => 'core/modules/pgsql/src/Driver/Database/pgsql/',
);
$settings['config_sync_directory'] = 'sites/default/files/config_tkM5Xch2-zZjN9woTj-4GxnI1HmEFwql3dHEJGSzHwM5Aop-UdUmcdu-t-FAHB6btlB7xOTghg/sync';
$settings['redis.connection']['interface'] = 'PhpRedis';
$settings['redis.connection']['host'] = 'redis.dns_name';
$settings['redis.connection']['port'] = '6379';
$settings['cache']['default'] = 'cache.backend.redis';
$settings['cache_prefix']['default'] = 'drupal_';
$settings['cache']['bins']['form'] = 'cache.backend.database';
$settings['container_yamls'][] = 'modules/contrib/redis/redis.services.yml';

if (file_exists($app_root . '/' . $site_path . '/modules/contrib/redis/example.services.yml')) {
    $settings['container_yamls'][] = 'modules/contrib/redis/example.services.yml';
    error_log('Redis services.yml loaded');
}
// Usar Memcached para la caché de sesiones
$settings['memcache']['bins']['session'] = 'default';
ini_set('session.save_handler', 'memcached');
ini_set('session.save_path', 'memcached.dns_name:11211');

Al hacer esta configuración en el archivo settings.php, contando con los secretos que están creados en el archivo KMS, se intentaba la conexión con la base de datos y la página web, y no daba ningún resultado positivo.

Algo parecido pasa con Cloudfront, ya que por el puerto 80 funciona perfectamente, pero cuando se usa por el puerto 443, teniendo el alb un certficiado SSL, daba errores.


