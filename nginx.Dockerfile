FROM nginx:1.28.0-alpine-slim

ARG PROJECT
ARG DJANGO_ROOT
ARG NGINX_ROOT

RUN sed -i "s|/var/log/nginx/|/var/log/nginx/${PROJECT}.|g" /etc/nginx/nginx.conf  \
    && grep -q "/var/log/nginx/${PROJECT}." /etc/nginx/nginx.conf \
    # Removes the /dev/stdout|/dev/stderr redirects created by the nginx base image.
    # We want to preserve the logs in a volume, and we want custom prefixes.
    # We also want fail2ban to not read stdout|stderr as they are endless, blocking
    # read from prefixed (access|error).log files.
    && rm /var/log/nginx/*

COPY --chown=nginx ${NGINX_ROOT}/templates /etc/nginx/templates
COPY --chown=nginx ${DJANGO_ROOT}/nginx_templates/* /etc/nginx/templates/
COPY --chown=nginx ${NGINX_ROOT} /srv/nginx
# FIXME: Replace with passing --exclude=${NGINX_ROOT}/templates/ above.
RUN rm -rf /srv/nginx/templates
