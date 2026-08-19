#!/bin/sh
# ibus_smoke.sh — headless IBus integration test (#3).
#
# Under a private D-Bus session: ibus-daemon + the engine (standalone
# self-registration, pipeline stubbed) + the test client. The stubbed
# transcript must arrive as a committed text at the client. SKIPs when
# the ibus toolchain is absent (macOS, minimal containers).
set -e
cd "$(dirname "$0")/.."

command -v ibus-daemon >/dev/null || { echo "SKIP: ibus-daemon not installed"; exit 0; }
command -v dbus-run-session >/dev/null || { echo "SKIP: dbus-run-session not installed"; exit 0; }
test -x ./ibus-engine-geist-diktat || { echo "SKIP: engine not built (make ibus)"; exit 0; }

dbus-run-session -- sh -ec '
    ibus-daemon --panel disable --daemonize
    for i in $(seq 20); do ibus list-engine >/dev/null 2>&1 && break; sleep 0.5; done

    GEIST_DIKTAT_CMD="printf \"hallo welt\n\"; sleep 30" ./ibus-engine-geist-diktat &
    ENGINE_PID=$!
    for i in $(seq 20); do ibus list-engine 2>/dev/null | grep -q geist-diktat && break; sleep 0.5; done
    ibus list-engine | grep -q geist-diktat || { echo "FAIL: engine not registered"; exit 1; }
    echo "ok: engine registered"

    OUT=$(./ibus-test-client)
    echo "committed: $OUT"
    echo "$OUT" | grep -q "hallo welt" || { echo "FAIL: commit mismatch"; exit 1; }

    kill $ENGINE_PID 2>/dev/null || true
    # The stubbed pipeline (sleep 30) must not outlive the engine.
    sleep 1
    if pgrep -f "sleep 30" >/dev/null; then echo "FAIL: pipeline outlived engine"; exit 1; fi
    echo PASS
'
