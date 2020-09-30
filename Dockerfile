#FROM alpine:3.10
FROM alpine:edge

RUN apk update \
 && apk add jq curl gettext perl 

RUN apk add --upgrade pandoc

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
