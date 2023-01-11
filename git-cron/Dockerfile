FROM alpine:3

ENV CRON_EXPRESSION "*/30 * * * *"

RUN apk add git
WORKDIR /
COPY docker-entrypoint.sh update-repos.sh ./
RUN chmod +x docker-entrypoint.sh update-repos.sh

ENTRYPOINT ["/docker-entrypoint.sh"]


