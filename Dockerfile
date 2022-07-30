
FROM        --platform=$BUILDPLATFORM alpine:latest

LABEL       author="Alex Grist" maintainer="alex@nebulous.cloud"

ENV         DEBIAN_FRONTEND noninteractive

RUN         apk add --update --no-cache ca-certificates curl file jq tar tzdata xz libgcc libstdc++ \
				&& adduser -D -h /home/container container

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

COPY        ./entrypoint.sh /entrypoint.sh
CMD         [ "/bin/ash", "/entrypoint.sh" ]
