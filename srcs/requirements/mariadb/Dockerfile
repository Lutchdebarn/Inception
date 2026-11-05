FROM alpine:3.23

RUN apk add --no-cache mariadb mariadb-client

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

RUN chmod +755 tools/entrypoint.sh

ENTRYPOINT [ "./tools/entrypoint.sh" ]
