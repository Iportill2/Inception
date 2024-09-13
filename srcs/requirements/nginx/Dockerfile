#base image
FROM debian:bullseye

#Updates the package list and installs Nginx and OpenSSL.
RUN apt-get update && apt-get install -y nginx openssl

#Create SSL Directory and Generate SSL Certificate
RUN mkdir /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/iportill.key \
	-out /etc/nginx/ssl/iportill.crt \
	-subj "/CN=iportill.42.fr"

#Copy Nginx Configuration and HTML File
COPY ./conf/nginx.conf /etc/nginx/conf.d
COPY ./tools/index.html /usr/share/nginx/html/

EXPOSE 443


CMD [ "nginx", "-g", "daemon off;" ]