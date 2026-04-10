# nginx-ld

An nginx-based reverse proxy that serves a [Prez](https://github.com/RDFLib/prez) deployment and dynamically generates redirect rules for linked data URI resolution.

On startup, the entrypoint generates an nginx config from environment variables and the bundled template, then starts nginx.

## Environment variables

| Variable | Required | Default                          | Description |
|---|---|----------------------------------|---|
| `EXTERNAL_PREZ_BACKEND_URL` | Yes | —                                | Public-facing base URL of the Prez backend, used to build redirect targets (e.g. `https://example.com/prez-b`) |
| `REDIRECTS` | Yes | —                                | Newline-separated list of `prefix=base_url` redirect rules (see below) |
| `PREZ_BACKEND_URL` | No | `http://prez:8000`               | Internal URL of the Prez backend service |
| `PREZ_UI_URL` | No | `http://prez-ui:8080`            | Internal URL of the Prez UI service |
| `PREZ_BACKEND_PATH` | No | `/prez-b`                        | Path prefix for the Prez backend proxy route |
| `PREZ_UI_PATH` | No | `/prez`                          | Path prefix for the Prez UI proxy route |
| `FUSEKI_URL` | No | `http://fuseki:3030`             | Internal URL of the Fuseki service |
| `FUSEKI_PATH` | No | `/fuseki`                        | Path prefix for the Fuseki proxy route |
| `TEMPLATE_FILE` | No | `/etc/nginx/nginx.conf.template` | Path to the nginx config template |
| `OUTPUT_FILE` | No | `/etc/nginx/conf.d/default.conf` | Path where the generated config is written |

## Proxy routes

| Path | Proxied to |
|---|---|
| `PREZ_UI_PATH` (`/prez`) | `PREZ_UI_URL` |
| `PREZ_BACKEND_PATH` (`/prez-b`) | `PREZ_BACKEND_URL` |
| `FUSEKI_PATH` (`/fuseki`) | `FUSEKI_URL` |

## Redirect rules (`REDIRECTS`)

`REDIRECTS` is a newline-separated list of `prefix=base_url` pairs. Each entry generates an nginx location block that redirects requests to the Prez object resolution endpoint.

A request to `{prefix}/{id}` is redirected to:
```
{EXTERNAL_PREZ_BACKEND_URL}/object/resource?uri={base_url}/{id}
```

### Example

```
REDIRECTS=/def/ont=https://example.com/ontology
/def/voc=https://example.com/vocabulary
```

A request to `/def/ont/MyClass` redirects to:
```
https://example.com/prez-b/object/resource?uri=https://example.com/ontology/MyClass
```

## Docker Compose example

```yaml
services:
  nginx-ld:
    image: dockerogc/nginx-ld
    ports:
      - "8080:80"
    environment:
      EXTERNAL_PREZ_BACKEND_URL: https://example.com/prez-b
      REDIRECTS: |
        /def/ont=https://example.com/ontology
        /def/voc=https://example.com/vocabulary
    depends_on:
      - prez
      - prez-ui
```

## Source

https://github.com/ogcincubator/ogc-docker