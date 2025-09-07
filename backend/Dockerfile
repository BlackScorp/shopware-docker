ARG ALPINE_VERSION=${ALPINE_VERSION:-latest}
ARG NODE_VERSION=${NODE_VERSION:-23}
FROM node:${NODE_VERSION}-alpine AS node-binaries
FROM alpine:$ALPINE_VERSION
ARG ENV=${ENV:-production}
ARG PHP_VERSION=${PHP_VERSION:-84}
ARG SW_VERSION=${SW_VERSION:-6.7.2.0}

ENV USER=docker
ENV GROUPNAME=$USER
ENV UID=1000
ENV GID=1000
ENV HOME=/var/www
ENV NPM_CONFIG_PREFIX=$HOME/.npm
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH:

RUN apk -U upgrade \
    && apk add --no-cache \
     openrc-dev \
    linux-headers \
     gcc \
     freetype-dev \
     libjpeg-turbo-dev \
     libpng-dev \
     libzip-dev \
     openssl-dev \
     nginx \
     su-exec \
     bash \
     curl \
     xdg-utils \
     npm \
     php${PHP_VERSION}-fpm \
     php${PHP_VERSION}-curl \
     php${PHP_VERSION}-bcmath \
     php${PHP_VERSION}-ctype \
     php${PHP_VERSION}-ffi \
     php${PHP_VERSION}-fileinfo \
     php${PHP_VERSION}-gd \
     php${PHP_VERSION}-gmp \
     php${PHP_VERSION}-gettext \
     php${PHP_VERSION}-intl \
     php${PHP_VERSION}-mbstring \
     php${PHP_VERSION}-mysqli \
     php${PHP_VERSION}-openssl \
     php${PHP_VERSION}-pdo \
     php${PHP_VERSION}-pdo_mysql \
     php${PHP_VERSION}-pdo_sqlite \
     php${PHP_VERSION}-phar \
     php${PHP_VERSION}-iconv \
     php${PHP_VERSION}-simplexml \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-xmlreader \
     php${PHP_VERSION}-xmlwriter \
     php${PHP_VERSION}-zip \
     php${PHP_VERSION}-calendar \
     php${PHP_VERSION}-common \
     php${PHP_VERSION}-session \
     php${PHP_VERSION}-sodium \
     php${PHP_VERSION}-tokenizer \
     php${PHP_VERSION}-dev \
      php${PHP_VERSION}-pecl-xdebug

COPY --from=node-binaries /usr/local/bin/node /usr/local/bin/

RUN addgroup \
     --gid "$GID" \
     "$GROUPNAME" \
     && adduser \
     --disabled-password \
     --gecos "" \
     --ingroup "$GROUPNAME" \
     --no-create-home \
     --uid "$UID" \
     $USER \
     && addgroup $USER www-data \
     && addgroup $USER nginx \
     && addgroup $USER root

RUN wget https://getcomposer.org/download/latest-stable/composer.phar \
     && chmod a+x composer.phar \
     && mv composer.phar /usr/local/bin/composer \
     && mkdir -p /usr/local/etc/php \
     && ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
     && ln -s /etc/php${PHP_VERSION}/conf.d /usr/local/etc/php \
     && rm -rf /usr/bin/php \
     && ln -s /usr/bin/php${PHP_VERSION} /usr/bin/php \
     && chown -R $USER:$GROUPNAME $HOME

ADD entrypoint.sh /entrypoint.sh

RUN chmod a+x /entrypoint.sh \
     && chmod a=rwx -R /var/log \
     && chmod a=rwx -R /var/lib \
     && chmod a=rwx -R /run

USER $USER

WORKDIR $HOME/html
RUN composer create-project shopware/production:$SW_VERSION . --no-scripts
CMD /entrypoint.sh