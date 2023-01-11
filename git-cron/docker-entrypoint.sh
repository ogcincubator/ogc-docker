#!/bin/sh

REPOS="$(printenv | grep ^CRON_REPO_.\\+)"

if [ -z "${REPOS}" ]; then
  echo "Error: no repositories specified" >&2
  exit 1
fi

mkdir -p /repos

MARKER='#Added by Docker entrypoint'
CRONTAB="/etc/crontabs/root"

sed -n "/${MARKER}/q;p" -i "$CRONTAB"
echo "${MARKER}" >> "${CRONTAB}"
echo "${CRON_EXPRESSION} /bin/bash /update-repos.sh" >> "${CRONTAB}"

/update-repos.sh &

exec crond -l 2 -f