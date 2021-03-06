FROM kbqallan/alpine:latest

MAINTAINER from kbqallan(443831995@qq.com)

ARG VERSION=${VERSION:-7.2.2}
ARG SHA256=${SHA256:-e563cee406b1ec96649c22ed2b35796cfe4e9aa9afa6eab6be4cf2fe5d724744}
#ARG SWOOLE_VERSION=${SWOOLE_VERSION:-1.7.17}
ARG SWOOLE_VERSION=${SWOOLE_VERSION:-1.9.4}

ENV INSTALL_DIR=/usr/local/php \
	TEMP_DIR=/tmp/php

RUN set -x && \
# Change Mirrors
#	PHP_URL="https://secure.php.net/get/php-${VERSION}.tar.xz/from/this/mirror" && \
	PHP_URL="http://cn2.php.net/get/php-7.2.2.tar.gz/from/this/mirror" && \
	LIBICONV_VERSION=1.14 && \
	LIBICONV_DIR=/tmp/libiconv && \
	MEMCACHE_DEPS="libmemcached-dev cyrus-sasl-dev libsasl linux-headers git" && \
	PHPIZE_DEPS="autoconf file g++ gcc libc-dev make m4 pkgconf re2c xz tar curl" && \
#Mkdir TEMP_DIR
	mkdir -p ${LIBICONV_DIR} ${TEMP_DIR} /tmp/memcached && cd /tmp && \
#Upgrade OS and install
	apk --update --no-cache upgrade && \
	apk add --no-cache --virtual .build-deps $PHPIZE_DEPS curl-dev  wget libedit-dev libxml2-dev openssl-dev sqlite-dev libxpm-dev libaio-dev \
		libjpeg-turbo-dev libpng-dev libmcrypt-dev icu-dev freetype-dev gettext-dev libxslt-dev zlib-dev imap-dev gettext-dev ${MEMCACHE_DEPS} && \
#Add run php user&group
	addgroup -g 400 -S www && \
	adduser -u 400 -S -H -s /sbin/nologin -g 'PHP' -G www www && \
#Download File
	wget  "${PHP_URL}" && mv mirror php-7.2.2.tar.gz && tar zxvf php-${VERSION}.tar.gz -C ${TEMP_DIR} --strip-components=1 && \
	curl -SL http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz | tar -xz -C ${LIBICONV_DIR} --strip-components=1 && \
#Install libiconv
	rm /usr/bin/iconv && \
	curl -Lk https://github.com/mxe/mxe/raw/7e231efd245996b886b501dad780761205ecf376/src/libiconv-1-fixes.patch > libiconv-1-fixes.patch && \
	cd ${LIBICONV_DIR} && \
	patch -p1 < ../libiconv-1-fixes.patch && \
	./configure --prefix=/usr/local && \
	make -j "$(getconf _NPROCESSORS_ONLN)" && \
	make install && \
#Install PHP
	cd ${TEMP_DIR}/ && \
	PHP_EXTRA_CONFIGURE_ARGS="--enable-fpm --with-fpm-user=www --with-fpm-group=www" && \
	./configure --prefix=${INSTALL_DIR} \
		--with-config-file-path=${INSTALL_DIR}/etc \
		--with-config-file-scan-dir=${INSTALL_DIR}/etc/php.d \
		${PHP_EXTRA_CONFIGURE_ARGS} \
		--enable-opcache \
		--disable-fileinfo \
		--with-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-iconv \
		--with-iconv-dir=/usr/local \
		--with-freetype-dir \
		--with-jpeg-dir \
		--with-png-dir \
		--with-zlib \
		--with-zlib-dir \
		--with-libxml-dir=/usr \
		--enable-xml \
		--disable-rpath \
		--enable-bcmath \
		--enable-shmop \
		--enable-exif \
		--enable-sysvsem \
		--enable-inline-optimization \
		--with-curl \
		--enable-mbregex \
		--enable-mbstring \
		--with-mcrypt \
		--with-gd \
		--enable-gd-native-ttf \
		--enable-gd-jis-conv \
		--with-openssl \
		--with-mhash \
		--enable-pcntl \
		--enable-sockets \
		--with-xmlrpc \
		--enable-ftp \
		--enable-intl \
		--with-xsl \
		--with-gettext \
		--enable-zip \
		--enable-soap \
		--disable-ipv6 \
		--disable-debug \
		--with-layout=GNU \
		--with-pic \
		--enable-cli \
		--with-xpm-dir \
		--enable-shared \
		--with-imap \
		--enable-memcache && \
	make -j$(getconf _NPROCESSORS_ONLN) && \
	make install && \
	[ ! -e "${INSTALL_DIR}/etc/php.d" ] && mkdir -p ${INSTALL_DIR}/etc/php.d && \
	/bin/cp php.ini-production ${INSTALL_DIR}/etc/php.ini && \
#Install libmemcached memcache-3.0.8
#	apk add --no-cache php5-memcache libmemcached-dev && \
#	mv /usr/lib/php5/modules/memcache.so ${INSTALL_DIR}/lib/php/20131226/memcache.so && \
#Install memcached-2.2.0
#	${INSTALL_DIR}/bin/pecl install http://pecl.php.net/get/memcached-2.2.0.tgz && \
#Install redis-2.2.8
#	${INSTALL_DIR}/bin/pecl install https://pecl.php.net/get/redis-2.2.8.tgz && \
#Install swoole
#	#${INSTALL_DIR}/bin/pecl install https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz && \
#	curl -Lk "https://pecl.php.net/get/swoole-${SWOOLE_VERSION}.tgz" | tar xz -C /tmp && \
#	cd /tmp/swoole-${SWOOLE_VERSION} && \
#	${INSTALL_DIR}/bin/phpize && \
#	./configure --with-php-config=${INSTALL_DIR}/bin/php-config && \
#	make -j "$(getconf _NPROCESSORS_ONLN)" && \
#	make install && \
#Install xdebug
#	${INSTALL_DIR}/bin/pecl install https://pecl.php.net/get/xdebug-2.5.0.tgz && \
#Uninstalll Build software an clean OS
	#docker-php-source delete && \
	runDeps="$( scanelf --needed --nobanner --recursive /usr/local | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u | xargs -r apk info --installed | sort -u )" && \
	apk add --no-cache --virtual .php-rundeps $runDeps && \
	apk del .build-deps && \
	rm -rf /var/cache/apk/* /tmp/*

ENV PATH=${INSTALL_DIR}/bin:$PATH
ENV PATH=${INSTALL_DIR}/sbin:$PATH \
	TERM=linux

COPY entrypoint.sh /entrypoint.sh
ADD php-fpm.conf ${INSTALL_DIR}/etc/php-fpm.conf

ENTRYPOINT ["/entrypoint.sh"]

CMD ["php-fpm"]
