FROM alpine:3.23

RUN apk add --no-cache vsftpd netcat-openbsd
COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY --chmod=755 tools/entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 21

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
