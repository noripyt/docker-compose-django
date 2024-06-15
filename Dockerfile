FROM python:3.12.3-slim-bookworm AS django

ENV DEBIAN_FRONTEND="noninteractive" TZ="Europe/Paris"

#RUN apt-get update -y --quiet \
#    && apt-get install -y --no-install-recommends \
#    && rm -rf \
#    /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* \
#    /usr/share/man/* /usr/share/info/* /usr/share/lintian/*

RUN adduser --disabled-password --gecos "" --home /srv --no-create-home django
WORKDIR /srv
RUN chown -R django:django /srv
USER django

ARG PROJECT
ARG DJANGO_SETTINGS_MODULE
ARG DOMAIN

ENV PATH="$PATH:/srv/.local/bin" \
    PROJECT=${PROJECT} \
    DJANGO_SETTINGS_MODULE=${DJANGO_SETTINGS_MODULE} \
    DOMAIN=${DOMAIN}

COPY --chown=django django/requirements/* requirements/
RUN python3 -m pip install --no-cache-dir -r requirements/base.txt -r requirements/prod.txt
RUN if [ "$DJANGO_SETTINGS_MODULE" = "${PROJECT}.settings.dev" ] ; then python3 -m pip install --no-cache-dir -r requirements/dev.txt ; fi


ARG BACKEND_CPUS

ENV BACKEND_CPUS=${BACKEND_CPUS}

COPY --chown=django django /srv
RUN python3 manage.py collectstatic --no-input

WORKDIR /srv

# Makes gunicorn display stdout & stderr as soon as they are printed.
ENV PYTHONUNBUFFERED=true

CMD gunicorn $PROJECT.wsgi:application -b django:8000 --workers $((2 * $BACKEND_CPUS + 1)) -t 86400


FROM nginx:1.26.1-alpine-slim AS nginx

COPY --chown=nginx ./nginx/templates /etc/nginx/templates
COPY --chown=nginx ./nginx/ /srv/nginx
COPY --from=django --chown=nginx /srv/static /srv/static
