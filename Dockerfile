ARG DJANGO_BASE_IMAGE
FROM ${DJANGO_BASE_IMAGE} AS django

ENV DEBIAN_FRONTEND="noninteractive"
ARG DJANGO_APT_DEPENDENCIES
RUN if [ "${DJANGO_APT_DEPENDENCIES}" != "" ] ; then \
    apt-get update -y --quiet \
    && apt-get install -y --no-install-recommends ${DJANGO_APT_DEPENDENCIES} \
    && rm -rf \
    /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* \
    /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /tmp/* \
    ; fi

RUN adduser --disabled-password --gecos "" --home /srv --no-create-home django
WORKDIR /srv
RUN chown -R django:django /srv
USER django

ARG PROJECT
ARG DJANGO_ROOT
ARG DJANGO_SETTINGS_MODULE
ARG DJANGO_CPUS
ARG DOMAIN

ENV PATH="$PATH:/srv/.local/bin" \
    PROJECT=${PROJECT} \
    DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE} \
    DJANGO_CPUS=${DJANGO_CPUS} \
    DOMAIN=${DOMAIN}

COPY --chown=django ${DJANGO_ROOT}/requirements/* requirements/
RUN python3 -m pip install --no-cache-dir -r requirements/base.txt -r requirements/prod.txt
RUN if [ "$DJANGO_SETTINGS_MODULE" = "${PROJECT}.settings.dev" ] ; then python3 -m pip install --no-cache-dir -r requirements/dev.txt ; fi

COPY --chown=django ${DJANGO_ROOT} /srv
RUN python3 manage.py collectstatic --no-input

WORKDIR /srv

ARG DJANGO_POST_INSTALL_RUN
RUN ${DJANGO_POST_INSTALL_RUN}

# Makes gunicorn display stdout & stderr as soon as they are printed.
ENV PYTHONUNBUFFERED=true

CMD gunicorn $PROJECT.wsgi:application -b django:8000 --workers $((2 * $DJANGO_CPUS + 1)) -t 86400


FROM nginx:1.26.1-alpine-slim AS nginx

ARG PROJECT
ARG NGINX_ROOT

RUN sed -i "s|/var/log/nginx/|/var/log/nginx/${PROJECT}.|g" /etc/nginx/nginx.conf  \
    && grep -q "/var/log/nginx/${PROJECT}." /etc/nginx/nginx.conf \
    # Removes the /dev/stdout|/dev/stderr redirects created by the nginx base image.
    # We want to preserve the logs in a volume, and we want custom prefixes.
    # We also want fail2ban to not read stdout|stderr as they are endless, blocking
    # read from prefixed (access|error).log files.
    && rm /var/log/nginx/*

COPY --chown=nginx ${NGINX_ROOT}/templates /etc/nginx/templates
COPY --chown=nginx ${NGINX_ROOT} /srv/nginx
COPY --from=django --chown=nginx /srv/static /srv/static
