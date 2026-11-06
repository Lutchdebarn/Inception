FROM alpine:3.23


#connexion a mariadb, telechargement des mise a jours et pr que wordpress
#parle en https
#traitement du texte, du XML et des images
RUN apk add --no-cache \
	php83 php83-fpm \
	php83-mysqli php83-curl php83-mbstring php83-xml php83-gd \
	php83-openssl php83-phar php83-iconv php83-ctype php83-dom \
	php83-session php83-zip php83-fileinfo php83-tokenizer \
	curl mariadb-client

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

RUN curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp
