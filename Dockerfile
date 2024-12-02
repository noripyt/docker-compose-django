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

FROM ${DJANGO_NODE_BUILD}

ARG DJANGO_ROOT
ARG DJANGO_EXTRA_PIP_ARGS
ARG DJANGO_POST_INSTALL_RUN
ARG DJANGO_ENVIRONMENT
ARG DJANGO_CPUS
ARG DOMAIN

ENV PATH="$PATH:/srv/.local/bin" \
    DJANGO_ENVIRONMENT=${DJANGO_ENVIRONMENT} \
    DJANGO_CPUS=${DJANGO_CPUS} \
    DOMAIN=${DOMAIN}

COPY --chown=django ${DJANGO_ROOT}/requirements/* requirements/
RUN python3 -m pip install --no-cache-dir -r requirements/base.txt ${DJANGO_EXTRA_PIP_ARGS}
RUN if [ "$DJANGO_ENVIRONMENT" = "dev" ] ; then python3 -m pip install --no-cache-dir -r requirements/dev.txt ; \
    else python3 -m pip install --no-cache-dir -r requirements/prod.txt ; fi

COPY --chown=django ${DJANGO_ROOT} /srv
RUN --mount=type=secret,id=.env.secrets,uid=1000 sh -c "${DJANGO_POST_INSTALL_RUN}"
RUN mkdir /srv/media /srv/static
# Creates the directory in case it does not exist, to make custom nginx configuration optional.
RUN mkdir -p /srv/nginx_templates

# Makes gunicorn display stdout & stderr as soon as they are printed.
ENV PYTHONUNBUFFERED=true

CMD gunicorn $PROJECT.wsgi:application -b django:8000 --workers $DJANGO_CPUS --threads 8 -t 86400
