#!/bin/bash

# crear el directorio
mkdir -p /var/www/html

# Esperar hasta que el servicio mariadb esté en funcionamiento
while ! nc -z mariadb 3306; do
    sleep 1
done

cd /var/www/html
rm -rf *
# Descargar WP en español.
wp core download --locale=es_ES --allow-root
#Asegura que WordPress se conecte correctamente a la base de datos de MariaDB durante el proceso de instalación y configuración.
wp --path=/var/www/html  config create --dbname=${MYSQL_DATABASE} --dbuser=${MYSQL_USER} --dbpass=${MYSQL_PASSWORD} --dbhost=${MYSQL_HOST} --locale=es_ES --allow-root --skip-check
# Por ejemplo, puedes usar WP-CLI para configurar WordPress en este punto
# Ejemplo: wp core install --url=http://mi-sitio.com --title="Mi Sitio" --admin_user=admin --admin_password=password --admin_email=info@mi-sitio.com
wp core install --path=/var/www/html --url=${DOMAIN_NAME} --title="INZEZION!!!" --admin_name=${WP_ADMIN_USER} --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASSWORD} --admin_email="iportill@student.42urduliz.com" --skip-email --allow-root 