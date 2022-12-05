#!/bin/bash
cd /app-theme
export SPARQL_ENDPOINT SYSTEM_URI_BASE
echo "SPARQL_ENDPOINT = ${SPARQL_ENDPOINT}"
echo "SYSTEM_URI_BASE = ${SYSTEM_URI_BASE}"
chmod a+x apply.sh
./apply.sh
cd /app
exec gunicorn -b 0.0.0.0:8000 vocprez.app:app