FROM nginx:1.26.2-alpine-slim

ARG PROJECT
ARG DJANGO_ROOT
ARG NGINX_ROOT
ARG DOMAIN
ARG TZ
ARG CLIENT_MAX_BODY_SIZE

ENV DOMAIN=${DOMAIN} \
    TZ=${TZ} \
    CLIENT_MAX_BODY_SIZE=${CLIENT_MAX_BODY_SIZE}

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

RUN DOMAIN=${DOMAIN} envsubst < /srv/nginx/robots.txt.template > /srv/nginx/robots.txt && rm /srv/nginx/robots.txt.template
