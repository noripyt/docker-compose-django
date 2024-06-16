# We base ourselves on Debian because the host will be on Debian.
# The Alpine distribution of fail2ban has custom sshd filters
# that are not appropriate for Debian.
FROM debian:bookworm-slim

ARG PROJECT
ARG TZ
ARG HOST_HAS_SSH

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=${TZ}

RUN apt-get update -y --quiet \
    && apt-get install -y --no-install-recommends fail2ban iptables \
    && rm -rf \
    /var/lib/apt/lists/* /var/cache/apt/archives/* /usr/share/doc/* \
    /usr/share/man/* /usr/share/info/* /usr/share/lintian/* /tmp/*

COPY . /etc/fail2ban/
RUN sed -i "s|\${HOST_HAS_SSH}|${HOST_HAS_SSH}|g" /etc/fail2ban/jail.local

CMD [ "fail2ban-server", "-f", "-x", "start" ]
