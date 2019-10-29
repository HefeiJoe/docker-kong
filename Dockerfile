FROM alpine:3.10
LABEL maintainer="Kong Core Team <team-core@konghq.com>"

ENV KONG_VERSION 1.4.0
ENV KONG_SHA256 e31080487cfb8262a839c19d5e8fdb18b7686e9e4cc594803eaa565e0b34ff7a
ENV KONG_PLUGINS=bundled,prometheus-adv


RUN adduser -Su 1337 kong \
	&& mkdir -p "/usr/local/kong" \
	&& apk add --no-cache --virtual .build-deps wget tar ca-certificates \
	&& apk add --no-cache libgcc openssl pcre perl tzdata curl libcap su-exec zip luarocks \
	&& wget -O kong.tar.gz "https://bintray.com/kong/kong-alpine-tar/download_file?file_path=kong-$KONG_VERSION.amd64.apk.tar.gz" \
	&& echo "$KONG_SHA256 *kong.tar.gz" | sha256sum -c - \
	&& tar -xzf kong.tar.gz -C /tmp \
	&& rm -f kong.tar.gz \
	&& cp -R /tmp/usr / \
	&& rm -rf /tmp/usr \
	&& cp -R /tmp/etc / \
	&& rm -rf /tmp/etc \
	&& apk del .build-deps \
	&& chown -R kong:0 /usr/local/kong \
	&& chmod -R g=u /usr/local/kong

COPY prometheus-server.conf /usr/local/kong/prometheus-server.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]

RUN apk add --no-cache git \
        && git clone https://github.com/HefeiJoe/kong-plugin-prometheus.git /tmp/kong-plugin-prometheus \
        && cd /tmp/kong-plugin-prometheus/ \
        && luarocks make *.rockspec \
        && rm -rf /tmp/kong-plugin-prometheus/
