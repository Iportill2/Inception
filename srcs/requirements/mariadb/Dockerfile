FROM debian:bullseye

COPY ./conf/*  /tmp/

#RUN apt-get update && apt-get -y install mariadb-server \
#	&&  service mysql start && chmod +x /tmp/create.sh && chmod +x /tmp/init.sh \
#	&& /tmp/init.sh


RUN apt-get update
RUN apt-get -y install mariadb-server
RUN service mariadb start
RUN chmod +x /tmp/create.sh
RUN chmod +x /tmp/init.sh
RUN /tmp/init.sh


EXPOSE 3306

CMD [ "sh", "-c", "./tmp/create.sh > /tmp/create.sql && mysqld --init-file=/tmp/create.sql"]