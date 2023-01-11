#!/bin/sh
set -e

cd /repos
REPOS="$(printenv | grep ^CRON_REPO_.\\+)"

echo "${REPOS}" | while read REPO; do
  SUBDIR="${REPO%%=*}"
  SUBDIR="${SUBDIR#CRON_REPO_}"
  URL="${REPO#*=}"
  BRANCH="${REPO#*@@}"
  if [ "${BRANCH}" == "${REPO}" ]; then # no @@ found
    BRANCH=
  fi

  if [ -e "${SUBDIR}" ]; then
    echo "Updating ${SUBDIR}"
    cd "${SUBDIR}"
    git checkout .
    git clean -fd
    if [ -n "${BRANCH}" ]; then
      git checkout -b "${BRANCH}"
    fi
    git pull
  else
    if [ -n "${BRANCH}" ]; then
      echo "Cloning ${URL} (branch ${BRANCH}) into ${SUBDIR}"
      echo git clone --depth 1 "${URL}" -b "${BRANCH}" "${SUBDIR}"
      git clone --depth 1 "${URL}" -b "${BRANCH}" "${SUBDIR}"
    else
      echo "Cloning ${URL} (default branch) into ${SUBDIR}"
      echo git clone --depth 1 "${URL}" "${SUBDIR}"
      git clone --depth 1 "${URL}" "${SUBDIR}"
    fi
  fi

  cd /repos
done

trap - ERR