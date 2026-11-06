#!/bin/sh

set -e

WP_PATH=/var/www/html

WP_UID="${WP_UID:-1000}"
WP_TEMP_USER="$WP_TEMP_USER"

if [ "$HTTPS_PORT" = "443" ]; then
	SITE_URL="https://$DOMAIN_NAME"
else
	SITE_URL="https://$DOMAIN_NAME:$HTTPS_PORT"
fi

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

# Creating a temp user with uid WP_UID to create all the wp files with it avoiding permission issues with ftp service.

if ! id "$WP_TEMP_USER" >/dev/null 2>&1; then
	addgroup -g "$WP_UID" "$WP_TEMP_USER"
	adduser -D -H -u "$WP_UID" -G "$WP_TEMP_USER" -s /sbin/nologin "$WP_TEMP_USER"
fi

sed -e "s/__WP_TEMP_USER__/$WP_TEMP_USER/g" \
	/etc/php85/php-fpm.d/zz-docker.conf.template \
	> /etc/php85/php-fpm.d/zz-docker.conf

# Check if admin is in username
case "$(echo "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')" in *admin*)
	echo "Error: env variable WP_ADMIN_USER cannot contain 'admin'" >&2
	exit 1
	;;
esac

# Wait for mariadb
until mariadb-admin ping -h mariadb -P 3307 -u"$MYSQL_USER" -p"$DB_PASSWORD" --skip-ssl --silent; do
	echo "Waiting to MariaDB..."
	sleep 2
done

# Download and configure WP
if [ ! -f "$WP_PATH/wp-load.php" ]; then
	wp core download --path="$WP_PATH" --allow-root
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	wp config create --path="$WP_PATH" --allow-root \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$DB_PASSWORD" \
		--dbhost=mariadb:3307
fi

# Redis settings (adding entries to wp-config.php)
wp config set WP_REDIS_HOST redis --path="$WP_PATH" --allow-root
wp config set WP_REDIS_PORT 6379 --raw --path="$WP_PATH" --allow-root
wp config set WP_REDIS_PASSWORD "$REDIS_PASSWORD" --path="$WP_PATH" --allow-root
#echo "define('WP_REDIS_HOST', 'redis')" >> "$WP_PATH/wp-config.php"
#echo "define('WP_REDIS_PORT', 6379)" >> "$WP_PATH/wp-config.php"


# Install the site and create the users
if ! wp core is-installed --path="$WP_PATH" --allow-root; then
	wp core install --path="$WP_PATH" --allow-root \
		--url="$SITE_URL" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email
	
	wp user create "$WP_USER" "$WP_USER_EMAIL" --path="$WP_PATH" --allow-root \
		--role=author \
		--user_pass="$WP_USER_PASSWORD"

fi

# Install redis-cache plugin if not installed
if ! wp plugin is-installed redis-cache --path="$WP_PATH" --allow-root; then
	wp plugin install redis-cache --activate --path="$WP_PATH" --allow-root
fi
wp redis enable --path="$WP_PATH" --allow-root || echo "WARNING: redis couldn't be activated"

# To update de domain in case there is a change after DB creation
wp option update home "$SITE_URL" --path="$WP_PATH" --allow-root
wp option update siteurl "$SITE_URL" --path="$WP_PATH" --allow-root

# Changing the files owner to the temporary user
chown -R "$WP_TEMP_USER:$WP_TEMP_USER" "$WP_PATH"

exec "$@"

