# Inception Developer Guide

This document describes how to prepare, build, run, inspect, and reset the Inception development environment.

## 1. Project layout

The repository is organized as follows:

```text
.
├── Makefile
├── secrets/
├── srcs/
│   ├── .env
│   ├── .env_example
│   ├── docker-compose.yml
│   └── requirements/
│       ├── adminer/
│       ├── mariadb/
│       ├── nginx/
│       ├── portainer/
│       ├── redis/
│       ├── vsftpd/
│       └── wordpress/
└── DEV.md
```

Each directory under `srcs/requirements/` contains the Dockerfile and configuration needed to build one service image. The Compose file defines the services, networks, secrets, volumes, health checks, and startup dependencies.

## 2. Prerequisites

Install the following on the Linux host:

- Docker Engine
- Docker Compose plugin (`docker compose`)
- GNU Make
- `sudo` access
- Git, if the repository is being cloned
- Internet access for Alpine packages and application downloads during image builds

Check the installation before continuing:

```sh
docker --version
docker compose version
make --version
```

The Makefile assumes that the project uses the host paths `/home/joflorid/data/` and the domain `joflorid.42.fr`. Update the Makefile and Compose volume paths if the project is moved to another host or user account.

## 3. Set up the environment from scratch

Run all commands from the repository root.

### 3.1 Create the environment file

Create a local environment file from the template:

```sh
cp srcs/.env_example srcs/.env
```

Set the values required by the Compose file. The current template contains:

```text
DOMAIN_NAME=
DOMAIN_PORT=
MYSQL_USER=
MYSQL_DATABASE=
WP_TITLE=
WP_ADMIN_USER=
WP_ADMIN_EMAIL=
WP_USER=
WP_USER_EMAIL=
WP_TEMP_USER=
WP_UID=
FTP_USER=
```

`DOMAIN_NAME` should normally be `joflorid.42.fr`. `DOMAIN_PORT` controls the host port published by Nginx; if it is empty, the Compose default is `443`.

Do not put passwords in `srcs/.env`. Non-sensitive settings and secrets are deliberately kept separate.

### 3.2 Prepare Docker secrets

