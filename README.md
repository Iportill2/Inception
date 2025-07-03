# Proyecto Inception - Docker LEMP Stack

## Descripción del Proyecto

Este proyecto implementa una infraestructura completa de servicios web utilizando Docker y Docker Compose. La arquitectura incluye un stack LEMP (Linux, Nginx, MariaDB, PHP) containerizado que proporciona un entorno de WordPress completamente funcional.

## Índice

1. [Preparación del Entorno 🛠️](#1--preparación-del-entorno-)
2. [Arquitectura del Sistema 📄](#2--arquitectura-del-sistema-)
3. [Configuración de Nginx 🌐](#3--configuración-de-nginx-)
4. [Configuración de MariaDB 🗄️](#4--configuración-de-mariadb-)
5. [Configuración de WordPress 📝](#5--configuración-de-wordpress-)
6. [Guía de Uso 🚀](#6--guía-de-uso-)

## 1- Preparación del Entorno 🛠️

### Requisitos del Sistema

Para este proyecto necesitarás:
- Una máquina virtual con Debian (recomiendo la versión estable más reciente)
- Docker y Docker Compose instalados
- Al menos 4GB de RAM y 20GB de espacio en disco

### Instalación de Dependencias

```bash
# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
sudo apt install docker.io docker-compose -y

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER
```

## 2- Arquitectura del Sistema 📄

### Visión General

Mi implementación utiliza una arquitectura de microservicios containerizada que separa claramente las responsabilidades:


- **Nginx**: Servidor web y proxy reverso con SSL/TLS
- **MariaDB**: Sistema de gestión de base de datos
- **WordPress**: CMS con PHP-FPM para procesamiento dinámico

### Configuración de Red

He implementado una red bridge personalizada llamada `iportillnet` que permite la comunicación segura entre contenedores:

```yaml
networks:
    iportillnet:
        name: iportillnet
        driver: bridge
```

Esta configuración aísla los servicios del proyecto del resto del sistema, proporcionando mayor seguridad y control sobre el tráfico de red.

### Configuración de Servicios

#### Servicio Nginx
```yaml
services:
    nginx:
        container_name: nginx
        build: ./requirements/nginx
        image: nginx
        ports:
        - 443:443
        volumes:
        - wordpress_data:/var/www/html
        restart: always
        networks:
        - iportillnet
```

**Decisiones de diseño implementadas:**

- **Puerto 443**: Configuré HTTPS únicamente para mayor seguridad
- **Volumen compartido**: Nginx sirve directamente los archivos estáticos de WordPress
- **Restart always**: Garantiza alta disponibilidad del servicio web

#### Servicio MariaDB
```yaml
mariadb:
    container_name: mariadb
    build:
       context: ./requirements/mariadb
    image: mariadb
    volumes:
     - mariadb_data:/var/lib/mysql
    restart: always
    networks:
     - iportillnet
    env_file:
     - .env
```

**Características implementadas:**
- Persistencia de datos mediante volúmenes Docker
- Configuración mediante variables de entorno para mayor flexibilidad
- Aislamiento de red para seguridad de la base de datos

#### Servicio WordPress
```yaml
wordpress:
    container_name: wordpress
    build: ./requirements/wordpress
    image: wordpress
    depends_on:
     - mariadb
    volumes:
     - wordpress_data:/var/www/html
    restart: always
    networks:
     - iportillnet
    env_file:
     - .env
```

**Dependencias y optimizaciones:**
- Dependencia explícita de MariaDB para orden de inicio correcto
- Volumen compartido con Nginx para servir contenido estático eficientemente
- Configuración centralizada mediante archivo `.env`

### Gestión de Volúmenes

He diseñado un sistema de persistencia de datos robusto utilizando bind mounts para garantizar que los datos sobrevivan a los reinicios de contenedores:

```yaml
volumes:
    mariadb_data:
        driver: local
        driver_opts:
            type: none
            device: /home/iportill/data/mysql
            o: bind

    wordpress_data:
        driver: local
        driver_opts:
            type: none
            device: /home/iportill/data/wordpress
            o: bind
```

**Ventajas de mi implementación:**
- **Persistencia garantizada**: Los datos se almacenan directamente en el sistema de archivos del host
- **Backup simplificado**: Fácil acceso a los datos desde el sistema host
- **Performance optimizada**: Acceso directo sin capas adicionales de abstracción

## 3- Configuración de Nginx 🌐

### Arquitectura del Contenedor

Mi implementación de Nginx se basa en Debian para cumplir con los requisitos del proyecto, evitando imágenes preconfiguradas:

### Dockerfile Personalizado

```dockerfile
FROM debian:10.11

RUN apt-get update && apt-get install -y nginx openssl

EXPOSE 443

COPY ./conf/default /etc/nginx/sites-enabled/default
COPY ./tools/nginx_start.sh /var/www

RUN chmod +x /var/www/nginx_start.sh

ENTRYPOINT [ "/var/www/nginx_start.sh" ]
CMD ["nginx", "-g", "daemon off;"]
```

**Decisiones de implementación:**
- **Base Debian**: Elegí Debian 10.11 por su estabilidad y compatibilidad
- **Instalación manual**: Nginx y OpenSSL instalados desde repositorios oficiales
- **SSL obligatorio**: Solo expongo el puerto 443 para forzar HTTPS
- **Script de inicialización**: Automatizo la generación de certificados SSL

### Script de Inicialización SSL

Desarrollé un script bash que gestiona automáticamente los certificados SSL:

```bash
#!/bin/bash
if [ ! -f /etc/ssl/certs/nginx.crt ]; then
    echo "Configurando SSL para iportill.42.fr..."
    openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
        -keyout /etc/ssl/private/nginx.key \
        -out /etc/ssl/certs/nginx.crt \
        -subj "/C=ES/ST=Urduliz/L=Urduliz/O=inception/CN=iportill.42.fr"
    echo "Certificado SSL generado correctamente"
fi
exec "$@"
```

**Características del certificado:**
- **Autofirmado**: Ideal para desarrollo y testing
- **RSA 4096 bits**: Máxima seguridad criptográfica
- **Validez 365 días**: Renovación anual
- **Sin contraseña**: Automatización completa del proceso

### Configuración del Servidor Virtual

Mi configuración de Nginx está optimizada para servir WordPress con máxima seguridad y rendimiento:

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name iportill.42.fr;

    ssl_certificate /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
    ssl_protocols TLSv1.3;

    index index.php;
    root /var/www/html;
    
    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        fastcgi_read_timeout 300;
    }
}
```

**Optimizaciones implementadas:**
- **TLS 1.3 exclusivamente**: Máxima seguridad en comunicaciones
- **HTTP/2**: Mejor rendimiento para múltiples recursos
- **FastCGI optimizado**: Comunicación eficiente con PHP-FPM
- **URL rewriting**: URLs amigables para WordPress

## 4- Configuración de MariaDB 🗄️

### Contenedor de Base de Datos

Implementé MariaDB desde cero utilizando Debian como base:

### Dockerfile

```
FROM debian:10.11

RUN apt-get update && \
	apt-get install -y \
	mariadb-server

COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/50-server.cnf

RUN mkdir -p /var/run/mysqld \
	&& chown -R mysql:mysql /var/run/mysqld \
	&& chmod 777 /var/run/mysqld

EXPOSE 3306

COPY ./tools/mariadb.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/mariadb.sh

RUN mysql_install_db

ENTRYPOINT [ "/usr/local/bin/mariadb.sh" ]
```

### Conf file



### Script MariaDB



🔴 Inicia el servicio MySQL. El servidor estara lito para aceptar conexiones.

🟠 Condicion que si no existe el directorio de la base de datos entrara al if. Si no se cumple la condicion directamente pasara al paso 🟤.

🟡 Nos conectamos a MySQL mediante nuestro usuario y contraseña (utilizamos las variables de entorno) y ejecutamos la instruccion ```CREATE DATABASE $MYSQL_DATABASE;``` para crear una nueva base de datos con el nombre almacenado en la variable de entorno.

🟢 Crearemos un usuario dentro de la base de datos especificando el nombre y la contraseña (utilizamos las variables de entorno).

🌐 Le concedemos todos los permisos al usuario recien creado para que pueda acceder a la base de datos y realizar cualquier operación en las tablas.

🔵 Actualizamos los privilegios para que los cambio realizados se apliquen.

🟣 Cambiamos la contraseña por defecto del usuario root de MySQL a la que tenemos almacenada en nuestra variable de entorno.

🟤 Apagamos el servidor utilizando el usuario y contraseña de root.

⚪️ Iniciamos el servidor MySQL de nuevo. Hemos realizado este reinicio para que el servidor se inicie con la configuracion y cambios realizados en el script.

## 6- Configuración WordPress ✍🏻

### Dockerfile

```
FROM debian:10.11

RUN apt-get update && apt-get -y install \
    curl \
    php7.3-fpm \
    php7.3-mysqli \
    mariadb-client

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY conf/www.conf /etc/php/7.3/fpm/pool.d/

RUN mkdir -p /run/php
RUN chmod 755 /run/php

COPY ./tools/wp.sh /usr/local/bin/wp.sh
RUN chmod +x /usr/local/bin/wp.sh

EXPOSE 9000

WORKDIR /var/www/html/

ENTRYPOINT [ "/usr/local/bin/wp.sh" ]
```



### Script Wordpress



1º Se verifica si el archivo no existe , de ser asi se entra al if.

2º Descarga el núcleo de WordPress utilizando la herramienta WP-CLI. La opción ```--allow-root``` permite ejecutar WP-CLI como el usuario root.

3º Creamos el archivo de configuracion ```wp-config.php``` con los detalles de la base de datos proporcionado a traves de variables de entorno.

4º Realizamos la instalacion de WordPress con los parametros proporcionados en las vaiables de entorno. La opcion --skip-email evita que se envie un correo electronico de notificacion.

5º Creamos un nuevo usuario de WordPress con el nombre, correo y contraseña proporcionados en las variables de entorno. En este caso al usuario nuevo se le asigna el rol de autor.

6º Descargamos, instalamos y activamos el tema twentysixteen.

7º Iniciamos el servicio PHP-FPM en segundo plano y lo dejamos en ejecucion constante con -F.


# Autor 
Iker Portillo
















