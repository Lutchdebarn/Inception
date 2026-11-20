#! /bin/sh

set -e

# Ask if the user exists and /dev/null 2>&1 hide for only the return code
if ! id "$FTP_USER" > /dev/null 2>&1; then
	adduser -D "$FTP_USER"
	echo "$FTP_USER:$(cat /run/secrets/ftp_password)" | chpasswd
fi

exec vsftpd /etc/vsftpd/vsftpd.conf
