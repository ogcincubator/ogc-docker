#!/bin/sh
set -e

TEMPLATE_FILE="${TEMPLATE_FILE:-/etc/nginx/nginx.conf.template}"
OUTPUT_FILE="${OUTPUT_FILE:-/etc/nginx/conf.d/default.conf}"

PREZ_BACKEND_URL="${PREZ_BACKEND_URL:-http://prez:8000}"
PREZ_UI_URL="${PREZ_UI_URL:-http://prez-ui:8080}"
PREZ_BACKEND_PATH="${PREZ_BACKEND_PATH:-/prez-b}"
PREZ_UI_PATH="${PREZ_UI_PATH:-/prez}"
FUSEKI_URL="${FUSEKI_URL:-http://fuseki:3030}"
FUSEKI_PATH="${FUSEKI_PATH:-/fuseki}"

if [ -z "$EXTERNAL_PREZ_BACKEND_URL" ]; then
    echo "ERROR: EXTERNAL_PREZ_BACKEND_URL environment variable must be set"
    exit 1
fi

if [ -z "$REDIRECTS" ]; then
    echo "ERROR: REDIRECTS environment variable must be set"
    exit 1
fi

PREZ_BACKEND_URL=$(echo "$PREZ_BACKEND_URL" | sed 's|/$||')
PREZ_UI_URL=$(echo "$PREZ_UI_URL" | sed 's|/$||')
EXTERNAL_PREZ_BACKEND_URL=$(echo "$EXTERNAL_PREZ_BACKEND_URL" | sed 's|/$||')
PREZ_BACKEND_PATH="/$(echo "$PREZ_BACKEND_PATH" | sed 's|^/||; s|/$||')"
PREZ_UI_PATH="/$(echo "$PREZ_UI_PATH" | sed 's|^/||; s|/$||')"
FUSEKI_URL=$(echo "$FUSEKI_URL" | sed 's|/$||')
FUSEKI_PATH="/$(echo "$FUSEKI_PATH" | sed 's|^/||; s|/$||')"

echo "Generating nginx config..."
echo "  PREZ_BACKEND_URL: $PREZ_BACKEND_URL"
echo "  PREZ_UI_URL: $PREZ_UI_URL"
echo "  PREZ_BACKEND_PATH: $PREZ_BACKEND_PATH"
echo "  PREZ_UI_PATH: $PREZ_UI_PATH"
echo "  FUSEKI_URL: $FUSEKI_URL"
echo "  FUSEKI_PATH: $FUSEKI_PATH"
echo "  EXTERNAL_PREZ_BACKEND_URL: $EXTERNAL_PREZ_BACKEND_URL"

REDIRECT_BLOCKS=$(echo "$REDIRECTS" | while IFS='=' read -r prefix base_url; do
    [ -z "$prefix" ] && continue
    prefix=$(echo "$prefix" | sed 's|/$||')
    base_url=$(echo "$base_url" | sed 's|/$||')
    cat <<EOF
    location ~ ^${prefix}/(.*)$ {
        return 302 ${EXTERNAL_PREZ_BACKEND_URL}/object?uri=${base_url}/\$1;
    }
EOF
done)

awk -v block="$REDIRECT_BLOCKS" \
    -v prez_backend="$PREZ_BACKEND_URL" \
    -v prez_ui="$PREZ_UI_URL" \
    -v prez_backend_path="$PREZ_BACKEND_PATH" \
    -v prez_ui_path="$PREZ_UI_PATH" \
    -v fuseki="$FUSEKI_URL" \
    -v fuseki_path="$FUSEKI_PATH" \
    '/^__REDIRECTS__$/ { print block; next }
     { gsub(/__PREZ_BACKEND_URL__/, prez_backend); gsub(/__PREZ_UI_URL__/, prez_ui);
       gsub(/__PREZ_BACKEND_PATH__/, prez_backend_path); gsub(/__PREZ_UI_PATH__/, prez_ui_path);
       gsub(/__FUSEKI_URL__/, fuseki); gsub(/__FUSEKI_PATH__/, fuseki_path); print }' \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Config written to $OUTPUT_FILE"
cat "$OUTPUT_FILE"

exec nginx -g "daemon off;"