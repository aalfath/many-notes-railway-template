#!/bin/sh
# Runs as www-data before the upstream entrypoint, and before nginx opens the
# public port. Migrates the database, runs Many Notes' upgrade steps with the
# search index up, and on an empty database creates the admin and closes open
# sign-up. Any failure exits non-zero, so the container stops instead of
# starting with sign-up open to the first visitor.
set -eu
cd /var/www/html

# Broadcasts need Reverb, which isn't running yet; nothing listens anyway.
export BROADCAST_CONNECTION=null

php artisan config:clear -q
php artisan migrate --force -q

# Bundled Typesense on loopback, only for these steps.
/opt/typesense-server --data-dir=/data/typesense --api-key="$TYPESENSE_API_KEY" \
  --api-address=127.0.0.1 --api-port=8108 --peering-address=127.0.0.1 \
  --thread-pool-size=2 >/tmp/typesense-first-boot.log 2>&1 &
ts=$!
stop_ts() { kill "$ts" 2>/dev/null || true; wait "$ts" 2>/dev/null || true; }
trap stop_ts EXIT
i=0
until curl -fsS http://127.0.0.1:8108/health >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 90 ] || ! kill -0 "$ts" 2>/dev/null; then
    echo "railway: Typesense did not start" >&2
    tail -n 20 /tmp/typesense-first-boot.log >&2 || true
    exit 1
  fi
  sleep 1
done

php artisan upgrade:run
php /opt/railway/bootstrap-admin.php
