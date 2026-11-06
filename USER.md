# Inception User Guide

This guide explains how to use and administer the Inception Docker stack.

## 1. Services provided

The stack contains the following services:

- **Nginx:** the HTTPS entry point. It serves the website and forwards requests to the internal services.
- **WordPress:** the content management system and public website.
- **MariaDB:** the database used by WordPress.
- **Redis:** the WordPress object cache.
- **Portainer:** the Docker administration panel.
- **Adminer:** a web interface for managing the MariaDB database.
- **vsftpd:** an FTP server that provides access to the WordPress files.

Only Nginx is published directly to the host. The other services communicate through the private `inception` Docker network.

## 2. Prerequisites

Before starting the project, make sure that the following are installed:

- Docker Engine
- Docker Compose plugin
- GNU Make
- `sudo` access

The project also needs an internet connection the first time the images are built because packages and application files are downloaded during the builds.

## 3. Credentials and configuration

### Configuration values

The non-sensitive configuration is stored in:

```text
srcs/.env
```

If it does not exist yet, create it from the example file:

```sh
cp srcs/.env_example srcs/.env
```

Edit `srcs/.env` and set the domain, database name and user, WordPress users and emails, `WP_UID`, `WP_TEMP_USER`, and `FTP_USER`.

### Passwords

Passwords are stored as individual files in the repository's `secrets/` directory:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
secrets/redis_password.txt
secrets/ftp_user_password.txt
```

Each file should contain only the password, followed by an optional final newline. The Compose file mounts these values inside the relevant containers under `/run/secrets/`.

Keep these files private and never publish real passwords to a public repository. To change a password, update the matching secret file and recreate the affected service. Changing a database or WordPress password after the first installation may also require updating the existing database or WordPress configuration.

Portainer creates its own first-login administrator account when it is opened for the first time. This account is created in Portainer and is separate from the WordPress, MariaDB, Redis, and FTP credentials.

## 4. Start the project

Run these commands from the repository root:

```sh
make
```

This command:

1. Creates the persistent data directories under `/home/joflorid/data/`.
2. Adds the default domain names to `/etc/hosts`.
3. Builds the service images.
4. Starts the containers in the background.

The equivalent Docker Compose command is:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

The first startup can take several minutes. MariaDB is initialized first, then WordPress downloads its files, creates its configuration, installs the site, and enables the Redis plugin.

## 5. Stop or restart the project

To stop the containers and remove the Compose network, run:

```sh
make down
```

The persistent data remains on the host, so the site can be started again without losing its database or WordPress files:

```sh
make
```

To stop the stack without removing containers, use:

```sh
docker compose -f srcs/docker-compose.yml stop
```

To start already-created containers again:

```sh
docker compose -f srcs/docker-compose.yml start
```

Do not run `make clean` or `make fclean` unless you intend to delete persistent project data. These commands remove the MariaDB, WordPress, and Portainer data directories.

## 6. Access the website and administration panels

### WordPress website

Open the following address in a browser:

```text
https://joflorid.42.fr
```

If `DOMAIN_NAME` or `DOMAIN_PORT` was changed in `srcs/.env`, use the configured domain and port instead.

The Nginx container creates a self-signed HTTPS certificate. Your browser will show a certificate warning on first access; this is expected for this local project.

The WordPress administration area is available at:

```text
https://joflorid.42.fr/wp-admin
```

Use the WordPress administrator username and password configured in `srcs/.env` and `secrets/wp_admin_password.txt`.

### Portainer Docker administration panel

Open:

```text
https://portainer.joflorid.42.fr
```

Create the Portainer administrator account on the first visit. Portainer uses its own stored data and credentials. The browser may show the same self-signed certificate warning.

### Adminer database panel

Open:

```text
https://joflorid.42.fr/adminer
```

Use these connection values:

- **System:** MariaDB
- **Server:** `mariadb`
- **Username:** the value of `MYSQL_USER` in `srcs/.env`
- **Password:** the contents of `secrets/db_password.txt`
- **Database:** the value of `MYSQL_DATABASE` in `srcs/.env`

The MariaDB root password is stored in `secrets/db_root_password.txt` and should only be used for administrative database tasks.

### FTP

Connect an FTP client to the host on port `21`:

- **Host:** the Docker host
- **Port:** `21`
- **User:** the value of `FTP_USER` in `srcs/.env`
- **Password:** the contents of `secrets/ftp_user_password.txt`

The FTP service exposes the WordPress files mounted from the shared WordPress volume.

## 7. Check that the services are working

### Check container status

From the repository root, run:

```sh
make status
```

or:

```sh
docker compose -f srcs/docker-compose.yml ps
```

The containers should be running. Services with health checks should show `healthy` after their startup checks complete.

### Check individual service logs

To inspect all logs:

```sh
docker compose -f srcs/docker-compose.yml logs
```

To inspect one service:

```sh
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

Follow new log messages with `-f`:

```sh
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

### Check the website response

From the host, test the HTTPS endpoint:

```sh
curl -k -I https://joflorid.42.fr
```

The `-k` option accepts the project's self-signed certificate. A successful response normally includes an HTTP status such as `200`, `301`, or `302`.

### Check WordPress and Redis

```sh
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp core is-installed --path=/var/www/html --allow-root

docker compose -f srcs/docker-compose.yml exec wordpress \
  wp redis status --path=/var/www/html --allow-root
```

Redis can also be checked directly:

```sh
docker compose -f srcs/docker-compose.yml exec redis sh -c \
  'REDISCLI_AUTH="$(cat /run/secrets/redis_password)" redis-cli ping'
```

The expected Redis response is:

```text
PONG
```

### Check MariaDB

```sh
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb-admin ping --silent
```

A working database returns a successful ping message or exits with status `0`.

## 8. Persistent data locations

The project stores persistent data on the host in:

```text
/home/joflorid/data/mariadb/
/home/joflorid/data/wordpress/
/home/joflorid/data/portainer/
```

Do not delete these directories while the project is running. They contain the database, WordPress files, and Portainer configuration.
