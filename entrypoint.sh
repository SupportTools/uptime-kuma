#!/usr/bin/env sh

# set -e Exit the script if an error happens
set -e
PUID=${PUID=0}
PGID=${PGID=0}

echo "==> Starting application with user $PUID group $PGID"

# --clear-groups Clear supplementary groups.
exec setpriv --reuid "$PUID" --regid "$PGID" --clear-groups "$@"