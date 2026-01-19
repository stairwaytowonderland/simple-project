#!/usr/bin/env bash
# shellcheck disable=SC1091

# ./.devcontainer/docker/bin/clean.sh

# ---------------------------------------
set -euo pipefail

if [ -z "$0" ]; then
    echo "Cannot determine script path"
    exit 1
fi

script_name="$0"
script_dir="$(cd "$(dirname "$script_name")" && pwd)"
# ---------------------------------------

simple_cleanup() {
    echo "Performing simple Docker cleanup..."

    # Remove dangling images
    (
        set -x
        docker rmi "$(docker image ls -f dangling=true -q)"
    ) || true

    # Remove stopped containers
    (
        set -x
        docker rm "$(docker ps -a -f status=exited -q)"
    ) || true

    # Remove unused volumes
    (
        set -x
        docker volume rm "$(docker volume ls -f dangling=true -q)"
    ) || true
}

system_cleanup() {
    echo "Cleaning up Docker system (this may take a while)..."

    # Deep clean docker system (use with caution)
    com=(docker system)
    com+=(prune)
    com+=(-a)
    com+=(--volumes)
    com+=("$@")

    set -- "${com[@]}"
    . "$script_dir/exec-com.sh" "$@"
}

clean() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --full)
                shift
                echo "Args remaining for full cleanup: $*"
                if [ "$#" -gt 0 ] && [ "$1" = "--" ]; then
                    shift
                fi
                system_cleanup "$@"
                break
                ;;
            --*)
                shift
                simple_cleanup
                break
                ;;
            *)
                echo "Unknown optionx: $1"
                exit 1
                ;;
        esac
    done
}

[ "$#" -gt 0 ] || set -- --simple

clean "$@"

echo "Done! Docker cleanup complete."
