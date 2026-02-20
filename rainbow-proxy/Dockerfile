FROM alpine:3

RUN apk update && apk add --no-cache squid python3 openssl

COPY squid.conf.tpl   /etc/squid/squid.conf.tpl
COPY rewriter.py      /usr/local/bin/rewriter.py
COPY entrypoint.sh    /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/rewriter.py \
    && mkdir -p /var/cache/squid /var/log/squid /etc/squid/ssl

EXPOSE 3128

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