The Compose file expects these files relative to the repository root:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
secrets/redis_password.txt
secrets/ftp_user_password.txt
```

Create or edit each file so that it contains only its corresponding password. Restrict access to the files on a development machine:

```sh
chmod 600 secrets/*.txt
```

The containers receive these files at runtime under `/run/secrets/`. Do not commit real credentials or print them in logs. The Portainer administrator account is created separately during the first Portainer login and is persisted in the Portainer data directory.

### 3.3 Prepare host name resolution

The `make` target adds these entries to `/etc/hosts` for the default domain:

```text
127.0.0.1 joflorid.42.fr portainer.joflorid.42.fr
```

If a different domain is used, add the matching domain and Portainer subdomain manually, or update the `hosts` target in the Makefile.

### 3.4 Create persistent directories

The Makefile creates the required directories automatically, but they can also be created manually:

```sh
sudo mkdir -p \
  /home/joflorid/data/mariadb \
  /home/joflorid/data/wordpress \
  /home/joflorid/data/portainer
```

## 4. Build and launch

### Using the Makefile

The complete development startup command is:

```sh
make
```

The `all` target runs `hosts` and `dirs`, then executes:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

This builds every image from its local Dockerfile and starts the stack in detached mode.

Useful Makefile targets are:

| Target | Action |
| --- | --- |
| `make` or `make all` | Prepare host names and directories, build images, and start the stack |
| `make dirs` | Create the host data directories |
| `make hosts` | Add the default domains to `/etc/hosts` |
| `make status` | Show all Compose containers, including stopped containers |
| `make logs` | Prompt for a service name and display its logs |
| `make down` | Stop and remove the Compose containers and network |
| `make clean` | Remove the project data directories |
| `make fclean` | Remove dangling Docker volumes and the project data directories |

### Using Docker Compose directly

Build and start all services:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

Build without starting containers:

```sh
docker compose -f srcs/docker-compose.yml build
```

Start the existing containers:

```sh
docker compose -f srcs/docker-compose.yml start
```

Stop containers without removing them:

```sh
docker compose -f srcs/docker-compose.yml stop
```

Rebuild and recreate one service after changing its Dockerfile or configuration:

```sh
docker compose -f srcs/docker-compose.yml up -d --build --force-recreate nginx
```

The first WordPress startup may take longer than the other services because the entrypoint waits for MariaDB and Redis, downloads WordPress, creates `wp-config.php`, installs WordPress, and enables the Redis plugin.

## 5. Container management commands

Show the current state and health information:

```sh
docker compose -f srcs/docker-compose.yml ps
docker ps -a
```

Inspect a service configuration:

```sh
docker inspect nginx
docker inspect wordpress
```

Read logs for all services or one service:

```sh
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs -f wordpress
```

Open a shell in a running container:

```sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
```

Run a service command without opening a shell:

```sh
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp core is-installed --path=/var/www/html --allow-root
```

Restart one service:

```sh
docker compose -f srcs/docker-compose.yml restart nginx
```

Remove the stack after stopping it:

```sh
docker compose -f srcs/docker-compose.yml down
```

`down` removes containers and the Compose network but does not remove the host data directories. Use `down --remove-orphans` if containers from an older Compose configuration must also be removed.

## 6. Volume and data management

### Persistent data paths

The Compose file declares these named volumes:

| Compose volume | Container path | Host path | Purpose |
| --- | --- | --- | --- |
| `mariadb_data` | `/var/lib/mysql` | `/home/joflorid/data/mariadb/` | MariaDB database files |
| `wordpress_data` | `/var/www/html` | `/home/joflorid/data/wordpress/` | WordPress core, uploads, plugins, and configuration |
| `portainer_data` | `/data` | `/home/joflorid/data/portainer/` | Portainer users and configuration |
| `docker_sock` | `/var/run` | `/var/run/` | Docker access used by Portainer |

Although these are declared as Docker volumes, the Compose file configures the local driver with bind options. The application data therefore persists directly on the host. Recreating containers does not remove the database, WordPress files, or Portainer configuration.

Nginx mounts `wordpress_data` read-only. WordPress and vsftpd share the WordPress volume, while MariaDB and Portainer use their own data volumes.

Inspect volumes and their mount details:

```sh
docker volume ls
docker volume inspect mariadb_data
docker volume inspect wordpress_data
docker volume inspect portainer_data
```

The exact Docker volume name may include the Compose project name. To find it safely, use:

```sh
docker volume ls --filter name=mariadb_data
docker volume ls --filter name=wordpress_data
docker volume ls --filter name=portainer_data
```

### Back up data

Stop the stack before making a consistent file-level backup:

```sh
make down
sudo tar -czf inception-data-backup.tgz \
  /home/joflorid/data/mariadb \
  /home/joflorid/data/wordpress \
  /home/joflorid/data/portainer
```

Restore the directories with the appropriate ownership and permissions before starting the stack again. Database backups should also be considered at the MariaDB logical level for production-like recovery procedures.

### Remove data

To remove only the project data directories:

```sh
make clean
```

To remove the project data and dangling Docker volumes:

```sh
make fclean
```

These operations are destructive. Confirm that backups exist before running them. Do not use a broad `docker volume prune` or remove volumes belonging to other projects unless that is intentional.

## 7. Development workflow

1. Update the relevant Dockerfile, shell entrypoint, service configuration, or web asset under `srcs/requirements/`.
2. Validate the Compose file before rebuilding:

   ```sh
   docker compose -f srcs/docker-compose.yml config
   ```

3. Rebuild and recreate the affected service:

   ```sh
   docker compose -f srcs/docker-compose.yml up -d --build --force-recreate <service>
   ```

4. Check its logs and health state:

   ```sh
   docker compose -f srcs/docker-compose.yml ps
   docker compose -f srcs/docker-compose.yml logs <service>
   ```

5. Use `make clean` or `make fclean` only when testing first-run initialization or intentionally resetting persistent state.

The services communicate on the `inception` bridge network using Compose service names such as `mariadb`, `wordpress`, `redis`, `adminer`, and `portainer`. Internal ports should therefore not be published to the host unless a specific development need requires it.
