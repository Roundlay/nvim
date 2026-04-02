#!/usr/bin/env bash

set -euo pipefail

ROOT="/mnt/c/Users/Christopher/AppData/Local/nvim"
SCRIPT="$ROOT/bin/tmux-paste-windows-clipboard"

assert_hex() {
    local name="$1"
    local input="$2"
    local expected="$3"
    local actual

    actual="$(printf '%b' "$input" | "$SCRIPT" normalize | od -An -tx1 -v | tr -d ' \n')"
    if [[ "$actual" != "$expected" ]]; then
        printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' "$name" "$expected" "$actual" >&2
        exit 1
    fi
}

assert_hex "crlf_to_lf" 'a\r\nb\r\n' '610a620a'
assert_hex "lone_cr_to_lf" 'a\rb' '610a62'
assert_hex "tabs_and_spaces_preserved" '\t  indented\r\nnext\tline\r' '092020696e64656e7465640a6e657874096c696e650a'

printf 'tmux_paste_windows_clipboard_spec: ok\n'
