*This project has been created as part of the 42 curriculum by joflorid.*

# Inception

## Description

Inception is a Docker-based infrastructure project that deploys a small, isolated web stack. Its goal is to build and orchestrate several services from custom Dockerfiles, connect them through a private Docker network, persist their data, and manage sensitive values with Docker secrets.

The main request path is:

```text
Client -> Nginx (HTTPS) -> WordPress/PHP-FPM -> MariaDB
                         -> Redis cache
```

Nginx is the only web entry point exposed by the Compose file. It serves the WordPress site over HTTPS, forwards PHP requests to WordPress, and proxies the `/adminer` path to Adminer. The `portainer.joflorid.42.fr` host name is proxied to Portainer.

### Services and sources

All service images are built locally from the files under `srcs/requirements/`:

| Service | Role | Main source or choice |
| --- | --- | --- |
| Nginx | HTTPS reverse proxy and static file server | Alpine Linux, Nginx, OpenSSL, custom `nginx.conf.template` |
| WordPress | PHP application and CMS | Alpine Linux, PHP 8.5, PHP-FPM, WP-CLI, custom entrypoint |
| MariaDB | Relational database | Alpine Linux, MariaDB, initialization entrypoint |
| Redis | WordPress object cache | Alpine Linux, Redis, password authentication |
| Adminer | Web database administration | Alpine Linux, Adminer PHP application |
| Portainer | Docker management interface | Alpine Linux, Portainer 2.45.3 |
| vsftpd | FTP access to WordPress files | Alpine Linux, vsftpd |

The project also includes a small custom HTML/PHP-facing web area in `srcs/requirements/nginx/html/` and `joflorid_web/`. WordPress files are generated and stored in the shared `wordpress_data` volume. The custom Nginx entrypoint generates a self-signed certificate for the configured domain and renders the Nginx template at container start.

### Main design choices

- **One service per container:** each major responsibility has its own lifecycle, image, configuration, and health check.
- **Alpine-based images:** small base images reduce the amount of software installed in each container.
- **Nginx as the public gateway:** only HTTPS is published by the Compose configuration; internal services communicate by service name on the `inception` bridge network.
- **Automatic initialization:** MariaDB creates the database and user on the first run, while WordPress downloads, configures, and installs the site through WP-CLI.
- **Persistent data:** database, WordPress, and Portainer data survive container recreation.
- **Health-aware startup:** WordPress waits for healthy MariaDB and Redis services, and health checks are defined for the main services.
- **Reduced privileges:** containers use `no-new-privileges` where configured, and the WordPress entrypoint assigns ownership to a configurable non-root user.

### Technical comparisons

#### Virtual Machines vs Docker

Virtual machines emulate complete computers and include a separate guest kernel for every VM. They provide stronger hardware-level isolation but use more memory, storage, and startup time. Docker containers share the host kernel and isolate applications through namespaces and control groups, so they start faster and use fewer resources. Docker is appropriate here because the project is a collection of cooperating Linux services that need reproducible packaging rather than complete operating-system environments.

#### Secrets vs Environment Variables

Environment variables are convenient for non-sensitive configuration such as `DOMAIN_NAME`, `MYSQL_DATABASE`, and WordPress user names, but they can be exposed through container inspection, process environments, logs, or accidental debugging output. Docker secrets are mounted as files under `/run/secrets/` and are used here for database passwords, WordPress passwords, the Redis password, and the FTP password. This keeps credentials out of the Compose environment section and separates configuration from sensitive data. Secrets still require correct file permissions and should never be committed with real values.

#### Docker Network vs Host Network

The project uses a user-defined bridge network named `inception`. Containers can resolve one another by service name, while only explicitly published ports are reachable from the host. This limits exposure and avoids port conflicts between internal services. Host networking would remove most of that network isolation and make containers share the host network namespace; it can be useful for specific performance or discovery requirements, but it is unnecessary and less controlled for this stack.

#### Docker Volumes vs Bind Mounts

Docker-managed volumes are normally created and managed by Docker, while bind mounts directly map a host path into a container. This project declares Compose volumes but configures the local volume driver with bind options, so persistent data is stored in `/home/joflorid/data/` on the host. This makes the required storage locations explicit and convenient to inspect or back up, but it is less portable than a Docker-managed volume because the host paths and permissions are host-specific.

## Instructions

### Requirements

- Linux with Docker Engine and the Docker Compose plugin
- GNU Make
- `sudo` access to create the persistent data directories and update `/etc/hosts`
- A working internet connection for Alpine packages, WordPress, WP-CLI, Adminer, and Portainer downloads during image builds

### Configuration

1. Clone the repository and enter its root directory.
2. Create the Compose environment file:

   ```sh
   cp srcs/.env_example srcs/.env
   ```

3. Fill in the values in `srcs/.env`, including the domain, database settings, WordPress accounts, `WP_UID`, and `FTP_USER`.
4. Put the required passwords in the files under `secrets/`. Do not replace these files with passwords committed to version control.

The default domain used by the Makefile is `joflorid.42.fr`. The Compose file uses `DOMAIN_PORT` when it is set and otherwise publishes HTTPS on port `443`.

### Build and run

From the repository root:

```sh
make
```

The `all` target creates the host data directories, adds the domain and Portainer subdomain to `/etc/hosts`, builds all images, and starts the stack in detached mode.

Equivalent Docker Compose command:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

Because Nginx generates a self-signed certificate, browsers will display a certificate warning on first access. The configured host names must resolve to `127.0.0.1`; the Makefile adds them automatically for the default domain.

### Access

- WordPress: `https://joflorid.42.fr` (or the configured `DOMAIN_NAME` and port)
- Portainer: `https://portainer.joflorid.42.fr`
- Adminer: `https://joflorid.42.fr/adminer`
- FTP: connect to the host on port `21` with the configured `FTP_USER`; passive ports are configured in `srcs/requirements/vsftpd/conf/vsftpd.conf`

### Useful commands

```sh
make status       # Show container status
make logs         # Show logs for a selected service
make down         # Stop and remove the Compose containers and network
make clean        # Remove persistent project data directories
make fclean       # Remove dangling Docker volumes and persistent data
```

To inspect the Redis integration:

```sh
docker compose -f srcs/docker-compose.yml exec wordpress \
  wp redis status --path=/var/www/html --allow-root
docker compose -f srcs/docker-compose.yml exec redis sh -c \
  'REDISCLI_AUTH="$(cat /run/secrets/redis_password)" redis-cli dbsize'
```

The first WordPress startup can take a little longer because it waits for MariaDB, downloads WordPress, installs the site, and installs the Redis cache plugin.

## Resources

### Documentation and references

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker storage volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker bridge networks](https://docs.docker.com/engine/network/drivers/bridge/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [WordPress developer documentation](https://developer.wordpress.org/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [MariaDB documentation](https://mariadb.com/docs/)
- [Redis documentation](https://redis.io/docs/latest/)
- [Adminer](https://www.adminer.org/)
- [Portainer documentation](https://docs.portainer.io/)
- [vsftpd documentation](https://security.appspot.com/vsftpd.html)

### AI usage

AI assistance was used to help structure, explain the requested technology comparisons, and suggest relevant documentation links. The project implementation itself consists of the repository's Dockerfiles, shell scripts, Nginx/PHP/Redis/vsftpd configurations, Compose file, and custom web assets; AI was not used as a substitute for testing or for making undocumented runtime claims.
