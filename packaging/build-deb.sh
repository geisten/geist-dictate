#!/bin/sh
# build-deb.sh — stage and build the geist-dictate .deb with dpkg-deb.
# No debhelper: the layout is small enough to own directly (and the
# engine build already happened via the repo Makefile).
#
#   make CC=gcc-14 TARGET=linux GEMM_PROVIDER=native
#   sh packaging/build-deb.sh            # -> geist-dictate_<v>_<arch>.deb
set -e
cd "$(dirname "$0")/.."

VERSION="${VERSION:-0.1.0}"
ARCH="$(dpkg --print-architecture)"
STAGE="build/geist-dictate_${VERSION}_${ARCH}"

test -x ./dictate || { echo "build ./dictate first (make)" >&2; exit 1; }

rm -rf "$STAGE"
mkdir -p \
    "$STAGE/DEBIAN" \
    "$STAGE/usr/bin" \
    "$STAGE/usr/lib/systemd/user" \
    "$STAGE/usr/lib/udev/rules.d" \
    "$STAGE/usr/share/applications" \
    "$STAGE/usr/share/geist-dictate" \
    "$STAGE/usr/share/doc/geist-dictate"

install -m755 dictate "$STAGE/usr/bin/dictate"
strip "$STAGE/usr/bin/dictate"
install -m755 packaging/geist-dictate "$STAGE/usr/bin/geist-dictate"
install -m644 packaging/geist-dictate.service "$STAGE/usr/lib/systemd/user/"
install -m644 packaging/70-geist-dictate-uinput.rules "$STAGE/usr/lib/udev/rules.d/"
install -m644 packaging/geist-dictate.desktop "$STAGE/usr/share/applications/"
# Runtime data the wrapper needs: mel constants (checked into the engine)
# and the SHA-verifying tower fetcher.
install -m644 geistlib/audio_test_data/mel_constants.bin "$STAGE/usr/share/geist-dictate/"
install -m755 geistlib/tools/fetch_audio_tower.py "$STAGE/usr/share/geist-dictate/"
install -m644 README.md "$STAGE/usr/share/doc/geist-dictate/"

# Debian changelog (lintian: required). One generated entry — release
# history lives in git.
cat > /tmp/geist_dictate_changelog <<EOF
geist-dictate ($VERSION) unstable; urgency=low

  * See https://github.com/geisten/geist-dictate/releases

 -- germar <g.schlegel@geisten.net>  $(date -R)
EOF
gzip -9n -c /tmp/geist_dictate_changelog > "$STAGE/usr/share/doc/geist-dictate/changelog.gz"

# Debian copyright file (lintian: required).
cat > "$STAGE/usr/share/doc/geist-dictate/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: geist-dictate
Source: https://github.com/geisten/geist-dictate

Files: *
Copyright: 2026 geisten.net
License: Apache-2.0
 On Debian systems the full text of the Apache License 2.0 can be found
 in /usr/share/common-licenses/Apache-2.0.
EOF

INSTALLED_SIZE=$(du -sk "$STAGE" | cut -f1)
cat > "$STAGE/DEBIAN/control" <<EOF
Package: geist-dictate
Version: $VERSION
Architecture: $ARCH
Maintainer: germar <g.schlegel@geisten.net>
Installed-Size: $INSTALLED_SIZE
Depends: libc6, libgomp1, alsa-utils, ydotool, curl, python3
Recommends: libnotify-bin
Section: sound
Priority: optional
Homepage: https://github.com/geisten/geist-dictate
Description: system-wide local dictation (Gemma 4 audio, geist engine)
 Speech-to-text into the focused window, fully offline: a streaming
 energy VAD segments utterances, Gemma 4 E2B transcribes them (measured
 4.2% WER English / 7.1% German), ydotool types the result. One static
 binary on the geist inference engine; the model (~3.7 GB) is fetched
 per-user by 'geist-dictate setup'.
EOF

cat > "$STAGE/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger /dev/uinput 2>/dev/null || true
    echo "geist-dictate: per user, run 'geist-dictate setup' (downloads ~3.7 GB),"
    echo "and add yourself to the 'input' group for typing: sudo usermod -aG input \$USER"
fi
EOF
chmod 755 "$STAGE/DEBIAN/postinst"

cat > "$STAGE/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
# Models under ~/.local/share/geist-dictate are user data — kept on purge.
udevadm control --reload-rules 2>/dev/null || true
EOF
chmod 755 "$STAGE/DEBIAN/postrm"

dpkg-deb --root-owner-group --build "$STAGE" "geist-dictate_${VERSION}_${ARCH}.deb"
echo "built: geist-dictate_${VERSION}_${ARCH}.deb"
