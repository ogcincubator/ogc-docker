#!/bin/sh

# Migrations
python manage.py makemigrations --noinput
python manage.py migrate --noinput

# Create superuser
cat <<EOF | python manage.py shell >/dev/null 2>&1 && echo "Superuser ${SUPERUSER} created" || echo "User ${SUPERUSER} already exists, not creating"
from django.contrib.auth import get_user_model
User = get_user_model()
User.objects.create_superuser('${SUPERUSER}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
EOF

# Update settings
export SETTINGS_FILE="/app/settings-base.py"
for CONFVAR in DEBUG URIREDIRECT_ALTR_BASETEMPLATE SMUGGLER_FIXTURE_DIR STATIC_ROOT ALLOWED_HOSTS ; do
  VARNAME="DJANGO_${CONFVAR}"
  eval CONFVALUE="\$${VARNAME}"
  grep -q ^${CONFVAR} "${SETTINGS_FILE}" \
    && sed -r "s/^${CONFVAR}\s+=.*/${CONFVAR} = ${CONFVALUE}/" -i "${SETTINGS_FILE}" \
    || echo "${CONFVAR} = ${CONFVALUE}" >> "${SETTINGS_FILE}"
done

python /app/install-modules.py

if [ -f "/app/installed-modules" ]; then
  python manage.py makemigrations --noinput
  python manage.py migrate --noinput
  rm /app/installed-modules
fi

yes yes | python manage.py collectstatic

gunicorn --bind unix:/run/gunicorn.sock --access-logfile - "${PROJECT_NAME}.wsgi:application" --daemon

exec "$@"