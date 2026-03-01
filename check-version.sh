#!/bin/sh
#
# check-version.sh - Show current Ptyxis version and upstream tag page
#
# Usage: ./check-version.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT_DIR="$SCRIPT_DIR/openbsd-port"
GITLAB_TAGS_URL="https://gitlab.gnome.org/chergert/ptyxis/-/tags"

get_version() {
    grep "^V =" "$PORT_DIR/Makefile" | awk '{print $3}'
}

CURRENT_VERSION="$(get_version)"
MAKEFILE="$PORT_DIR/Makefile"

# stat(1) format differs between GNU (Linux) and BSD
MAKEFILE_DATE="$(stat -c '%y' "$MAKEFILE" 2>/dev/null \
             || stat -f '%Sm' "$MAKEFILE" 2>/dev/null \
             || echo "(unknown)")"

printf 'Current version : %s\n' "$CURRENT_VERSION"
printf 'Makefile updated: %s\n' "$MAKEFILE_DATE"
printf '\n'
printf 'Upstream tags   : %s\n' "$GITLAB_TAGS_URL"
printf '\n'
printf 'Next steps:\n'
printf '  1. Open the URL above and check for a newer stable tag.\n'
printf '  2. If a new version is available:\n'
printf '       ./build-ptyxis.sh <new-version>\n'
printf '  3. If already up to date, update the version check date in CLAUDE.md.\n'
