#!/usr/bin/env bash
# shellcheck disable=SC1091

__load_env() {
    local env_file="${1}"

    if [ -f "${env_file}" ] && [ -r "${env_file}" ]; then
        set -a
        # shellcheck disable=SC1090
        . "${env_file}"
        set +a
        echo "(*) Loaded environment variables from '${env_file}'" >&2
    else
        echo "(!) Warning: Environment file '${env_file}' not found or not readable." >&2
    fi
}

# * Helper function to deduplicate comma-separated strings and sort results
# Behavior:
# - If arr_name is provided, sets the variable with that name to the deduplicated array
# - If arr_name is not provided, echoes the deduplicated comma-separated string
# Usage: dedupe [sort] str [arr_name]
# Args:
#   str: Comma-separated string to deduplicate
#   arr_name: (Optional) Name of the variable to set with the deduplicated array
# Example:
#   result_str=$(dedupe false "c,a,b,a,b")
#   dedupe "c,a,b,a,b" my_array
# ! Caution: Uses eval to set variable by name for bash 3 compatibility
dedupe() {
    local str arr_name sort=true
    if [ "$1" = "true" ] || [ "$1" = "false" ]; then
        sort="$1"
        shift
    fi
    str="${1}"
    arr_name="${2-}"
    local -a temp_arr
    [ -n "$str" ] || return $?
    # Parse str into an array
    IFS="," read -r -a temp_arr <<< "$str"
    # Remove duplicate entries from the array
    if [ "$sort" != "true" ]; then
        # Use `awk '!seen[$0]++'` to filter for unique entries while preserving the original order
        read -r -a temp_arr <<< "$(printf '%s\n' "${temp_arr[@]}" | awk '!seen[$0]++' | xargs echo)"
    else
        # Sort and deduplicate
        read -r -a temp_arr <<< "$(printf '%s\n' "${temp_arr[@]}" | sort -u | xargs echo)"
    fi
    if [ -n "$arr_name" ]; then
        eval "$arr_name"="($(printf '%q ' "${temp_arr[@]}"))"
    else
        # Return comma-separated string
        local IFS=","
        echo "${temp_arr[*]}"
    fi
}

load_env() {
    # Declare script path variables in local scope since this is called from other scripts
    # ---------------------------------------
    if [ -z "$0" ]; then
        echo "(!) Cannot determine script path" >&2
        exit 1
    fi

    local script_name="$0"
    local script_dir
    script_dir="$(cd "$(dirname "$script_name")" && pwd)"
    # ---------------------------------------

    local default_env_file="${script_dir}/../.env"
    local from_script="${1:-false}"

    if [ -d "${1-}" ]; then
        echo "(+) Found .env file in directory '${1}'" >&2
        env_file="${1}/.env"
    else
        echo "(+) Using default .env file path '${default_env_file}'" >&2
        if [ "$from_script" = "true" ]; then
            env_file="$default_env_file"
        fi
    fi

    __load_env "$env_file"
}

load_env "$@"
