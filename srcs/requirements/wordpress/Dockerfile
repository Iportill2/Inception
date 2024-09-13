FROM debian:bullseye

COPY ./conf/setup.sh /tmp

RUN apt-get update && apt -y install curl wget netcat tar
RUN apt install -y php php-fpm php-mysql php-gd php-xml php-curl
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar  && mv -f wp-cli.phar /usr/local/bin/wp
RUN chmod +x /tmp/setup.sh



COPY ./conf/www.conf  /etc/php/7.4/fpm/pool.d/

RUN sed -i 's/^pid = \/run\/php\/php7\.4-fpm\.pid$/pid = \/var\/run\/php-fpm7.4.pid/' /etc/php/7.4/fpm/php-fpm.conf

EXPOSE 9000

CMD [ "sh", "-c", "./tmp/setup.sh && /usr/sbin/php-fpm7.4 -F" ]