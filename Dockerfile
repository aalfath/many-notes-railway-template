# Many Notes 0.18.1 (Docker Hub tag 0.18, pinned by digest), wrapped for Railway.
FROM brufdev/many-notes:0.18@sha256:4a61723eca842b644ced386b17e189d143e97096c65ac80eadca13c6cd89a739

USER root

# Railway settings: one volume at /data holds the SQLite database, the vault
# files and the search index. Logs go to stdout/stderr.
ENV DB_CONNECTION=sqlite \
    DB_DATABASE=/data/database/database.sqlite \
    LOG_CHANNEL=stderr \
    LOG_LEVEL=warning \
    TRUSTED_PROXY=railway \
    SHOW_WELCOME_MESSAGE=false \
    PHP_FPM_PM_CONTROL=ondemand \
    PHP_FPM_PM_MAX_CHILDREN=4 \
    PHP_FPM_PM_START_SERVERS=1 \
    PHP_FPM_PM_MIN_SPARE_SERVERS=1 \
    PHP_FPM_PM_MAX_SPARE_SERVERS=2 \
    PHP_OPCACHE_MEMORY_CONSUMPTION=96 \
    REVERB_HOST=127.0.0.1

COPY rootfs/ /

RUN set -eux; \
    cd /var/www/html; \
    rm -r storage/app/private storage/app/public; \
    ln -s /data/private storage/app/private; \
    ln -s /data/public storage/app/public; \
    sed -i 's/^worker_processes .*/worker_processes  ${NGINX_WORKER_PROCESSES};/' /etc/nginx/nginx.conf.template; \
    grep -q 'NGINX_WORKER_PROCESSES' /etc/nginx/nginx.conf.template; \
    chmod 755 /usr/local/bin/railway-start /opt/railway/first-boot.sh /opt/railway/typesense.sh \
      /etc/s6-overlay/s6-rc.d/typesense/run /etc/s6-overlay/s6-rc.d/reverb/run \
      /etc/s6-overlay/s6-rc.d/php-fpm/finish /etc/s6-overlay/s6-rc.d/nginx/finish; \
    chown www-data:www-data /etc/nginx; \
    chown -R www-data:www-data /etc/nginx/trusted-proxy

# Starts as root only to prepare the volume, then drops to www-data.
ENTRYPOINT ["/usr/local/bin/railway-start"]
CMD ["/init"]
