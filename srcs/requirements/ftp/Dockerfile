FROM alpine:3.23

RUN apk add --no-cache vsftpd

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf


COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
