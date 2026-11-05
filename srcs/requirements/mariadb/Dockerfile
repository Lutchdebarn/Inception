FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/entrypoint /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "./tools/entrypoint.sh" ]
