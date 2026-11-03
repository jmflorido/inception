#!/bin/sh

#Script aborts if any command fails
set -e

DOMAIN_NAME="${DOMAIN_NAME:-joflorid.42.fr}"
SSL_DIR=/etc/nginx/ssl

#Generating self-signed certificate if there is not
if [ ! -f "$SSL_DIR/server.crt" ] || [ ! -f "$SSL_DIR/server.key" ]; then
	echo "Generating self-signed certificate for $DOMAIN_NAME"
	mkdir -p "$SSL_DIR"
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "$SSL_DIR/server.key" \
		-out "$SSL_DIR/server.crt" \
		-subj "/CN=$DOMAIN_NAME" \
		-addext "subjectAltName=DNS:$DOMAIN_NAME, DNS:portainer.$DOMAIN_NAME"
	chmod u=rw,go= "$SSL_DIR/server.key"
fi

#Substituting the domain name in the nginx config file
sed "s/__DOMAIN_NAME__/$DOMAIN_NAME/g" /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

#Return back the PID 1 to nginx (after execute shell)
exec "$@"
