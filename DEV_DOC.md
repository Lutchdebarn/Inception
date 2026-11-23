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
```bash
cp .example.env srcs/.env
```
Then fill in `srcs/.env`. It holds only settings that are not secret:

| Variable | Meaning |
|---|---|
| `DOMAIN_NAME` | Domain of the site, for example `ludebarn.42.fr` |
| `SQL_DATABASE` | WordPress database name. A plain name (for example `wordpress`), not a path |
| `SQL_USER` | Database user used by WordPress |
| `WP_TITLE` | Title of the WordPress site |
| `WP_ADMIN_USER` | WordPress administrator. Must not contain `admin` or `administrator`, in any case |
| `WP_ADMIN_EMAIL` | E-mail of the administrator. Must be a valid address |
| `WP_USER` | Second WordPress user (role: author) |
| `WP_USER_EMAIL` | E-mail of the second user |
| `FTP_USER` | FTP username |

The WordPress entrypoint refuses to start if `WP_ADMIN_USER` contains `admin`.

**3. Create the secrets.**
Create a `secrets/` folder at the root of the repository, with one file per password.
Each file contains only the password:

```
secrets/db_password
secrets/db_root_password
secrets/wp_admin_password
secrets/wp_user_password
secrets/redis_password
secrets/ftp_password
```
The file names must match the paths in the `secrets:` section of `srcs/docker-compose.yml`.
Use a different password in each file.

`srcs/.env` and `secrets/` are listed in `.gitignore`.
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
docker logs <name>                         # logs of one container
docker exec -it <name> sh                  # shell inside a container
docker compose -f srcs/docker-compose.yml -p inception ps
docker volume ls                           # volumes (prefixed with "inception_")
docker volume inspect inception_db_data    # shows the host path of a volume
docker network ls                          # the "inception" network
```
Always use the same project name (`-p inception`) as the Makefile.
A different name creates separate containers, networks and volumes, and causes name conflicts.

**Rebuild only one service.** For example, after changing the static website:
```bash
docker compose -f srcs/docker-compose.yml -p inception up -d --build static
docker restart nginx
```
Restart nginx afterwards. It resolves the container names only when it starts. A recreated container can get a new address.

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
        ├── redis/      Dockerfile, tools/entrypoint.sh
        ├── ftp/        Dockerfile, conf/vsftpd.conf, tools/entrypoint.sh
        ├── adminer/    Dockerfile, conf/www.conf
        └── static/     Dockerfile, conf/nginx.conf, site/ (HTML and CSS)
```
All images are built from `alpine:3.23`. No ready-made image is pulled.
The images are tagged `<service>:inception`.

## 6. How the services work together

**Network and ports**
- All containers are on one Docker network named `inception`.
- They reach each other by service name (`mariadb`, `wordpress`, `redis`, `static`, `adminer`).
- Only two things are published on the host: nginx on port `443`, and the FTP server on ports `21` and `21000-21010`.
- The other services use `expose`. They are reachable only inside the Docker network.

**Routes in nginx** (`srcs/requirements/nginx/conf/nginx.conf`)

| URL | Goes to |
|---|---|
| `/` and `*.php` | `wordpress:9000` (php-fpm, FastCGI) |
| `/site/` | `static:80` (reverse proxy to the static website) |
| `/adminer` | `adminer:9000` (php-fpm, FastCGI, fixed script `/var/www/adminer/adminer.php`) |

**Connections between services**
- WordPress talks to MariaDB on port 3306 and to Redis on port 6379.
- Redis requires a password (`--requirepass`, from the `redis_password` secret).
- Adminer connects to `mariadb` with the credentials typed by the user. It holds no secret.

**Start order** is set with `depends_on` and healthchecks:
- `wordpress` waits for `mariadb` and `redis` to be healthy.
- `nginx` waits for `wordpress`, `static` and `adminer` to start.
- If nginx cannot resolve one of these names, it exits with `host not found in upstream`.

