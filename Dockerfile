FROM alpine:3.10
LABEL maintainer="Kong Core Team <team-core@konghq.com>"

ENV KONG_VERSION 1.2.2
ENV KONG_SHA256 76183d7e8ff084c86767b917da441001d0d779d35fa2464275b74226029a46bf

RUN adduser -Su 1337 kong \
	&& mkdir -p "/usr/local/kong" \
	&& apk add --no-cache --virtual .build-deps wget tar ca-certificates git \
	&& apk add --no-cache libgcc openssl pcre perl tzdata curl libcap su-exec zip luarocks \
	&& wget -O kong.tar.gz "https://bintray.com/kong/kong-alpine-tar/download_file?file_path=kong-$KONG_VERSION.apk.tar.gz" \
	&& echo "$KONG_SHA256 *kong.tar.gz" | sha256sum -c - \
	&& tar -xzf kong.tar.gz -C /tmp \
	&& rm -f kong.tar.gz \
	&& git clone https://github.com/HefeiJoe/kong-plugin-prometheus.git /tmp/kong-plugin-prometheus \
	&& cp -R /tmp/usr / \
	&& rm -rf /tmp/usr \
	&& cp -R /tmp/etc / \
	&& rm -rf /tmp/etc \
	&& apk del .build-deps \
	&& chown -R kong:0 /usr/local/kong \
	&& chmod -R g=u /usr/local/kong

COPY prometheus-server.conf /tmp/prometheus-server.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]
CMD ["luarocks make /tmp/kong-plugin-prometheus/*.rockspec"]
CMD ["export KONG_NGINX_HTTP_INCLUDE=/tmp/prometheus-server.conf"]
CMD ["export KONG_PLUGINS=bundled,prometheus-adv"]
CMD ["kong reload"]
CMD ["rm -rf /tmp/kong-plugin-prometheus"]