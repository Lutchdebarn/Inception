FROM alpine:3.23

RUN apk add --no-cache mariadb-client

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY tools/backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
