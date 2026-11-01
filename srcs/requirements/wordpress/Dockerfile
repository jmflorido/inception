FROM alpine:3.23

RUN apk add --no-cache php85 php85-fpm php85-phar php85-mysqli php85-openssl \
	php85-curl php85-mbstring php85-zlib php85-ctype php85-dom php85-xml \
	php85-tokenizer php85-pecl-redis mariadb-client curl && \
	echo "memory_limit = 512M" > /etc/php85/conf.d/99-wordpress.ini && \
	# To run properly WP-CLI
	ln -sf /usr/bin/php85 /usr/bin/php && \
	curl -fsSL -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
	chmod +x /usr/local/bin/wp && \
	mkdir -p /var/www/html

COPY conf/zz-docker.conf.template /etc/php85/php-fpm.d/zz-docker.conf.template
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm85", "-F"]

