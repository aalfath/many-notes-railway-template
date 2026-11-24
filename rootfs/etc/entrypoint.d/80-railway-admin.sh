#!/bin/sh
# First boot on Railway: create the admin from ADMIN_EMAIL / ADMIN_PASSWORD and
# close open sign-up, before nginx opens the public port. Runs after the
# migrations (50) and upstream upgrades (75). A failure stops the container.
# The upstream entrypoint sources this file with `set -e`, so catch exit codes.
rc=0
php /opt/railway/bootstrap-admin.php --check || rc=$?
[ "$rc" -eq 10 ] && exit 0
if [ "$rc" -ne 0 ]; then
  echo "railway: could not read the users table (exit $rc), refusing to start" >&2
  exit 1
fi

# The starter vault is indexed for search while it is created, so run the
# bundled Typesense (loopback only) just for this step.
/opt/typesense-server --data-dir=/data/typesense --api-key="$TYPESENSE_API_KEY" \
  --api-address=127.0.0.1 --api-port=8108 --peering-address=127.0.0.1 \
  --thread-pool-size=2 >/tmp/typesense-bootstrap.log 2>&1 &
ts=$!
i=0
until curl -fsS http://127.0.0.1:8108/health >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -gt 60 ] || ! kill -0 "$ts" 2>/dev/null; then
    echo "railway: Typesense did not start for the admin bootstrap" >&2
    tail -n 20 /tmp/typesense-bootstrap.log >&2
    kill "$ts" 2>/dev/null
    exit 1
  fi
  sleep 1
done

rc=0
php /opt/railway/bootstrap-admin.php || rc=$?
kill "$ts" 2>/dev/null || true
wait "$ts" 2>/dev/null || true
if [ "$rc" -ne 0 ]; then
  echo "railway: admin bootstrap failed, refusing to start with open sign-up" >&2
  exit 1
fi
exit 0
