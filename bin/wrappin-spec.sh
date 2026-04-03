#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)

nvim --headless -u "$root_dir/tests/minimal_init.lua" "+lua dofile('$root_dir/tests/wrappin_spec.lua')" +qa
printf 'wrappin-spec: ok\n'
