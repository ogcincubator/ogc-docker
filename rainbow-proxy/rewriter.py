#!/usr/bin/env python3
"""
Squid url_rewrite_program helper for rainbow-proxy.

Reads URL mappings from /etc/squid/url-mappings.conf.
Each non-comment, non-empty line is:
    PATTERN <TAB> INTERNAL_URL

For every proxied request Squid passes the URL as the first whitespace-
separated token on stdin; the helper replies with:
    OK              – pass through unchanged
    OK url=NEW_URL  – rewrite to NEW_URL

Rewriting rule (applied to the first matching pattern):
    NEW_URL = INTERNAL_URL + url[len(PATTERN):]

This covers two common cases:

  Path proxy:
    PATTERN      https://example.com/ld/
    INTERNAL_URL http://nginx:8080/ld/
    https://example.com/ld/foo  →  http://nginx:8080/ld/foo

  URI-as-query-param:
    PATTERN      https://example.com/ld/
    INTERNAL_URL http://prez:5000/object?uri=https://example.com/ld/
    https://example.com/ld/foo  →  http://prez:5000/object?uri=https://example.com/ld/foo

In both cases pattern and internal_url should have matching trailing slashes.
"""

import sys
import os

MAPPINGS_FILE = '/etc/squid/url-mappings.conf'


def load_mappings():
    mappings = []
    try:
        with open(MAPPINGS_FILE) as fh:
            for line in fh:
                line = line.rstrip('\n')
                if not line or line.startswith('#'):
                    continue
                parts = line.split('\t', 1)
                if len(parts) == 2:
                    mappings.append((parts[0], parts[1]))
    except FileNotFoundError:
        pass
    return mappings


def rewrite(url, mappings):
    for pattern, internal_url in mappings:
        if url.startswith(pattern):
            return internal_url + url[len(pattern):]
    return None


def main():
    mappings = load_mappings()
    sys.stderr.write(f'rainbow-proxy rewriter: loaded {len(mappings)} mapping(s)\n')
    sys.stderr.flush()

    for raw in sys.stdin:
        line = raw.rstrip('\n')
        if not line:
            continue

        # Squid input: URL [SP client_ip/fqdn SP user SP method SP kv-pairs]
        tokens = line.split()
        if not tokens:
            print('BH')
            sys.stdout.flush()
            continue

        url = tokens[0]
        new_url = rewrite(url, mappings)

        if new_url:
            print(f'OK url={new_url}')
        else:
            print('OK')

        sys.stdout.flush()


if __name__ == '__main__':
    main()
