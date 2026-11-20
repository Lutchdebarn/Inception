# Developer documentation

This guide is for a developer who wants to set up, build, run and modify the project.

## 1. Prerequisites

- A virtual machine running Linux (Debian or Ubuntu).
- `git`, `make`, `sudo`.
- Docker Engine and the Docker Compose plugin (`docker compose version` must work).
- Your user must be allowed to run `docker` (member of the `docker` group).
- The domain name must resolve to the machine. Add to `/etc/hosts`:
  ```
  127.0.0.1 ludebarn.42.fr
  ```

## 2. Set up the environment from scratch

**1. Clone the repository.**
```bash
git clone <repository-url> inception
cd inception
```

**2. Create the environment file.**
Copy the example and fill it in:
```bash
cp .example.env srcs/.env
```
`srcs/.env` holds non-secret settings: `DOMAIN_NAME`, `SQL_DATABASE`, `SQL_USER`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`.
- `SQL_DATABASE` is a plain database name (for example `wordpress`), not a path.
- `WP_ADMIN_USER` must not contain `admin` or `administrator` in any case. The entrypoint refuses to start otherwise.
- Passwords do **not** go in `.env`. They are secrets (next step).

**3. Create the secrets.**
Create a `secrets/` folder at the root of the repository, with one file per password. Each file contains only the password:
```
secrets/db_password
secrets/db_root_password
secrets/wp_admin_password
secrets/wp_user_password
```
The file names must match the paths in the `secrets:` section of `srcs/docker-compose.yml`.

`.env` and `secrets/` are listed in `.gitignore`.
Never commit them.

## 3. Build and launch

The Makefile builds the images and starts the containers with Docker Compose.

```bash
make        # same as make up
```
`make up` does two things:
1. `mkdir -p /home/ludebarn/data/mariadb /home/ludebarn/data/wordpress`: creates the folders used by the volumes.
2. `docker compose -f srcs/docker-compose.yml -p inception up -d --build`: builds the images and starts the containers in the background.

## 4. Useful commands

**Makefile targets**

| Target | Effect |
|---|---|
| `make up` / `make` | Build and start |
| `make down` | Stop and remove containers. Data is kept |
| `make clean` | `down` and remove the images. Data is kept |
| `make fclean` | `clean`, remove the volumes, and delete `/home/ludebarn/data` |
| `make re` | `fclean` then `up` |

**Docker commands**

```bash
docker ps                                  # running containers and health status
docker logs <name>                         # logs (mariadb, wordpress, nginx, redis)
docker exec -it <name> sh                  # shell inside a container
docker compose -f srcs/docker-compose.yml -p inception ps
docker volume ls                           # volumes (prefixed with "inception_")
docker volume inspect inception_db_data    # shows the host path of a volume
docker network ls                          # the "inception" network
```
Always use the same project name (`-p inception`) as the Makefile.
A different name creates separate containers, networks and volumes, and causes name conflicts.

**WP-CLI** is installed in the `wordpress` container:
```bash
docker exec wordpress wp user list --allow-root --path=/var/www/html
docker exec wordpress wp redis status --allow-root --path=/var/www/html
```

## 5. Project layout

```
.
├── Makefile
├── README.md, USER_DOC.md, DEV_DOC.md
├── .example.env
├── secrets/                  (ignored by git)
└── srcs/
    ├── docker-compose.yml
    ├── .env                  (ignored by git)
    └── requirements/
        ├── nginx/      Dockerfile, conf/nginx.conf
        ├── wordpress/  Dockerfile, conf/www.conf, tools/entrypoint.sh
        ├── mariadb/    Dockerfile, conf/50-server.cnf, tools/entrypoint.sh
        └── redis/      Dockerfile
```
All images are built from `alpine:3.23`. No ready-made image is pulled.

## 6. How the services work together

- All containers are on one Docker network named `inception`.
- They reach each other by service name (`mariadb`, `wordpress`, `redis`).
- Only nginx publishes a port (`443`). The others use `expose`.
- nginx passes `.php` requests to php-fpm in the `wordpress` container, on port 9000.
- WordPress talks to MariaDB on port 3306 and to Redis on port 6379.
- Start order is controlled by `depends_on` with healthchecks. `wordpress` waits for `mariadb` and `redis` to be healthy.
- Every container restarts automatically (`restart: unless-stopped`).
- Each container runs its service in the foreground as PID 1. The entrypoint scripts end with `exec`.

## 7. Secrets

Secrets are declared in the `secrets:` section of `srcs/docker-compose.yml`.
Docker mounts each one as a file in the container, under `/run/secrets/<name>`.
The entrypoint scripts read them with `cat`:

| Secret | Given to |
|---|---|
| `db_password` | `mariadb`, `wordpress` |
| `db_root_password` | `mariadb` |
| `wp_admin_password` | `wordpress` |
| `wp_user_password` | `wordpress` |

## 8. Where the data is stored and how it persists

Two Docker **named volumes** store the persistent data.
They are configured with `driver_opts` so that the data is written to the host:

| Volume | Container path | Host path |
|---|---|---|
| `db_data` | `/var/lib/mysql` | `/home/ludebarn/data/mariadb` |
| `wordpress` | `/var/www/html` | `/home/ludebarn/data/wordpress` |

The `wordpress` volume is mounted in both the `wordpress` and `nginx` containers.
nginx serves the static files, and php-fpm runs the PHP code.

Redis has no volume. It is a cache in memory, and WordPress refills it from the database.

**Persistence**
- `make down` then `make up`: the data is kept.
- `make fclean` and `make re`: the host folders are deleted, so all data is lost.

**First-start initialization**
- MariaDB initializes the database only if `/var/lib/mysql/mysql` does not exist.
- WordPress installs itself only if `/var/www/html/wp-config.php` does not exist.

If the two volumes get out of step (for example, only the WordPress folder is emptied), the installation can fail.
Empty both folders, or use `make re`.
