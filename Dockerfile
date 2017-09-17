FROM gp3t1/alpine:0.7.1

# SHAARLI BUILD SETTINGS
ARG VERSION="stable"

LABEL maintainer="Jeremy PETIT <jeremy.petit@gmail.com>" \
			description="alpine-based shaarli image - rss feed"

## CUSTOM SHARLII UID/GID
ENV APP_USER="shaarli" 		APP_UID=500
ENV APP_GROUP="$APP_USER"	APP_GUID=501
RUN setAppUser

## GLOBAL CONFIG
ENV LOGS_DIR="/data/logs" \
		SUPERVISORD_SOCK="/var/run/supervisord.sock" \
		SUPERVISORD_LOGLVL="info" \
		SUPERVISORD_PIDFILE="/run/supervisord.pid"
## SHAARLI CONFIG
ENV SHAARLI_DIR="/var/www/shaarli" \
		SHAARLI_SOCK="/var/run/php7-fpm-shaarli.sock" \
		SHAARLI_CONTINENT="Europe" \
		SHAARLI_CITY="Paris" \
		SHAARLI_TITLE="My Links" \
		SHAARLI_TITLELINK="?" \
		SHAARLI_REDIRECTOR="" \
		SHAARLI_DISABLESESSIONPROTECT="false" \
		SHAARLI_DEFAULTPRIVATELINK="true" \
		SHAARLI_LOGFILE="${LOGS_DIR}/shaarli.log" \
		SHAARLI_DATADIR="data" \
		SHAARLI_CHECKUPDATE="true" \
		SHAARLI_CACHEDIR="/data/cache" \
		SHAARLI_PAGECACHE="pagecache" \
		SHAARLI_BANAFTER=4 \
		SHAARLI_BANDURATION=1800 \
		SHAARLI_PERMALINKS="true" \
		SHAARLI_SHOWATOM="false" \
		SHAARLI_HIDEPUBLICLINKS="false" \
		SHAARLI_HIDETIMESTAMPS="false" \
		SHAARLI_LINKSPERPAGE="20" \
		SHAARLI_OPENSHAARLI="false" \
		SHAARLI_ENABLETHUMBNAILS="true" \
		SHAARLI_ENABLELOCALCACHE="true" \
		SHAARLI_UPDATECHECKBRANCH="${VERSION}" \
		SHAARLI_UPDATECHECKINTERVAL=86400 \
		SHAARLI_REDIRECTORURLENCODE="true" \
		SHAARLI_ENABLEDPLUGINS="array (  0 => 'qrcode',  1 => 'addlink_toolbar',  2 => 'archiveorg',  3 => 'markdown', );" \
		SHAARLI_PUBSUBHUBURL=""
## NGINX CONFIG
ENV NGINX_WORKERS=4 \
		NGINX_WORKERS_CNX=768 \
		NGINX_PORT=80 \
		NGINX_KEEPALIVE_TO=20 \
		NGINX_CLIENT_MAXBODYSIZE="10m" \
		NGINX_PIDFILE="/run/nginx/nginx.pid"
## PHP CONFIG
ENV PHP_LISTENCLIENTS="127.0.0.1" \
		PHP_LISTENMODE=0660 \
		PHP_RLIMITFILES="" \
		PHP_RLIMITCORE="" \
		PHP_MAXPROC=0 \
		PHP_MAXCHILD=5 \
		PHP_STARTCHILD=2 \
		PHP_MINSPARECHILD=1 \
		PHP_MAXSPARECHILD=3 \
		PHP_IDLETIMEOUT="10s" \
		PHP_MAXREQUEST=0 \
		PHP_SLOWTIMEOUT=0 \
		PHP_REQUESTTIMEOUT=0 \
		PHP_OUTPUTBUFFER=4096 \
		PHP_POSTMAXSIZE="10M" \
		PHP_UPLOADMAXSIZE="10M" \
		PHP_STATUS="" \
		PHP_PING="" \
		PHP_LOGLVL="notice" \
		PHP_LOGFORMAT="%R - %u %{%Y-%m-%dT%H:%M:%S%z}t \"%m %r%Q%q\" %s %f %{mili}d %{kilo}M %C%%"

# PHP_RLIMITFILES=1024
# PHP_RLIMITCORE=0
# PHP_STATUS="/status" \
# PHP_PING="/ping" \

## EXPOSE SHAARLI DEFAULT PORT
EXPOSE 80

## VOLUMES FOR LOGS & CERTIFICATES
VOLUME ["${LOGS_DIR}", "${SHAARLI_CACHEDIR}"]

## INSTALL SHAARLI
RUN apk --no-cache add -t build-dependencies \
			git \
			php7-dom \
			php7-phar \
			php7-simplexml \
			php7-tokenizer \
			py2-pip \
	&& apk --no-cache add \
			curl \
			# openssl \
			nginx \
			php7-curl \
			php7-fpm \
			php7-gd \
			php7-intl \
			php7-json \
			php7-mbstring \
			php7-openssl \
			php7-session \
			php7-zlib \
			python2 \
			supervisor \
	&& pip install --no-cache j2cli \
	&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
	&& git clone -b "${VERSION}" https://github.com/shaarli/Shaarli.git ${SHAARLI_DIR} \
	&& cd ${SHAARLI_DIR} \
	&& composer install --no-dev --prefer-dist \
	&& apk del --no-cache build-dependencies \
	&& rm /usr/bin/composer

# RUN /etc/init.d/php-fpm7 start

COPY templates/* 	/templates/
COPY bin/*				/usr/bin/
RUN  chmod -R 0760 /templates /usr/bin/entrypoint \
	&& chown -R "$APP_USER:$APP_GROUP" "${SHAARLI_DIR}" \
	&& chmod -R 760 "${SHAARLI_DIR}" \
	&& mv /etc/supervisord.conf "/etc/supervisor.$(date +%Y%m%d.%H%M%S)"

ENTRYPOINT ["entrypoint"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
