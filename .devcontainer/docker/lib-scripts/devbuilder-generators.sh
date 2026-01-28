#!/bin/sh

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

touch "$PIPX" \
    && chmod +x "$PIPX" \
    && cat > "$PIPX" << EOF
#!/bin/sh

# Get the path to pipx binary

if type pipx >/dev/null 2>&1; then
  _pipx="\$(which pipx)"
elif type "\$(dirname "$BREW")/pipx" >/dev/null 2>&1; then
  _pipx="\$(dirname "$BREW")/pipx"
else
  _pipx=""
fi

if [ -z "\$_pipx" ]; then
  echo "pipx not found" >&2
  exit 1
fi

if [ "\$#" -gt 0 ]; then
  "\$_pipx" "\$@"
else
  printf "%s\n" "\$_pipx"
fi
EOF
