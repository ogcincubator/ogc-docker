#!/bin/sh
set -e

SSL_DIR=/etc/squid/ssl
SSL_DB=/var/cache/squid/ssl_db
MAPPINGS_FILE=/etc/squid/url-mappings.conf
SQUID_CONF=/etc/squid/squid.conf
TEMPLATE_FILE=/etc/squid/squid.conf.tpl

# ── 1. Parse URL_MAPPINGS ─────────────────────────────────────────────────────
# Format: one PATTERN=INTERNAL_URL per line, split on the first '=' so that
# '=' inside query strings (e.g. ?uri=https://...) is never mangled.
#
# docker-compose example (YAML block scalar):
#
#   environment:
#     URL_MAPPINGS: |
#       https://example.com/ld/=http://nginx:8080/ld/
#       https://other.org/=http://prez:5000/object?uri=https://other.org/

printf '' > "$MAPPINGS_FILE"

if [ -n "$URL_MAPPINGS" ]; then
    echo "Configuring URL mappings:"
    printf '%s\n' "$URL_MAPPINGS" | while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        pattern="${entry%%=*}"
        internal_url="${entry#*=}"
        [ -z "$pattern" ] && continue
        [ -z "$internal_url" ] && continue
        printf '%s\t%s\n' "$pattern" "$internal_url" >> "$MAPPINGS_FILE"
        printf '  %s  ->  %s\n' "$pattern" "$internal_url"
    done
else
    echo "No URL_MAPPINGS defined – all traffic will be passed through unchanged."
fi

# ── 2. Build the ssl_bump ACL for mapped HTTPS domains ───────────────────────
# Only bump TLS for domains that actually appear in https:// patterns.
# All other HTTPS traffic is spliced through with no interception at all.
HTTPS_HOSTNAMES=$(awk -F'\t' '!/^#/ && NF==2 && $1 ~ /^https:\/\// {
    url = $1
    gsub(/^https:\/\//, "", url)
    gsub(/\/.*$/, "", url)
    print url
}' "$MAPPINGS_FILE" | sort -u | tr '\n' ' ')
HTTPS_HOSTNAMES="${HTTPS_HOSTNAMES% }"

if [ -n "$HTTPS_HOSTNAMES" ]; then
    MAPPED_DOMAINS_ACL="acl mapped_domains dstdomain $HTTPS_HOSTNAMES"
    echo "TLS will be intercepted for: $HTTPS_HOSTNAMES"
else
    MAPPED_DOMAINS_ACL="acl mapped_domains dstdomain .invalid-placeholder.local"
fi

# ── 3. SSL CA certificate ─────────────────────────────────────────────────────
# Mount a volume at /etc/squid/ssl to persist the CA across container restarts
# so clients only need to import it once.
#
# The CA is generated with an X.509 Name Constraints extension that restricts
# it to the mapped domains only.  Even if the CA key were stolen, it cannot
# forge a certificate for any other domain (gmail.com, your bank, etc.).
# Delete ca.crt + ca.key and restart the container to regenerate (e.g. when
# adding new domains to URL_MAPPINGS).

mkdir -p "$SSL_DIR"

if [ ! -f "$SSL_DIR/ca.crt" ] || [ ! -f "$SSL_DIR/ca.key" ]; then
    echo "Generating self-signed CA (Name Constraints: $HTTPS_HOSTNAMES)..."

    # Build the OpenSSL config dynamically so Name Constraints match exactly
    # the domains being tested.
    CA_CNF=/tmp/rainbow-proxy-ca.cnf
    cat > "$CA_CNF" <<EOF
[req]
distinguished_name = dn
x509_extensions    = v3_ca
prompt             = no

[dn]
CN = rainbow-proxy CA

[v3_ca]
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints       = critical, CA:true, pathlen:0
keyUsage               = critical, keyCertSign, cRLSign
EOF

    if [ -n "$HTTPS_HOSTNAMES" ]; then
        printf 'nameConstraints = critical, @nc\n\n[nc]\n' >> "$CA_CNF"
        i=1
        for domain in $HTTPS_HOSTNAMES; do
            # permit the bare domain and all its subdomains
            printf 'permitted;DNS.%d = %s\n'  "$i"       "$domain" >> "$CA_CNF"
            printf 'permitted;DNS.%d = .%s\n' "$(($i+1))" "$domain" >> "$CA_CNF"
            i=$(($i+2))
        done
    fi

    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -config  "$CA_CNF" \
        -keyout  "$SSL_DIR/ca.key" \
        -out     "$SSL_DIR/ca.crt"
    rm -f "$CA_CNF"
else
    echo "Using existing CA certificate from $SSL_DIR"
fi

chmod 600 "$SSL_DIR/ca.key"
chmod 644 "$SSL_DIR/ca.crt"

echo ""
echo "=== CA certificate ==="
echo "Import into Firefox: Settings → Privacy & Security → View Certificates"
echo "                     → Authorities → Import → select ca.crt"
echo "Import for curl:     curl --cacert /path/to/ca.crt  (or use -k per-request)"
echo ""
cat "$SSL_DIR/ca.crt"
echo "======================"
echo ""

# ── 4. SSL dynamic-certificate database ───────────────────────────────────────
if [ ! -d "$SSL_DB" ]; then
    echo "Initialising SSL certificate database..."
    /usr/lib/squid/security_file_certgen -c -s "$SSL_DB" -M 4MB
fi

# ── 5. Generate squid.conf from template ──────────────────────────────────────
awk -v acl="$MAPPED_DOMAINS_ACL" \
    '/__MAPPED_DOMAINS_ACL__/ { print acl; next } { print }' \
    "$TEMPLATE_FILE" > "$SQUID_CONF"

# ── 6. Initialise Squid swap directories and start ───────────────────────────
squid -z -N -f "$SQUID_CONF" 2>/dev/null || true

echo "Starting Squid on port 3128..."
exec squid -N -f "$SQUID_CONF"
