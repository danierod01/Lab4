Lista de comandos usados en la terminal de VS Code para realizar la conexión con el repositorio:

git config --global user.name "danierod01"
git config --global user.email "daniel01mr@gmail.com"
git init
git add .
git commit -m "Primer commit del lab4"
git remote add origin https://github.com/danierod01/Lab4.git
git push -u origin main

Una vez hecho esto, me pide un nombre de usuario, y una contraseña, aquí he usado un token de GitHub, debido a que el anterior se caducó.

Hay que aclarar varios puntos:

El comando del user data de Instancia.tf: if ! grep -qs "DocumentRoot /var/www/html/drupal" /etc/apache2/sites-available/000-default.conf; then sudo sed -i 's|DocumentRoot/var/www/html|DocumentRoot/var/www/html/drupal|' /etc/apache2/sites-available/000-default.conf fi, lo que hace es comprobar primero si el Document Root no es /var/www/html/drupal, gracias a "!", y si esta condición se cumple, escribe directamente en el archivo original el DocumentRoot deseado, /var/www/html/drupal.

Para poder realiar el anterior caso había varias opciones, como por ejemplo realizar un nuevo archivo llamado "drupal.conf", en el que se escribía directamente toda la configuración necesaria, pero se ha decidido usar este método dado que usa el archivo original de configuración de Apache.

Algo parecido pasa con el montaje del EFS, donde se usa el siguiente comando: if ! grep -qs "${efs.lab4_internal}:/ /mnt/efs/drupal nfs4" /etc/fstab; then echo "${efs.lab4_internal}:/ /var/www/html/drupal nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" | sudo tee -a /etc/fstab fi, que comprueba si la línea "${efs.lab4_internal}:/ /mnt/efs/drupal nfs4" NO se encuentra en /etc/fstab, y si se cumple la condición y no está en el archivo, se escribe a mano toda la configuración del EFS en dicho archivo, incluyendo el montaje automático al reiniciar la instancia.

Para esta ocasión, se ha decidido usar este método debido a que asegura el buen funcionamiento del montaje del EFS, ya que otras opciones no comprobaban si dicho EFS estaba montado.
