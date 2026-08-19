#!/bin/sh
# smoke.sh — geist-diktat smoke test.
#
# Always: the binary must exist and refuse a missing model cleanly.
# With fixtures (after `make setup`): a piped synthetic clip must run the
# full audio path and exit 0. Without fixtures the second half SKIPs —
# same convention as geistlib's model-gated suites.
set -e
cd "$(dirname "$0")/.."

MODEL=geistlib/gguf_artifacts/gemma4-e2b-Q4_K_M.gguf

test -x ./diktat || { echo "FAIL: ./diktat not built"; exit 1; }

# 1. Missing model → clean error, no crash.
if ./diktat /nonexistent/model.gguf </dev/null 2>/tmp/geist_diktat_err.txt; then
    echo "FAIL: missing model not refused"
    exit 1
fi
grep -q "model_load failed" /tmp/geist_diktat_err.txt || {
    echo "FAIL: unexpected error output:"
    cat /tmp/geist_diktat_err.txt
    exit 1
}
echo "ok: missing model refused cleanly"

# 2. Full-path smoke (fixture-gated).
if [ ! -f "$MODEL" ]; then
    echo "SKIP: model not fetched (make setup) — full-path smoke skipped"
    exit 0
fi
python3 geistlib/tools/gen_test_wav.py /tmp/geist_diktat_smoke.wav 2
export GEIST_AUDIO_MODEL_PATH=geistlib/audio_bench/audio_tower.safetensors
export GEIST_MEL_CONSTANTS_PATH=geistlib/audio_test_data/mel_constants.bin
(
    tail -c +45 /tmp/geist_diktat_smoke.wav
    dd if=/dev/zero bs=32000 count=1 2>/dev/null
) | ./diktat "$MODEL" >/tmp/geist_diktat_out.txt 2>/dev/null
echo "ok: full audio path ran (output: $(head -c 80 /tmp/geist_diktat_out.txt))"
echo "PASS"
