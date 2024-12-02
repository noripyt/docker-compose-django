FROM node:22.11.0-alpine


RUN adduser --disabled-password --home /srv --no-create-home react
WORKDIR /srv
RUN chown react /srv

USER react

ARG NODE_ENV

ENV NODE_ENV=${NODE_ENV}

COPY --chown=react package.json /srv/
COPY --chown=react package-lock.json /srv/
RUN npm install && npm cache clean --force && rm package-lock.json && rm -rf /srv/.npm/

COPY --chown=react . /srv

RUN mkdir /srv/.next
RUN if [ "${NODE_ENV}" = "production" ] ; then npm run build ; fi && rm -rf /srv/.npm/ /srv/.next/cache/

CMD npm start
