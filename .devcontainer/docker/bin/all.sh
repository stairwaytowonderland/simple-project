#!/usr/bin/env bash

# ---------------------------------------
set -euo pipefail

if [ -z "$0" ]; then
    echo "Cannot determine script path"
    exit 1
fi

script_name="$0"
script_dir="$(cd "$(dirname "$script_name")" && pwd)"
# ---------------------------------------

# shellcheck disable=SC1091
. "$script_dir/load-env.sh" "$script_dir/.."

REPO_NAME="${REPO_NAME-}"
REPO_NAMESPACE="${REPO_NAMESPACE-}"
REMOTE_USER="${REMOTE_USER-}"

main() {
    # Newline-separated list of commands to run
    local all_commands=""
    while IFS= read -r cmd || [ -n "$cmd" ]; do
        [ -z "$cmd" ] && continue
        if [ -z "$all_commands" ]; then
            all_commands="$cmd"
        else
            all_commands="$all_commands && $cmd"
        fi
    done << EOF
.devcontainer/docker/bin/build.sh $REPO_NAME $REMOTE_USER --build-arg PYTHON_VERSION=devcontainer .
.devcontainer/docker/bin/build.sh $REPO_NAME:devtools $REMOTE_USER --build-arg PYTHON_VERSION=devcontainer .
.devcontainer/docker/bin/build.sh $REPO_NAME:cloudtools $REMOTE_USER --build-arg PYTHON_VERSION=devcontainer .
.devcontainer/docker/bin/publish.sh $REPO_NAME $REPO_NAMESPACE
.devcontainer/docker/bin/publish.sh $REPO_NAME:devtools $REPO_NAMESPACE
.devcontainer/docker/bin/publish.sh $REPO_NAME:cloudtools $REPO_NAMESPACE
EOF

    "$script_dir/exec-com.sh" sh -c "$all_commands"
}

main "$@"
