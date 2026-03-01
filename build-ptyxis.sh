#!/bin/sh
#
# build-ptyxis.sh - Build and install Ptyxis on OpenBSD via direct meson build
#
# Usage:
#   ./build-ptyxis.sh                  # build current version (from Makefile)
#   ./build-ptyxis.sh 49.4             # update Makefile to 49.4 and build
#
# Environment variables (all optional):
#   OPENBSD_HOST    SSH hostname of the OpenBSD build machine (default: openbsd77)
#   REMOTE_SRCDIR   Work directory on the remote machine, relative to HOME
#                   (default: ptyxis-src)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT_DIR="$SCRIPT_DIR/openbsd-port"

OPENBSD_HOST="${OPENBSD_HOST:-openbsd77}"
REMOTE_SRCDIR="${REMOTE_SRCDIR:-ptyxis-src}"

# ---------------------------------------------------------------------------
# Log helpers (no ANSI codes - output may be piped or logged to file)
# ---------------------------------------------------------------------------
log_info()  { printf 'INFO:  %s\n' "$1"; }
log_warn()  { printf 'WARN:  %s\n' "$1"; }
log_error() { printf 'ERROR: %s\n' "$1" >&2; }

# ---------------------------------------------------------------------------
# Resolve version
# ---------------------------------------------------------------------------
get_version() {
    grep "^V =" "$PORT_DIR/Makefile" | awk '{print $3}'
}

VERSION="$(get_version)"

if [ "$#" -ge 1 ]; then
    NEW_VERSION="$1"
    log_info "Updating Makefile: $VERSION -> $NEW_VERSION"
    sed -i "s/^V =.*$/V =		$NEW_VERSION/" "$PORT_DIR/Makefile"
    VERSION="$NEW_VERSION"
fi

log_info "Version: $VERSION"

# ---------------------------------------------------------------------------
# Check SSH connectivity
# ---------------------------------------------------------------------------
log_info "Checking connection to $OPENBSD_HOST..."
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=10 "$OPENBSD_HOST" true; then
    log_error "Cannot connect to $OPENBSD_HOST."
    log_error "Verify that the host is reachable and SSH key authentication is configured."
    exit 1
fi

# ---------------------------------------------------------------------------
# Sync patches to remote
# ---------------------------------------------------------------------------
REMOTE_PATCH_DIR="$REMOTE_SRCDIR/patches"

log_info "Syncing patches to $OPENBSD_HOST:~/$REMOTE_PATCH_DIR/ ..."
ssh "$OPENBSD_HOST" "mkdir -p ~/$REMOTE_PATCH_DIR"
scp "$PORT_DIR/patches/patch-"* "$OPENBSD_HOST:~/$REMOTE_PATCH_DIR/"

# ---------------------------------------------------------------------------
# Remote build
# Variables expanded locally: $VERSION, $REMOTE_SRCDIR, $REMOTE_PATCH_DIR
# Variables expanded remotely: $HOME (via \$HOME in heredoc)
# ---------------------------------------------------------------------------
log_info "Building Ptyxis $VERSION on $OPENBSD_HOST..."

ssh "$OPENBSD_HOST" /bin/sh <<REMOTE
set -e

VERSION="$VERSION"
SRCDIR="\$HOME/$REMOTE_SRCDIR/src"
PATCHDIR="\$HOME/$REMOTE_PATCH_DIR"

# Clone or update source
if [ -d "\$SRCDIR/.git" ]; then
    printf 'INFO:  Fetching tags from upstream...\n'
    git -C "\$SRCDIR" fetch --tags
else
    printf 'INFO:  Cloning ptyxis source...\n'
    git clone https://gitlab.gnome.org/chergert/ptyxis.git "\$SRCDIR"
fi

cd "\$SRCDIR"
git checkout "\$VERSION"
git clean -fdx

# Apply OpenBSD patches
for p in "\$PATCHDIR"/patch-*; do
    printf 'INFO:  Applying %s...\n' "\$(basename "\$p")"
    patch -p0 < "\$p"
done

# Configure
rm -rf build
meson setup build \
    --prefix=/usr/local \
    --buildtype=debugoptimized \
    -Ddevelopment=false

# Compile
ninja -C build

# Install
sudo ninja -C build install

printf 'INFO:  Installation complete.\n'
REMOTE

log_info "Done. Ptyxis $VERSION is installed on $OPENBSD_HOST."
