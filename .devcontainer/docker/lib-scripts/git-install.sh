#!/usr/bin/env bash

set -e

# This script installs common utilities and dependencies

GIT_VERSION="${GIT_VERSION:-latest}"
USE_PPA_IF_AVAILABLE="${USE_PPA_IF_AVAILABLE:-true}"

apt-get update

export DEBIAN_FRONTEND=noninteractive

# * If installing from source, GIT_VERSION needs to be reset to the actual version
# being built, since the Makefile uses it. We could also avoid using GIT_VERSION
# as a global variable, but resetting the variable for the build is simpler.
if [ "$(echo "${GIT_VERSION}" | grep -o '\.' | wc -l)" != "2" ]; then
    version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/git/git/tags" | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -rV)"
    if [ "${GIT_VERSION}" = "latest" ] || [ "${GIT_VERSION}" = "lts" ] || [ "${GIT_VERSION}" = "current" ]; then
        GIT_VERSION="$(echo "${version_list}" | head -n 1)"
    else
        set +e
        GIT_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${GIT_VERSION//./\\.}([\\.\\s]|$)")"
        set -e
    fi
    if [ -z "${GIT_VERSION}" ] || ! echo "${version_list}" | grep "^${GIT_VERSION//./\\.}$" > /dev/null 2>&1; then
        LEVEL=error $LOGGER "Invalid git version: ${GIT_VERSION}"
        exit 1
    fi
fi

git_download() {
    local git_version="$1"
    local git_tar="git-${git_version}.tar.gz"
    local git_url="https://www.kernel.org/pub/software/scm/git/${git_tar}"
    # shellcheck disable=SC2034  # Unused variables left for readability
    local git_url_mirror1="https://mirrors.edge.kernel.org/pub/software/scm/git/git-${git_version}.tar.gz"
    # shellcheck disable=SC2034  # Unused variables left for readability
    local git_url_mirror2="https://github.com/git/git/archive/v${git_version}.tar.gz"
    $LOGGER "Downloading source for git version ${git_version}..."
    (
        set -x
        # curl -sSL -o "/tmp/${git_tar}" "${git_url}" | tar -xzC /tmp
        curl -sSL -o "/tmp/${git_tar}" "${git_url}"
        tar -xzf "/tmp/${git_tar}" -C /tmp/
    )
}

git_build() {
    git_version="$1"
    $LOGGER "Building git version ${git_version}..."
    # cd "/tmp/git-${git_version}"
    # ./configure --prefix=/usr/local
    # make all
    # make install
    make -C "/tmp/git-${git_version}" prefix=/usr/local sysconfdir=/etc all
    make -C "/tmp/git-${git_version}" prefix=/usr/local sysconfdir=/etc install
    update-alternatives --install /usr/bin/git git /usr/local/bin/git 1
}

git_install() {
    local git_version="$1"

    # Remove any existing git installation
    apt-get -y remove git

    $LOGGER "Preparing to install git version ${git_version}..."

    if { [ "${git_version}" = "latest" ] || [ "${git_version}" = "lts" ] || [ "${git_version}" = "current" ]; } \
        && [ "${IMAGE_NAME}" = "ubuntu" ] && [ "${USE_PPA_IF_AVAILABLE}" = "true" ]; then
            apt-get -y install --no-install-recommends git-core
            add-apt-repository ppa:git-core/ppa \
                && apt-get update \
                && apt-get -y install --no-install-recommends git
        $LOGGER "Done! GIT installation from PPA complete!"
    else
        # Install build dependencies
        # https://git-scm.com/book/en/v2/Getting-Started-Installing-Git#_installing_from_source
        apt-get -y install --no-install-recommends \
            dh-autoreconf libcurl4-gnutls-dev libexpat1-dev \
            gettext libz-dev libssl-dev \
            install-info

        git_download "${git_version}"
        git_build "${git_version}"
        rm -f "/tmp/git-${git_version}.tar.gz"
        rm -rf "/tmp/git-${git_version}"
        $LOGGER "Done! GIT installation from source complete!"

        # Remove build dependencies
        apt-get -y remove \
            dh-autoreconf libcurl4-gnutls-dev libexpat1-dev \
            gettext libz-dev libssl-dev \
            install-info
    fi
}

git_install "$GIT_VERSION"

$LOGGER "Done! Devuser utilities installation complete."
