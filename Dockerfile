ARG DJANGO_BASE_IMAGE
ARG DJANGO_NODE_BUILD
FROM ${DJANGO_BASE_IMAGE} AS django_without_node

ENV DEBIAN_FRONTEND="noninteractive"

ARG DJANGO_PRE_INSTALL_RUN
ARG DJANGO_APT_DEPENDENCIES
ARG DJANGO_NODE_BUILD
RUN apt-get update -y --quiet \
    && sh -c "${DJANGO_PRE_INSTALL_RUN}"  \
    && apt-get install -y --no-install-recommends \
    `if [ "${DJANGO_NODE_BUILD}" = "django_with_node" ] ; then echo "npm" ; fi` \
    ${DJANGO_APT_DEPENDENCIES} \
    && rm -rf \
    /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* \
    /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /tmp/*

RUN adduser --disabled-password --gecos "" --home /srv --no-create-home django
WORKDIR /srv
RUN chown -R django:django /srv
USER django

FROM django_without_node AS django_with_node

ONBUILD COPY --chown=django ${DJANGO_ROOT}/package*.json /srv
ONBUILD RUN npm install

FROM ${DJANGO_NODE_BUILD} AS django

ARG PROJECT
ARG DJANGO_ROOT
ARG DJANGO_EXTRA_PIP_ARGS
ARG DJANGO_COLLECTSTATIC_ARGS
ARG DJANGO_POST_INSTALL_RUN
ARG DJANGO_ENVIRONMENT
ARG DJANGO_CPUS
ARG DOMAIN
ARG TZ
ARG LOCALE

ENV PATH="$PATH:/srv/.local/bin" \
    PROJECT=${PROJECT} \
    DJANGO_ENVIRONMENT=${DJANGO_ENVIRONMENT} \
    DJANGO_CPUS=${DJANGO_CPUS} \
    DOMAIN=${DOMAIN} \
    TZ=${TZ} \
    LOCALE=${LOCALE}

COPY --chown=django ${DJANGO_ROOT}/requirements/* requirements/
RUN python3 -m pip install --no-cache-dir -r requirements/base.txt ${DJANGO_EXTRA_PIP_ARGS}
RUN if [ "$DJANGO_ENVIRONMENT" = "dev" ] ; then python3 -m pip install --no-cache-dir -r requirements/dev.txt ; \
    else python3 -m pip install --no-cache-dir -r requirements/prod.txt ; fi

COPY --chown=django ${DJANGO_ROOT} /srv
RUN python3 manage.py collectstatic --no-input ${DJANGO_COLLECTSTATIC_ARGS} && sh -c "${DJANGO_POST_INSTALL_RUN}"
RUN mkdir /srv/media

# Makes gunicorn display stdout & stderr as soon as they are printed.
ENV PYTHONUNBUFFERED=true

CMD gunicorn $PROJECT.wsgi:application -b django:8000 --workers $DJANGO_CPUS --threads 8 -t 86400


FROM nginx:1.26.2-alpine-slim AS nginx

ARG PROJECT
ARG NGINX_ROOT
ARG DOMAIN

RUN sed -i "s|/var/log/nginx/|/var/log/nginx/${PROJECT}.|g" /etc/nginx/nginx.conf  \
    && grep -q "/var/log/nginx/${PROJECT}." /etc/nginx/nginx.conf \
    # Removes the /dev/stdout|/dev/stderr redirects created by the nginx base image.
    # We want to preserve the logs in a volume, and we want custom prefixes.
    # We also want fail2ban to not read stdout|stderr as they are endless, blocking
    # read from prefixed (access|error).log files.
    && rm /var/log/nginx/*

COPY --chown=nginx ${NGINX_ROOT}/templates /etc/nginx/templates
COPY --chown=nginx ${NGINX_ROOT} /srv/nginx
# FIXME: Replace with passing --exclude=${NGINX_ROOT}/templates/ above.
RUN rm -rf /srv/nginx/templates

RUN DOMAIN=${DOMAIN} envsubst < /srv/nginx/robots.txt.template > /srv/nginx/robots.txt && rm /srv/nginx/robots.txt.template

COPY --from=django --chown=nginx /srv/static /srv/static
