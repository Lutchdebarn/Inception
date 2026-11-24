# User documentation

This guide is for the person who uses or administers the running stack.
It explains what the stack provides, how to start and stop it, how to reach each service, where the credentials are, how backups work, and how to check that everything works.

## 1. What the stack provides

The project runs eight services. Each one runs in its own Docker container.

| Service | Role | Reachable from outside? |
|---|---|---|
| **nginx** | Web server. The only web entry point. HTTPS only (TLS 1.2 / 1.3), port 443. | Yes, port 443 |
| **wordpress** | The WordPress website, run by php-fpm. | No (internal) |
| **mariadb** | The database. Stores posts, users and comments. | No (internal) |
| **redis** | Cache for WordPress. Protected by a password. | No (internal) |
| **adminer** | A web page to browse the database. | Through nginx, at `/adminer` |
| **static** | A small static website (a CV). | Through nginx, at `/site/` |
| **ftp** | FTP server. Gives access to the WordPress files. | Yes, ports 21 and 21000-21010 |
| **backup** | Makes regular copies of the database. | No (internal) |

Your data is kept in three folders on the host machine:

- `/home/ludebarn/data/mariadb`: the database.
- `/home/ludebarn/data/wordpress`: the WordPress files (themes, plugins, uploads).
- `/home/ludebarn/backup`: the database backups.

## 2. Start and stop the project

Run these commands from the root of the repository.

| Action | Command |
|---|---|
| Build and start everything | `make` (or `make up`) |
| Stop and remove the containers (data is kept) | `make down` |
| Stop, and remove the containers and images (data is kept) | `make clean` |
| Remove containers, images, volumes and the data | `make fclean` |
| Wipe everything and start again from scratch | `make re` |

**Warning:** `make fclean` and `make re` delete `/home/ludebarn/data`.
The website content and the database are lost.
The backups in `/home/ludebarn/backup` are **not** deleted.
For a normal restart, use `make down` then `make up`.

The first start takes longer. WordPress is downloaded and installed automatically.

**After a reboot of the machine,** the containers start again by themselves (unless you ran `make down` before).
For a minute, some containers may restart while the others come up. This is normal.

## 3. Access the services

First, make the domain name point to your machine.
Add this line to `/etc/hosts` (needs `sudo`):
```
127.0.0.1 ludebarn.42.fr
```

| What | Address |
|---|---|
| WordPress website | https://ludebarn.42.fr |
| WordPress administration panel | https://ludebarn.42.fr/wp-admin |
| Adminer (database) | https://ludebarn.42.fr/adminer |
| Static website (CV) | https://ludebarn.42.fr/site/ |
| FTP server | `localhost`, port 21 (from the machine that runs the containers) |

The certificate is self-signed.
The browser shows a security warning.
Accept it to continue. This is expected.

There is no HTTP access. Port 80 is closed.

### Adminer

Open https://ludebarn.42.fr/adminer and fill in the form:

| Field | Value |
|---|---|
| System | MySQL |
| Server | `mariadb` |
| Username | `SQL_USER` from `srcs/.env` |
| Password | the content of `secrets/db_password` |
| Database | `SQL_DATABASE` from `srcs/.env` |

Do not use `localhost` as the server. Adminer runs in its own container.
The database account is limited to the WordPress database. You only see that database.

### FTP

**Web browsers no longer support FTP.** Do not type an `ftp://` address or `localhost:21` in a browser.
Use an FTP client, such as FileZilla.

In FileZilla, fill in the quick-connect bar:

| Field | Value |
|---|---|
| Host | `localhost` |
| Username | `FTP_USER` from `srcs/.env` |
| Password | the content of `secrets/ftp_password` |
| Port | `21` |

The server has no encryption. If FileZilla warns about TLS, choose "Use plain FTP" in the site settings.

You land in the WordPress files. You can download and upload files.
A file uploaded to this folder is also served by the website.
For example, uploading `demo.txt` makes it available at `https://ludebarn.42.fr/demo.txt`.

A quick test from the command line (the password is asked, so it is not stored in your history):
```bash
curl -u <FTP_USER> ftp://localhost/                          # list the files
curl -u <FTP_USER> -T /tmp/demo.txt ftp://localhost/demo.txt  # upload a file
```
The address must start with `ftp://`, not `http://`.

FTP does not encrypt anything. The password and the files travel in clear text. Use it only on a trusted network.

## 4. Credentials

Credentials are never stored in the Git repository.
They are in two places on your machine.

