FROM alpine:3.23

RUN apk add --no-cache nginx openssl && mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
	-out /etc/nginx/ssl/inception.crt \
	-keyout /etc/nginx/ssl/inception.key \
	-subj "/C=CH/ST=VD/L=Lausanne/O=42/OU=42/CN=ludebarn.42.fr/UID=ludebarn"

RUN mkdir -p var/www/html

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443
CMD [ "nginx", "-g", "daemon off;" ]
