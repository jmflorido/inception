FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

VOLUME home/joflorid/data/mariadb /var/lib/mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["mariadbd", "--user=mysql"]

