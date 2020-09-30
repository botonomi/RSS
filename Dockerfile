#FROM alpine:3.10
FROM skyzyx/alpine-pandoc:1.2.0

RUN apk update \
 && apk add jq curl gettext perl pandoc

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
