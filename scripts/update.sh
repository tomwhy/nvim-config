#!/usr/bin/env bash
# Refresh everything this config vendors, on a machine WITH network access:
#   1. plugins (lazy.nvim sync: install missing, remove unused, update, rewrite lazy-lock.json)
#   2. blink.cmp's prebuilt fuzzy-matcher binary for the new tag
#   3. Treesitter parsers in site/ (needs the `tree-sitter` CLI and a C compiler)
# then optionally pack the config for the offline machine, and report which
# programs the plugins need at runtime (scripts/check-deps.sh).
#
# Usage: scripts/update.sh [output.tar]
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config_dir=$(dirname "$script_dir")
# Point nvim at this directory, wherever it is checked out.
export XDG_CONFIG_HOME=$(dirname "$config_dir")
export NVIM_APPNAME=$(basename "$config_dir")

if ! "$script_dir/check-deps.sh" --update; then
	echo "error: install the missing tools above first" >&2
	exit 1
fi
echo

run() { nvim --headless "$@" +qa; echo; }

echo "==> Updating plugins"
run "+Lazy! sync"

echo "==> Fetching blink.cmp fuzzy-matcher binary"
run +"lua local done = false
	require('blink.cmp.fuzzy.download').ensure_downloaded(function(err)
		if err then io.stderr:write('blink.cmp: ' .. tostring(err) .. '\n') end
		done = true
	end)
	vim.wait(120000, function() return done end, 200)"

echo "==> Installing/updating Treesitter parsers"
run "+Lazy! build nvim-treesitter"

if [[ $# -ge 1 ]]; then
	out=$(realpath "$1")
	echo "==> Packing $config_dir -> $out"
	tar -C "$XDG_CONFIG_HOME" -cf "$out" "$NVIM_APPNAME"
fi
echo "==> Runtime dependencies on THIS machine (run scripts/check-deps.sh on the offline one too)"
"$script_dir/check-deps.sh" || true
