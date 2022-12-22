#!/bin/bash
cd /app-theme
export SPARQL_ENDPOINT SYSTEM_URI_BASE
echo "SPARQL_ENDPOINT = ${SPARQL_ENDPOINT}"
echo "SYSTEM_URI_BASE = ${SYSTEM_URI_BASE}"
chmod a+x apply.sh
./apply.sh
cd /app
rm -f vocprez/cache/DATA.p
if [ -f vocprez/_config/additional.py ]; then
  cat vocprez/_config/__init__.py <(echo -e '\n### Additional configuration by Docker') vocprez/_config/additional.py > /vocprez_config.py
  mv /vocprez_config.py vocprez/_config/__init__.py
fi
exec gunicorn -b 0.0.0.0:8000 vocprez.app:app