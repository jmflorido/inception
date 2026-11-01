FROM alpine:3.23

RUN apk add --no-cache nginx openssl && mkdir -p /run/nginx

COPY conf/nginx.conf.template /etc/nginx/nginx.conf.template
COPY html/ /var/www/html/
RUN mkdir -p /var/www/html/joflorid
COPY joflorid_web/* /var/www/html/joflorid
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# CMD ["-V"]
CMD ["nginx", "-g", "daemon off;"]
