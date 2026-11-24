[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/many-notes?utm_medium=integration&utm_source=button&utm_campaign=many-notes)

# Many Notes on Railway

One-click [Railway](https://railway.com) template for [Many Notes](https://github.com/brufdev/many-notes), an open-source (MIT) Markdown note-taking web app with vaults, a file tree, tags, links, templates, full-text search and real-time collaboration.

## What it deploys

| Service | What it does |
|---|---|
| **Many Notes** | Built from this repo's `Dockerfile`: the official image `brufdev/many-notes:0.18` (Many Notes **0.18.1**) pinned by digest `sha256:4a61723eca842b644ced386b17e189d143e97096c65ac80eadca13c6cd89a739`, with a small Railway wrapper. nginx + PHP-FPM serve the app on `$PORT`. Inside the same container: Typesense (search, loopback only), Reverb (live updates over `/ws`) and the queue worker. Volume at `/data`. Health check: `GET /up`. |

Everything the app keeps sits on the `/data` volume:

- `/data/database/database.sqlite`: users, vaults, notes, settings
- `/data/private/`: your vaults as plain `.md` files
- `/data/public/`: public uploads
- `/data/typesense/`: the search index

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *(you enter it)* | Email of the admin account created on the first boot. |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | The admin's first password. Read it in the service's Variables tab. Only used on the first boot. |
| `APP_KEY` | `${{secret(32)}}` | Laravel encryption key. Don't change it after the first deploy. |
| `REVERB_APP_SECRET` | `${{secret(32)}}` | Signs live-update (WebSocket) channel auth. |
| `PORT` | `8080` | Port nginx listens on. |

Optional upstream settings (`APP_TIMEZONE`, SMTP `MAIL_*`, OpenID Connect/OAuth `OIDC_*`, upload limits) can be added as variables. See the [upstream README](https://github.com/brufdev/many-notes#customization). `APP_URL` is taken from the Railway domain unless you set it, for example `https://notes.example.com` for a custom domain.

## What the wrapper changes

- **Admin first, then the public port.** Before nginx starts, the start script runs the migrations and Many Notes' upgrade steps, then creates the admin from `ADMIN_EMAIL`/`ADMIN_PASSWORD` (Many Notes makes the first user super admin) and switches open sign-up off. If that fails, the container exits non-zero, so it never comes up with sign-up open to the first visitor. You can turn registration on again in the admin settings.
- **No baked secrets.** The upstream image ships a fixed `APP_KEY`, Reverb secret and Typesense key `xyz`. The template generates `APP_KEY` and `REVERB_APP_SECRET`. Typesense and Reverb listen on loopback only, and Typesense gets a new random key on every start.
- **Small plans.** Workers are sized from the container's CPU limit (Railway shows the host's CPUs). Typesense runs with transparent huge pages off and 2 jemalloc arenas: without that it held ~360 MB on a 0.5 GB service and was OOM-killed. With it, the service peaked at ~245 MB after creating 150 notes, searching and exporting.
- **Crash recovery.** s6-overlay supervises every process, and `S6_BEHAVIOUR_IF_STAGE2_FAILS=2` makes a failed start exit non-zero. If an nginx or PHP-FPM master is killed, a finish script clears its orphaned workers so the restart can bind the port again.
- **Behind Railway's proxy.** nginx trusts `X-Forwarded-For` from Railway's ranges (100.64.0.0/10, 152.233.0.0/16), and cookies are `Secure` on the HTTPS domain.
- The app runs as `www-data`. The start script runs as root only to create and chown the `/data` folders.

## Updates

Deployers get Railway's "update available" notice when `main` changes. Each version is listed in [`CHANGELOG.md`](CHANGELOG.md), breaking changes first. Many Notes runs its own migrations on start. Back up the volume before you apply an update.

## Local test

```sh
docker build -t many-notes-railway .
docker run -p 8080:8080 -v mn:/data -e PORT=8080 -e APP_URL=http://localhost:8080 \
  -e APP_KEY=$(openssl rand -hex 16) -e REVERB_APP_SECRET=$(openssl rand -hex 16) \
  -e ADMIN_EMAIL=you@example.com -e ADMIN_PASSWORD=change-me-please-123 many-notes-railway
```

Licence: this wrapper is MIT. Many Notes is MIT, © brufdev.
