FROM alpine:3.23

RUN apk add --no-cache wget php85 php85-mysqli php85-phar \
	php85-fpm php85-openssl php85-openssl php85-curl \
	php85-mbstring php85-zlib php85-ctype php85-dom php85-xml \
	php85-tokenizer php85-pecl-redis 

RUN mkdir -p /var/www

RUN wget https://www.adminer.org/latest.php -O /var/www/adminer.php

EXPOSE 8080

WORKDIR /var/www

CMD ["php85", "-S", "0.0.0.0:8080", "adminer.php"] 
