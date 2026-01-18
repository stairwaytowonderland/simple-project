#!/usr/bin/env bash

set -e

# This script installs common utilities and dependencies

# Install common packages
$LOGGER "Installing common utilities and dependencies..."

apt-get update

export DEBIAN_FRONTEND=noninteractive

apt-get -y install --no-install-recommends \
    apt-transport-https \
    build-essential \
    ca-certificates \
    gnupg2 \
    curl \
    wget \
    unzip \
    vim \
    nano \
    less \
    procps \
    lsb-release \
    tzdata \
    jq \
    yq

$LOGGER "Done. Common utilities installation complete!"
