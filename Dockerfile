FROM debian:jessie

ENV MUSL_VERSION="1.1.11" \
  NCURSES_VERSION="6.0" \
  LIBEVENT_VERSION="2.0.22" \
  TMUX_VERSION="2.0"

RUN set -x && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates less build-essential && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY build-tmux.sh /
RUN chmod +x /build-tmux.sh

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["build-tmux"]
