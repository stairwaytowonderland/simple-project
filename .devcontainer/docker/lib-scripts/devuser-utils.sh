#!/bin/sh

set -e

# This script installs common utilities and dependencies

# Install common packages
$LOGGER "Installing devuser utilities and dependencies..."

apt-get update

export DEBIAN_FRONTEND=noninteractive

# * Install sudo here so production image doesn't have it
# * Also install python because pre-commit requires it
apt-get -y install --no-install-recommends \
    sudo \
    bash-completion \
    software-properties-common

if [ "$IMAGE_NAME" = "ubuntu" ] && [ "$USE_PPA_IF_AVAILABLE" = "true" ]; then
    apt-get -y install --no-install-recommends git-core
    add-apt-repository ppa:git-core/ppa \
        && apt-get update \
        && apt-get -y install --no-install-recommends git
else
    apt-get -y install --no-install-recommends git
fi

# Install git (either from PPA or from source)
# ! Installing from source causes issues for the gh CLI dev container feature
# /tmp/lib-scripts/git-install.sh

# * We don't want to use --no-install-recommends here
# since the additional utilities (games) may depend on some recommended packages.
apt-get -y install \
    cowsay \
    fortune

$LOGGER "Done! Devuser utilities installation complete."