**`srcs/.env`** holds the settings that are not secret:
- the domain name,
- the database name and the database user,
- the WordPress site title,
- the usernames and e-mail addresses of the two WordPress users,
- the FTP username,
- the backup schedule.

**`secrets/`** holds the passwords, one file per password:

| File | Used for |
|---|---|
| `db_password` | Password of the WordPress database user |
| `db_root_password` | Password of the database root account |
| `wp_admin_password` | Password of the WordPress administrator |
| `wp_user_password` | Password of the second WordPress user |
| `redis_password` | Password of the Redis cache |
| `ftp_password` | Password of the FTP user |

WordPress has two users:
- the **administrator**, who can manage the whole site;
- a second user with the **author** role.

To log in, use the username from `srcs/.env` and the matching password file.

**Changing a password:** the values are applied when the data is first created.
Editing a file later does not change an existing account.
To apply new values, run `make re`. This deletes all data.

## 5. Backups

The `backup` service copies the WordPress database to a file at a regular time.

- **Where:** `/home/ludebarn/backup`. This folder is outside `/home/ludebarn/data`, so `make fclean` does not delete it.
- **File names:** `<database>_<date>_<time>.sql`, for example `wordpress_2026-11-24_14-30.sql`.
- **When:** the schedule is the `BACKUP_SCHEDULE` value in `srcs/.env`. It uses the cron format. The default `*/10 * * * *` means every 10 minutes. This is a short delay for demonstration. In production, a nightly schedule such as `0 3 * * *` is more usual.
- **Retention:** copies older than 60 minutes are deleted, so the folder does not grow without limit.

**Make a backup now:**
```bash
docker exec backup /usr/local/bin/backup.sh
ls /home/ludebarn/backup
```

**Restore a backup.** The file is a list of SQL commands. Replaying it puts the database back in the state of the copy.
Everything created after the copy is lost.
```bash
docker exec backup sh -c 'MYSQL_PWD="$(cat /run/secrets/db_password)" mariadb -h mariadb -u "$SQL_USER" "$SQL_DATABASE" < /backup/<file>.sql'
docker exec wordpress wp cache flush --allow-root --path=/var/www/html
```
Replace `<file>` with the name of the backup. The second command empties the Redis cache, so the site does not show old data.

## 6. Check that the services are running

**All containers at once:**
```bash
docker ps
```
Expect eight containers: `nginx`, `wordpress`, `mariadb`, `redis`, `ftp`, `static`, `adminer`, `backup`.
`mariadb` and `redis` should show `(healthy)`.

**The website answers over HTTPS:**
```bash
curl -k -I https://ludebarn.42.fr
```
Expect a `200` or a `302` response.

**The static website and Adminer answer:**
```bash
curl -k -I https://ludebarn.42.fr/site/
curl -k -I https://ludebarn.42.fr/adminer
```

**The database answers:**
```bash
docker exec mariadb mariadb-admin ping
```
Expect `mysqld is alive`.

**The cache answers.** Redis needs its password. The command reads it inside the container:
```bash
docker exec redis sh -c 'REDISCLI_AUTH=$(cat /run/secrets/redis_password) redis-cli ping'
```
Expect `PONG`.

**The cache is connected to WordPress:**
```bash
docker exec wordpress wp redis status --allow-root --path=/var/www/html
```
Expect `Status: Connected`.

**The backup schedule is set, and files appear:**
```bash
docker exec backup cat /etc/crontabs/root
ls /home/ludebarn/backup
```
The first command shows one line with the schedule and the script. A new file appears at each scheduled time.

**Something is wrong?** Read the logs of the container:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs redis
docker logs ftp
docker logs static
docker logs adminer
docker logs backup
```

| Symptom | Likely cause |
|---|---|
| `502 Bad Gateway` | WordPress is still installing, or its container is restarting. Wait, then check `docker logs wordpress`. |
| Redirect to `/wp-admin/install.php` | The WordPress installation did not finish. Check `docker logs wordpress`. The container retries at each start. |
| A new comment does not appear | It is waiting for moderation. Approve it in the administration panel. |
| Adminer says `No such file or directory` | The server field is `localhost` or empty. Use `mariadb`. |
| The browser says the address is restricted when opening `localhost:21` | Browsers block port 21 and no longer support FTP. Use an FTP client. |
| FTP upload fails with `553` | The FTP user cannot write to the WordPress files. Check `docker logs ftp`. |
| No file appears in `/home/ludebarn/backup` | `BACKUP_SCHEDULE` is missing in `srcs/.env`, or the database was not ready. Check `docker exec backup cat /etc/crontabs/root`. |
