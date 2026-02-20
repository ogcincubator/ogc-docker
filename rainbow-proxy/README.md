# rainbow-proxy

A Squid-based HTTP/HTTPS forward proxy for testing linked data deployments locally before they go live.

It intercepts requests to production URIs and rewrites them to internal Docker services, so tools like curl, Firefox, or any linked data client can dereference `https://example.com/ld/…` URIs against a local stack without changing any application code.

All other traffic is passed through to its real destination.

## How it works

URL mappings are provided via an environment variable. For each mapping, the proxy matches the URL prefix and rewrites it to the configured internal URL:

```
https://example.com/ld/foo  →  http://prez:5000/object?uri=https://example.com/ld/foo
https://example.com/ld/foo  →  http://nginx:8080/ld/foo
```

For `https://` patterns, Squid uses SSL bump to intercept TLS for mapped domains only (everything else is tunnelled through unchanged). A self-signed CA is generated on first start, scoped via X.509 **Name Constraints** to the mapped domains so it cannot forge certificates for any other site.

## Configuration

### `URL_MAPPINGS` environment variable

One `PATTERN=INTERNAL_URL` per line. The split is on the **first** `=`, so `=` inside query strings is safe.

Two common patterns:

**Path proxy** — append the remaining path to the internal base URL:
```
https://example.com/ld/=http://nginx:8080/ld/
```
`https://example.com/ld/foo` → `http://nginx:8080/ld/foo`

**URI as query parameter** — pass the full original URI to a backend that resolves by URI:
```
https://example.com/ld/=http://prez:5000/object?uri=https://example.com/ld/
```
`https://example.com/ld/foo` → `http://prez:5000/object?uri=https://example.com/ld/foo`

Pattern and internal URL should have matching trailing slashes. The first matching pattern wins.

## docker-compose example

```yaml
services:
  rainbow-proxy:
    build: ./rainbow-proxy
    environment:
      URL_MAPPINGS: |
        https://example.com/ld/=http://nginx:8080/ld/
        https://other.org/=http://prez:5000/object?uri=https://other.org/
    volumes:
      - ./ssl:/etc/squid/ssl   # persist CA across restarts
    ports:
      - "3128:3128"

  nginx:
    image: nginx
    # ...

  prez:
    image: ghcr.io/rdflib/prez:latest
    # ...
```

## Using the proxy

Set the proxy for your client:

```bash
export HTTP_PROXY=http://localhost:3128
export HTTPS_PROXY=http://localhost:3128
```

### curl

No setup required — use `-k` to skip certificate verification:

```bash
curl -k https://example.com/ld/foo
# or explicitly:
curl -k -x http://localhost:3128 https://example.com/ld/foo
```

Or import the CA once and drop `-k`:

```bash
curl --cacert ssl/ca.crt https://example.com/ld/foo
```

### Firefox

Either click through the security warning when it appears ("Advanced → Accept the Risk and Continue"), or import the CA once into Firefox's own certificate store — this does **not** affect the system trust store:

Settings → Privacy & Security → View Certificates → Authorities → Import → select `ssl/ca.crt`

### Python requests

```python
import requests
requests.get("https://example.com/ld/foo",
             proxies={"https": "http://localhost:3128"},
             verify=False)           # or verify="ssl/ca.crt"
```

## CA certificate and security

The CA is printed to stdout on startup and written to `/etc/squid/ssl/ca.crt` inside the container (available via the `ssl/` volume mount).

The CA is generated with an X.509 **Name Constraints** extension listing only the mapped domains. Even if the private key were compromised, it cannot be used to forge certificates for any domain outside that list.

To rotate the CA (e.g. after adding new domains to `URL_MAPPINGS`), delete `ssl/ca.crt` and `ssl/ca.key` and restart the container, then re-import if you had imported previously.

## Ports

| Port | Protocol |
|------|----------|
| 3128 | HTTP proxy (also handles CONNECT/HTTPS via SSL bump) |
