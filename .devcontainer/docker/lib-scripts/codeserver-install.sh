#!/usr/bin/env bash

set -e

$LOGGER "Installing code-server utilities..."

VERSION="${CODESERVER_VERSION:-latest}"
if [ "$VERSION" = "latest" ]; then
    VERSION="$(curl -sSLf https://api.github.com/repos/coder/code-server/releases/latest \
        | jq -r .tag_name | sed 's/^v//')"
fi

# shellcheck disable=SC1091
. /tmp/lib-scripts/install-helper.sh

if __set_url_parts "coder/code-server" "$VERSION"; then
    build_url() {
        url_prefix="https://github.com/coder/code-server/releases/download/v"
        echo "${url_prefix}${DOWNLOAD_VERSION}/code-server-${DOWNLOAD_VERSION}-${DOWNLOAD_OS}-${DOWNLOAD_ARCH}.tar.gz"
    }
    DOWNLOAD_URL="$(build_url)"
else
    $LOGGER "Failed to determine download parameters for code-server version $VERSION"
    exit 1
fi

INSTALL_PREFIX="$HOME/.local/lib"
mkdir -p "$INSTALL_PREFIX" "$HOME/.local/bin"
rm -rf "$INSTALL_PREFIX/code-server-$DOWNLOAD_VERSION"

$LOGGER "Downloading code-server from $DOWNLOAD_URL ..."
if (
    __download_tar "$DOWNLOAD_URL" "$INSTALL_PREFIX"
); then
    (
        set -x
        mv "$INSTALL_PREFIX/code-server-$DOWNLOAD_VERSION-$DOWNLOAD_OS-$DOWNLOAD_ARCH" "$INSTALL_PREFIX/code-server-$DOWNLOAD_VERSION"
    )
    ln -s "$INSTALL_PREFIX/code-server-$DOWNLOAD_VERSION/bin/code-server" "$HOME/.local/bin/code-server"
    # update-alternatives --install "$HOME/.local/bin/code-server" code-server "$INSTALL_PREFIX/code-server-$DOWNLOAD_VERSION/bin/code-server" 1

else
    $LOGGER "Failed to download code-server from $DOWNLOAD_URL"
fi

$LOGGER "Done! code-server utilities installation complete."
