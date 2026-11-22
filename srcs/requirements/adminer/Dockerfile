FROM alpine:3.23

RUN apk add --no-cache \
	php83 php83-fpm \
	php83-mysqli php83-session curl 

RUN ln -s /usr/bin/php83 /usr/bin/php

RUN sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php83/php.ini

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

RUN curl -fsSL -o /var/www/adminer https://github.com/vrana/adminer/releases/download/v6.3.1/adminer-6.3.1-mysql.php 