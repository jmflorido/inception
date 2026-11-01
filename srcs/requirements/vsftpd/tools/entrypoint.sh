#!/bin/sh

set -e

FTP_USER="${FTP_USER:-ftpuser}"
FTP_USER_PASSWORD=$(cat /run/secrets/ftp_user_password)

if ! id "$FTP_USER" >/dev/null 2>&1; then
	adduser -D -h "/home/$FTP_USER" -s /sbin/nologin "$FTP_USER"
fi
echo "$FTP_USER:$FTP_USER_PASSWORD" | chpasswd

#touch /etc/vsftpd/vsftpd_chroot_list
#echo "$FTP_USER" >> /etc/vsftpd/vsftpd_chroot_list

mkdir -p "/home/$FTP_USER/ftp"
chown root:root "/home/$FTP_USER"
chmod 555 "/home/$FTP_USER"

chown "$FTP_USER:$FTP_USER" "/home/$FTP_USER/ftp"

grep -qx /sbin/nologin /etc/shells || echo /sbin/nologin >> /etc/shells

exec "$@"
