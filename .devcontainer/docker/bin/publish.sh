#!/usr/bin/env bash
# shellcheck disable=SC1091

# ./.devcontainer/docker/bin/publish.sh \
#   stairwaytowonderland

echo "(ƒ) Preparing for Docker image publish (push)..." >&2

# ---------------------------------------
set -euo pipefail

if [ -z "$0" ]; then
    echo "(!) Cannot determine script path" >&2
    exit 1
fi

script_name="$0"
script_dir="$(cd "$(dirname "$script_name")" && pwd)"
# ---------------------------------------

# Parse first argument as IMAGE_NAME, second as GITHUB_USER, third as IMAGE_VERSION
first_arg="${1-}"
[ -z "$first_arg" ] || shift

. "$script_dir/load-env.sh" "$script_dir/.."

# ---------------------------------------

LATEST_TARGET="${LATEST_TARGET:-base}"

BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-ubuntu}"
BASE_IMAGE_VARIANT="${BASE_IMAGE_VARIANT:-latest}"

GITHUB_TOKEN="${GITHUB_TOKEN-}"
GH_TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
GITHUB_PAT="${GITHUB_PAT:-$GH_TOKEN}"
CR_PAT="${CR_PAT:-$GITHUB_PAT}"
REPO_NAMESPACE="${REPO_NAMESPACE-}"
REPO_NAME="${REPO_NAME-}"

# Determine IMAGE_NAME
IMAGE_NAME=${first_arg:-$REPO_NAME}
if [ -z "$IMAGE_NAME" ]; then
    echo "Usage: $0 <image-name[:build_target]> [github-username] [image-version]" >&2
    exit 1
fi
if [ -n "${IMAGE_NAME##*:}" ] && [ "${IMAGE_NAME##*:}" != "$IMAGE_NAME" ]; then
    DOCKER_TARGET="${IMAGE_NAME##*:}"
    IMAGE_NAME="${IMAGE_NAME%%:*}"
fi
DOCKER_TARGET=${DOCKER_TARGET:-"base"}
# Determine GITHUB_USER
if [ $# -gt 0 ]; then
    GITHUB_USER="${1:-$REPO_NAMESPACE}"
    shift
fi
if [ -z "${GITHUB_USER-}" ]; then
    echo "(!) Please provide your GitHub username as the first argument or set the REPO_NAMESPACE environment variable." >&2
    exit 1
fi
# Determine IMAGE_VERSION
if [ $# -gt 0 ]; then
    IMAGE_VERSION="${1-}"
    shift
fi
IMAGE_VERSION="${IMAGE_VERSION:-latest}"

tag_suffix="${BASE_IMAGE_VARIANT}"
# Append image version if not 'latest'
[ "$IMAGE_VERSION" = "latest" ] || tag_suffix="${tag_suffix}-${IMAGE_VERSION}"

if [ "$DOCKER_TARGET" = "filez" ]; then
    build_tag="$DOCKER_TARGET"
    docker_tag="${IMAGE_NAME}:${DOCKER_TARGET}"
else
    tag_prefix="${IMAGE_NAME}:${DOCKER_TARGET}"
    # Append base image name if variant is 'latest'
    [ "$BASE_IMAGE_VARIANT" != "latest" ] || tag_prefix="${tag_prefix}-${BASE_IMAGE_NAME}"

    build_tag="${tag_prefix}-${BASE_IMAGE_VARIANT}"
    docker_tag="${tag_prefix}-${tag_suffix}"
fi

registry_url="ghcr.io/${GITHUB_USER}/${docker_tag}"

tag_image() {
    local source_image="$1"
    local target_image="$2"

    echo "(*) Tagging Docker image '${source_image}' as '${target_image}'..." >&2
    (
        set -x
        docker tag "$source_image" "$target_image"
    )
}

remove_danglers() {
    echo "(*) Removing dangling Docker images..." >&2
    (
        set -x
        docker images --filter label="org.opencontainers.image.build_tag=${1}" --filter dangling=true -q | xargs -r docker rmi
    )
}

# Tag the image for GitHub Container Registry
echo "(*) Tagging Docker image for GitHub Container Registry..." >&2
# (set -x; docker tag "$build_tag" "$docker_tag")
tag_image "$build_tag" "$registry_url"

echo "(*) Logging in to GitHub Container Registry..." >&2
echo "$CR_PAT" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

echo "(*) Publishing Docker image to GitHub Container Registry..." >&2
com=(docker push)
com+=("$registry_url")

set -- "${com[@]}"
. "$script_dir/exec-com.sh" "$@"

if [ "$DOCKER_TARGET" = "$LATEST_TARGET" ] && [ "${LATEST:-false}" = "true" ]; then
    latest_tag="${IMAGE_NAME}:latest"
    registry_url="ghcr.io/${GITHUB_USER}/${latest_tag}"

    echo "(*) Tagging Docker image with 'latest' tag for GitHub Container Registry..." >&2
    tag_image "$build_tag" "$registry_url"

    com=(docker push)
    com+=("$registry_url")

    set -- "${com[@]}"
    . "$script_dir/exec-com.sh" "$@"
fi

remove_danglers "$build_tag"

IFS="," read -r -a platforms <<< "${PLATFORM:-linux/$(uname -m)}"
image_description="A simple Debian-based Docker image with essential development tools and Homebrew."
image_title="$REPO_NAME - $DOCKER_TARGET - $BASE_IMAGE_NAME - $BASE_IMAGE_VARIANT"
repo_source="https://github.com/${REPO_NAMESPACE}/${REPO_NAME}"

description_suffix=""
title_suffix=""
annotation_prefix="index:"
if [ ${#platforms[*]} -gt 1 ]; then
    annotation_prefix="index:"
    # if echo "${platforms[*]}" | grep -q "linux/amd64"; then
    #     annotation_prefix="manifest[linux/amd64]:"
    #     description_suffix=" -- for AMD64."
    #     title_suffix=" - AMD64"
    # elif echo "${platforms[*]}" | grep -q "linux/arm64"; then
    #     annotation_prefix="manifest[linux/arm64]:"
    #     description_suffix=" -- for ARM64."
    #     title_suffix=" - ARM64"
    # fi
fi

annotation_com=(docker buildx imagetools create)
annotation_com+=("-t" "${registry_url}")  # * In a more production-like environment, use temporary tags up until this point, then retag to final name here
annotation_com+=("--annotation" "${annotation_prefix}org.opencontainers.image.description=${image_description%.}${description_suffix%.}.")
annotation_com+=("--annotation" "${annotation_prefix}org.opencontainers.image.title=${image_title%.}${title_suffix}.")
annotation_com+=("--annotation" "${annotation_prefix}org.opencontainers.image.ref.name=${build_tag}")
annotation_com+=("--annotation" "${annotation_prefix}org.opencontainers.image.source=${repo_source}")
annotation_com+=("--annotation" "${annotation_prefix}org.opencontainers.image.licenses=MIT")
annotation_com+=("$registry_url")

echo "(*) Adding annotations to ${registry_url} ..." >&2

set -- "${annotation_com[@]}"
. "$script_dir/exec-com.sh" "$@"

# Pull the manifest to ensure local availability
# echo "Pulling the published Docker image manifest to ensure local availability..."
# pull_com=(docker pull)
# pull_com+=("$registry_url")

# set -- "${pull_com[@]}"
# . "$script_dir/exec-com.sh" "$@"

echo "(√) Done! Docker image publishing complete." >&2
echo "_______________________________________" >&2
echo >&2
