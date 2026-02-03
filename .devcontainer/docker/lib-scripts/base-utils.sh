#!/bin/sh

# Only check for errors (set -e)
# Don't check for unset variables (set -u) since variables are set in Dockerfile
# Pipepail (set -o pipefail) is not available in sh
set -e

LEVEL='ƒ' $LOGGER "Installing base utilities and dependencies..."

# shellcheck disable=SC1091
. /helpers/install-helper.sh

PACKAGES_TO_INSTALL="${PACKAGES_TO_INSTALL% } $(
    cat << EOF
openssh-client
EOF
)"

if [ "$PRE_COMMIT_ENABLED" = "true" ] \
    && ! "$PIPX" > /dev/null 2>&1 \
    && ! type "$BREW" > /dev/null 2>&1; then
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $(
        cat << EOF
pre-commit
EOF
    )"
fi

# shellcheck disable=SC2086
update_and_install "${PACKAGES_TO_INSTALL# }"

LEVEL='√' $LOGGER "Done! Base utilities installation complete."
