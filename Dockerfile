#FROM alpine:3.10
FROM conoria/alpine-pandoc


RUN apk --update add jq curl gettext perl 

RUN jq --version

COPY entrypoint.sh /entrypoint.sh

RUN chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
