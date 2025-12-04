FROM node:24.11.1-alpine


RUN adduser --disabled-password --home /srv --no-create-home react
WORKDIR /srv
RUN chown react /srv

USER react

ARG NODE_ENV

ENV NODE_ENV=${NODE_ENV}

COPY --chown=react ${REACT_ROOT}/package.json /srv/
COPY --chown=react ${REACT_ROOT}/package-lock.json /srv/
RUN npm install && npm cache clean --force && rm package-lock.json && rm -rf /srv/.npm/

COPY --chown=react ${REACT_ROOT} /srv

RUN mkdir /srv/.next
RUN if [ "${NODE_ENV}" = "production" ] ; then \
    npm run build && mv /srv/.next /srv/.built-next \
    ; fi && rm -rf /srv/.npm/

CMD cp -r /srv/.built-next/* /srv/.next/ && npm start
