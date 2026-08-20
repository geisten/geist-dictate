#!/bin/sh
# build-tarball.sh — static tarball for non-Debian distros.
#
#   make CC=gcc-14 TARGET=linux GEMM_PROVIDER=native
#   sh packaging/build-tarball.sh    # -> geist-diktat_<v>_linux-<arch>.tar.gz
#
# The layout mirrors the installed /usr prefix (bin/, share/geist-diktat/),
# and the wrapper derives its prefix from its own location — the same
# file works installed and unpacked, no patching:
#   tar xf geist-diktat_*.tar.gz && geist-diktat_*/bin/geist-diktat setup
set -e
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
ARCH="$(uname -m)"
NAME="geist-diktat_${VERSION}_linux-${ARCH}"
STAGE="build/$NAME"

test -x ./diktat || { echo "build ./diktat first (make)" >&2; exit 1; }

rm -rf "$STAGE"
mkdir -p "$STAGE/bin" "$STAGE/share/geist-diktat"
install -m755 diktat "$STAGE/bin/diktat"
strip "$STAGE/bin/diktat" 2>/dev/null || true
install -m755 packaging/geist-diktat "$STAGE/bin/geist-diktat"
install -m644 geistlib/audio_test_data/mel_constants.bin "$STAGE/share/geist-diktat/"
install -m755 geistlib/tools/fetch_audio_tower.py "$STAGE/share/geist-diktat/"
install -m644 README.md LICENSE "$STAGE/"

tar -C build -czf "$NAME.tar.gz" "$NAME"
echo "built: $NAME.tar.gz"
