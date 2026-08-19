#!/bin/sh
# nvim_smoke.sh — the plugin must insert piped transcript lines at the
# cursor and stop cleanly. dictate is stubbed (printf); no model needed.
set -e
cd "$(dirname "$0")/.."

command -v nvim >/dev/null || { echo "SKIP: nvim not installed"; exit 0; }

nvim --headless -u NONE \
    +"set rtp+=$(pwd)" \
    +"lua require('geist-dictate').setup({ cmd = [[printf 'hello world\n']] })" \
    +"lua require('geist-dictate').start()" \
    +"lua assert(vim.wait(3000, function() return (table.concat(vim.api.nvim_buf_get_lines(0,0,-1,false),' ')):match('hello world') ~= nil end), 'transcript not inserted')" \
    +"lua require('geist-dictate').stop()" \
    +"lua assert(not require('geist-dictate').is_active(), 'job not stopped')" \
    +"qa!" 2>/dev/null
echo "PASS: nvim plugin inserts transcripts and stops cleanly"
