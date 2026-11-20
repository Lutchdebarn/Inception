# User documentation

This guide is for the person who uses or administers the running stack.
It explains what the stack does, how to start and stop it, how to reach the website, where the credentials are, and how to check that everything works.

## 1. What the stack provides

The project runs four services, each in its own Docker container.

| Service | Role | Reachable from outside? |
|---|---|---|
| **nginx** | Web server. Only entry point. HTTPS only (TLS 1.2 / 1.3), port 443. | Yes, port 443 |
| **wordpress** | WordPress site, run by php-fpm. | No (internal only) |
| **mariadb** | Database that stores posts, users and comments. | No (internal only) |
| **redis** | Cache for WordPress. Reduces the load on the database. | No (internal only) |

Your data is kept in two places on the host machine:

- `/home/ludebarn/data/mariadb`: the database.
- `/home/ludebarn/data/wordpress`: the WordPress files (themes, plugins, uploads).

## 2. Start and stop the project

Run these commands from the root of the repository.

| Action | Command |
|---|---|
| Build and start everything | `make` (or `make up`) |
| Stop and remove the containers (data is kept) | `make down` |
| Stop, and remove the containers and images (data is kept) | `make clean` |
| Remove **everything**, including the data | `make fclean` |
| Wipe everything and start again from scratch | `make re` |

**Warning:** `make fclean` and `make re` delete `/home/ludebarn/data`.
The website content and the database are lost.
Use `make down` and `make up` for a normal restart.

The first start takes longer. WordPress is downloaded and installed automatically.

## 3. Access the website and the administration panel

1. Make the domain name point to your machine.
   Add this line to `/etc/hosts` (needs `sudo`):
   ```
   127.0.0.1 ludebarn.42.fr
   ```
2. Open the website: **https://ludebarn.42.fr**
3. Open the administration panel: **https://ludebarn.42.fr/wp-admin**

The certificate is self-signed.
The browser shows a security warning.
Accept it to continue. This is expected.

There is no HTTP access. Port 80 is closed.

## 4. Credentials

Credentials are never stored in the Git repository.
They are in two places on your machine:

**`srcs/.env`** holds the non-secret settings:
- the domain name,
- the database name and the database user,
- the WordPress site title,
- the usernames and e-mail addresses of the two WordPress users.

**`secrets/`** holds the passwords, one file per password:

| File | Used for |
|---|---|
| `db_password` | Password of the WordPress database user |
| `db_root_password` | Password of the database root account |
| `wp_admin_password` | Password of the WordPress administrator |
| `wp_user_password` | Password of the second WordPress user |

WordPress has two users:
- the **administrator**, who can manage the whole site;
- a second user with the **author** role.

To log in, use the username from `srcs/.env` and the matching password file.

**Changing a password:** the values are applied when the data is first created.
Editing a file later does not change an existing account.
To apply new values, run `make re`. This deletes all data.

## 5. Check that the services are running

**All containers at once:**
```bash
docker ps
```
Expect four containers: `nginx`, `wordpress`, `mariadb`, `redis`.
`mariadb` and `redis` should show `(healthy)`.

**The website answers over HTTPS:**
```bash
curl -k -I https://ludebarn.42.fr
```
Expect a `200` or a `302` response.

**The database answers:**
```bash
docker exec mariadb mariadb-admin ping
```
Expect `mysqld is alive`.

**The cache answers:**
```bash
docker exec redis redis-cli ping
```
Expect `PONG`.

**The cache is connected to WordPress:**
```bash
docker exec wordpress wp redis status --allow-root --path=/var/www/html
```
Expect `Status: Connected`.

**Something is wrong?** Read the logs of the container:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs redis
```

| Symptom | Likely cause |
|---|---|
| `502 Bad Gateway` | WordPress is still installing, or its container is restarting. Wait, then check `docker logs wordpress`. |
| Redirect to `/wp-admin/install.php` | The WordPress installation failed. Check `docker logs wordpress`, then run `make re`. |
| A new comment does not appear | It is waiting for moderation. Approve it in the administration panel. |
