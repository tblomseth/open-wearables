# Proof-of-concept deploy on a single host

This branch runs Open Wearables in Docker on one macOS host (the deploy host) and connects the `google_health` provider. Develop on another machine. Deploy each pushed commit to the deploy host.

## Layout

- Deploy host: `mini.local`, deploy clone `~/deploy/open-wearables`. Do not edit files in the deploy clone, except `backend/config/.env`.
- `docker-compose.override.yml` sets `restart: unless-stopped` on every service and binds every published port to `127.0.0.1`. Nothing is reachable from the network.
- `poc/deploy.sh` checks that the local branch is pushed, fast-forwards the deploy clone to the same commit, and runs `docker compose up -d --build`.
- `poc/tunnel.sh` forwards ports 3000, 8000 and 5555 from the deploy host to `localhost` on the development machine.

## First setup on the deploy host

1. Clone the fork over HTTPS into `~/deploy/open-wearables` and check out the branch.
2. Copy `backend/config/.env.example` to `backend/config/.env`. Set `SECRET_KEY`, `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`. Set `SENTRY_ENABLED=False`.
3. In Docker Desktop, turn on "Start Docker Desktop when you sign in". In macOS, turn on automatic login for the user. Docker Desktop starts only after a login, so without automatic login the containers do not start after a reboot.

## Deploy

```bash
git push origin poc/mac-mini
poc/deploy.sh
```

## OAuth redirect

Google accepts `http` redirect URIs only for `localhost`. Keep `API_BASE_URL=http://localhost:8000` and `FRONTEND_URL=http://localhost:3000`, and run `poc/tunnel.sh`. The browser on the development machine then reaches the deploy host through `localhost`.

Register this redirect URI on the Google OAuth client: `http://localhost:8000/api/v1/oauth/google_health/callback`.

Google Health webhooks need a public HTTPS endpoint. This deploy does not have one, so data arrives only through the scheduled pull sync (`SYNC_INTERVAL_SECONDS`).

## Google OAuth client in Testing mode

A Testing-mode app with an external user type gets refresh tokens that expire after 7 days. Then the connection becomes `revoked`, and you must connect again through the frontend.
