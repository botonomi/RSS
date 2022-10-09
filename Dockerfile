#FROM alpine:3.10
#FROM conoria/alpine-pandoc:latest
FROM pandoc/core

RUN apk --update add jq curl gettext perl 

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
