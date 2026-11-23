FROM alpine:3.23

RUN apk add --no-cache \
	php83 php83-fpm \
	php83-mysqli php83-session curl 

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

RUN curl -fsSL -o --create-dirs /var/www/adminer/index.php https://github.com/vrana/adminer/releases/download/v6.3.1/adminer-6.3.1-mysql.php 

CMD [ "php-fpm83", "-F" ]