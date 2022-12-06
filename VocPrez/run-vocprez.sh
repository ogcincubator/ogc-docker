#!/bin/bash
cd /app-theme
export SPARQL_ENDPOINT SYSTEM_URI_BASE
echo "SPARQL_ENDPOINT = ${SPARQL_ENDPOINT}"
echo "SYSTEM_URI_BASE = ${SYSTEM_URI_BASE}"
chmod a+x apply.sh
./apply.sh
cd /app
rm -f vocprez/cache/DATA.p
exec gunicorn -b 0.0.0.0:8000 vocprez.app:app