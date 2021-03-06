FROM alpine:3.10
LABEL maintainer="Kong Core Team <team-core@konghq.com>"

ENV KONG_VERSION 1.3.0
ENV KONG_SHA256 566f2a8009cbd7eebd32843c2f03c8d5f736139110988dc12dee161046428112
ENV KONG_PLUGINS=bundled,ensaas-apim

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

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY ensaas-apim-server.conf /usr/local/kong/ensaas-apim-server.conf

RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]

RUN apk add --no-cache git \
        && git clone https://github.com/HefeiJoe/kong-plugin-prometheus.git /tmp/kong-plugin-ensaas-apim \
        && cd /tmp/kong-plugin-ensaas-apim/ \
        && luarocks make *.rockspec \
        && rm -rf /tmp/kong-plugin-ensaas-apim/
