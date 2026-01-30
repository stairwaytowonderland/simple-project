#!/usr/bin/env bash
# shellcheck disable=SC1091

# Basic Usage:
# ./.devcontainer/docker/bin/clean.sh [--simple|--full [--force|-f]]
# Example:
# ./.devcontainer/docker/bin/clean.sh --full -f

echo "(ƒ) Preparing for Docker cleanup..." >&2

# ---------------------------------------
set -euo pipefail

if [ -z "$0" ]; then
    echo "(!) Cannot determine script path" >&2
    exit 1
fi

script_name="$0"
script_dir="$(cd "$(dirname "$script_name")" && pwd)"
# ---------------------------------------

simple_cleanup() {
    echo "(*) Performing simple Docker cleanup..." >&2

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
    echo "(*) Cleaning up Docker system (this may take a while)..." >&2

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
                echo "(!) Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

[ "$#" -gt 0 ] || set -- --simple

clean "$@"

echo "(√) Done! Docker cleanup complete." >&2
echo "_______________________________________" >&2
echo >&2