**Other rules**
- Every container restarts automatically (`restart: unless-stopped`).
- Each container runs its service in the foreground as PID 1. The entrypoint scripts end with `exec`.

## 7. Secrets

Secrets are declared in the `secrets:` section of `srcs/docker-compose.yml`.
Docker mounts each one as a file in the container, under `/run/secrets/<name>`.
The entrypoint scripts read them with `cat`.

| Secret | Given to |
|---|---|
| `db_password` | `mariadb`, `wordpress` |
| `db_root_password` | `mariadb` |
| `wp_admin_password` | `wordpress` |
| `wp_user_password` | `wordpress` |
| `redis_password` | `redis`, `wordpress` |
| `ftp_password` | `ftp` |

Each service receives only the secrets it needs.
The `.env` file is read by `mariadb` and `wordpress` (`env_file`). The `ftp` service receives only `FTP_USER` (`environment`).

## 8. Where the data is stored and how it persists

Two Docker **named volumes** store the persistent data.
They are configured with `driver_opts` so that the data is written to the host:

| Volume | Container path | Host path |
|---|---|---|
| `db_data` | `/var/lib/mysql` | `/home/ludebarn/data/mariadb` |
| `wordpress` | `/var/www/html` | `/home/ludebarn/data/wordpress` |

The `wordpress` volume is mounted in three containers: `wordpress`, `nginx` and `ftp`.
- nginx serves the static files.
- php-fpm runs the PHP code.
- The FTP server gives access to the files.

Redis has no volume. It is a cache in memory, and WordPress refills it from the database.
The static website has no volume. Its files are copied into the image at build time.

**Persistence**
- `make down` then `make up`: the data is kept.
- `make fclean` and `make re`: the host folders are deleted, so all data is lost.

**First-start initialization**
- MariaDB initializes the database only if `/var/lib/mysql/mysql` does not exist.
- WordPress installs itself (download, `wp-config.php`, site, users, Redis plugin) only if `/var/www/html/wp-config.php` does not exist.

If the two volumes get out of step (for example, only the WordPress folder is emptied), the installation can fail.
Empty both folders, or use `make re`.

## 9. Notes on specific services

**FTP (vsftpd).**
- The user is created at startup by the entrypoint, with the password from the secret.
- vsftpd maps every login to the system user `nobody` (`guest_enable`, `guest_username=nobody`).
- php-fpm also runs as `nobody` and owns `/var/www/html`. This gives the FTP server the same rights, so uploads work.
- Passive mode uses ports `21000-21010`. The same range is set in `vsftpd.conf` and in the compose file. Keep them identical.

**Adminer.** The single file `adminer.php` is downloaded at build time (version pinned in the Dockerfile) and run by php-fpm.

**Static website.** Edit the files in `srcs/requirements/static/site/`. They are copied into the image, so rebuild after a change (see section 4).
To see changes without rebuilding, run the container alone with the folder mounted:
```bash
docker run --rm -p 8081:80 -v $(pwd)/srcs/requirements/static/site:/var/www/site:ro static:inception
```
Then open `http://localhost:8081`.

## 10. Troubleshooting

| Problem | What to check |
|---|---|
| `container name is already in use` | Old containers from another Compose project name. Remove them with `docker rm -f <name>`. |
| WordPress redirects to `install.php` | `wp-config.php` exists but the install failed. Read `docker logs wordpress`. Fix the cause, empty `/home/ludebarn/data/wordpress` and run `make up`. |
| `502 Bad Gateway` | php-fpm of WordPress is not running. Read `docker logs wordpress`. |
| nginx restarts in a loop | Read `docker logs nginx`. Usually a syntax error in `nginx.conf`, or a service name it cannot resolve. |
| Adminer shows `File not found` | Directory rights in the adminer image. php-fpm runs as `nobody` and needs read access to `/var/www/adminer`. |
| FTP upload fails with `553` | The FTP user has no write rights. Check the `guest_*` options in `vsftpd.conf`. |
| A secret file is not found at `up` | The file name in `secrets/` does not match the path in `docker-compose.yml`. |
