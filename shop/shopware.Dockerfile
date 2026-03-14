# syntax=docker/dockerfile:1.4

ARG NODE_VERSION=${NODE_VERSION:-23}
ARG SW_VERSION=${SW_VERSION:-6.7.2.0}
ARG ALPINE_VERSION=${ALPINE_VERSION:-latest}
ARG PHP_VERSION=${PHP_VERSION:-85}

FROM node:${NODE_VERSION}-alpine AS node-binaries
RUN npm cache clean --force


ARG PHP_VERSION
ARG ALPINE_VERSION
ARG SW_VERSION

FROM base:PHP-${PHP_VERSION}-ALPINE-${ALPINE_VERSION}

ENV HOME=/var/www

ADD entrypoint.sw.sh /entrypoint.sw.sh

COPY --from=node-binaries /usr/local/bin /usr/local/bin
COPY --from=node-binaries /usr/local/lib/node_modules /usr/local/lib/noade_modules

WORKDIR $HOME/html

RUN composer create-project shopware/production:$SW_VERSION . \
        --no-scripts \
        --no-dev \
        --no-cache \
        --prefer-source \
    && rm -rf /var/cache/apk/* $HOME/.npm /tmp/* $HOME/.composer \
    && zip -r -9 $HOME/shopware.zip . \
        -x *.git* *node_modules* *var/cache* *docs* *.pdf *.md \
    && rm -rf vendor/* \
    && find . -type d -exec touch {}/.temp.docker + \
    && find . -type f ! -name '.temp.docker' -delete



CMD ["/entrypoint.sw.sh"]

HEALTHCHECK --interval=5s --timeout=3s --retries=10 \
    CMD [ "sh", "-c", "test -f /var/www/html/shop.installed" ]
