#!/usr/bin/env bash

touch "$LOGGER" \
    && chmod +x "$LOGGER" \
    && cat > "$LOGGER" << EOF
#!/bin/sh

# Simple logger script

# Usage: [LEVEL=<level>] $LOGGER <message>
#
# Arguments:
#   message: Message to log
#
# Output:
#   Logs message with timestamp and log level (default: info)

LEVEL="\${LEVEL:-info}"

log() {
  local timestamp="\$(date +'%Y-%m-%d %H:%M:%S')"
  printf "[%s] [%s] %s\n" "\$timestamp" "\$(echo \$LEVEL | tr '[:lower:]' '[:upper:]')" "\$*" >&2
}

main() {
  if [ "\$#" -lt 1 ] ; then
    LEVEL=error log "Usage: [LEVEL=<level>] $LOGGER <message>"
    exit 1
  fi
  # Log the message
  log "\$@"
}

main "\$@"
EOF

touch "$PASSGEN" \
    && chmod +x "$PASSGEN" \
    && cat > "$PASSGEN" << EOF
#!/bin/sh

# Generate a random $DEFAULT_PASS_LENGTH-character (unless specified) alphanumeric password

# Usage: $PASSGEN [length] [charset]
#
# Arguments:
#   length: Length of password to generate (default: $DEFAULT_PASS_LENGTH)
#   charset: Characters to use for password generation (default: $DEFAULT_PASS_CHARSET)
#
# Output:
#   Randomly generated password

LC_ALL=C tr -dc "${2:-$DEFAULT_PASS_CHARSET}" < /dev/urandom | head -c${1:-$DEFAULT_PASS_LENGTH}
EOF

touch "$FIXPATH" \
    && chmod +x "$FIXPATH" \
    && cat > "$FIXPATH" << EOF
#!/bin/sh

set -eu

# Fix PATH to use the PATH variable from /etc/environment

# Usage: $FIXPATH [term]
#
# Arguments:
#   term: Term to search for in PATH (default: /usr/local/sbin)
#        Expected to be the first common entry in the
#        /etc/environment PATH and exported PATH. Typically
#        the first entry in PATH, and usually /usr/local/sbin
#        for Debian-based systems.
#
# Output:
#   Fixed PATH string

term=\${1:-/usr/local/sbin}
search=\$(echo "\$PATH" | awk -F"\${term}:" '{print \$2}')
replace=\$(sed -nE '1s|^PATH=\"(.*)\"|\1|p' /etc/environment 2>/dev/null)

if ! echo "\$PATH" | grep -q "\$replace" ; then
  replaced=\$(echo "\$PATH" | sed "s|\$search|\$replace|g" 2>/dev/null)
  PATH=\$(echo "\$replaced" | sed "s|\${term}:||" 2>/dev/null)
fi

# Remove duplicate entries from PATH
# https://unix.stackexchange.com/questions/40749/remove-duplicate-path-entries-with-awk-command
__path=\$PATH:
PATH=
while [ -n "\$__path" ]; do
  x=\${__path%%:*}          # Extract the first entry
  case \$PATH: in
    *:"\$x":*) ;;           # If already in PATH, do nothing
    *) PATH=\$PATH:\$x;;    # Otherwise, append it
  esac
  __path=\${__path#*:}      # Remove the first entry from the list
done
PATH=\${PATH#:}             # Remove the leading colon

printf "%s" "\$PATH"
EOF

touch "/docker-entrypoint.sh" \
    && chmod +x /docker-entrypoint.sh \
    && cat > "/docker-entrypoint.sh" << EOF
#!/bin/sh

set -e

if [ "\$RESET_ROOT_PASS" = "true" ] ; then
  printf "\033[1m%s\033[0m\n" "Updating root password ..."
  sudo passwd root
fi

if type /usr/games/fortune >/dev/null 2>&1 \
  && type /usr/games/cowsay >/dev/null 2>&1
then
  /usr/games/fortune | /usr/games/cowsay
fi

exec "\$@"
EOF
