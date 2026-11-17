#!/usr/bin/env bash
# Rebuild everything this config vendors from scratch, on a machine WITH network access:
#   1. plugins (lazy.nvim sync: install the latest version of every spec, rewrite lazy-lock.json)
#   2. blink.cmp's prebuilt fuzzy-matcher binary for the new tag
#   3. Treesitter parsers in site/ (needs the `tree-sitter` CLI and a C compiler)
# checks the result with scripts/verify.sh, then optionally packs the config
# for the offline machine (and verifies the tarball too), and reports which
# programs the plugins need at runtime (scripts/check-deps.sh).
#
# Every run starts from nothing: the config (minus plugins/, site/, .git and
# *.tar) is copied into a scratch dir and nvim runs there with empty
# data/state/cache dirs, so nothing from an earlier run or from your own
# Neovim leaks in. Only when the build passes verify.sh are plugins/, site/ and
# lazy-lock.json swapped into this directory.
#
# Usage: scripts/update.sh [output.tar]
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config_dir=$(dirname "$script_dir")
name=$(basename "$config_dir")

if ! "$script_dir/check-deps.sh" --update; then
	echo "error: install the missing tools above first" >&2
	exit 1
fi
echo

# Next to the config dir, so the final swap is a cheap same-filesystem move.
scratch=$(mktemp -d "$(dirname "$config_dir")/.$name-update.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
stage=$scratch/config/$name
mkdir -p "$stage"
tar -C "$config_dir" --exclude=./plugins --exclude=./site --exclude=./.git --exclude='./*.tar' -cf - . |
	tar -C "$stage" -xf -

export XDG_CONFIG_HOME=$scratch/config NVIM_APPNAME=$name
export XDG_DATA_HOME=$scratch/data XDG_STATE_HOME=$scratch/state XDG_CACHE_HOME=$scratch/cache

run() { nvim --headless -i NONE "$@" +qa; echo; }

echo "==> Downloading plugins"
run "+Lazy! sync"

echo "==> Fetching blink.cmp fuzzy-matcher binary"
run +"lua local done = false
	require('blink.cmp.fuzzy.download').ensure_downloaded(function(err)
		if err then io.stderr:write('blink.cmp: ' .. tostring(err) .. '\n') end
		done = true
	end)
	vim.wait(120000, function() return done end, 200)"

echo "==> Building Treesitter parsers"
run "+Lazy! build nvim-treesitter"

# nvim-treesitter links site/queries/<lang> to its own queries by absolute
# path, which here is the scratch dir. Make the links relative so they keep
# working after the move below and wherever the tarball is extracted.
while IFS= read -r link; do
	target=$(readlink "$link")
	[[ $target == "$stage"/* ]] &&
		ln -sfn "$(realpath -m --relative-to="$(dirname "$link")" "$target")" "$link"
done < <(find "$stage/site" -type l)

# nvim exits 0 even when a download fails, so check the result before
# replacing the working copy.
echo "==> Verifying the new build"
if ! "$script_dir/verify.sh" "$stage"; then
	echo "error: the new build is broken; $config_dir left unchanged" >&2
	exit 1
fi
echo

echo "==> Replacing plugins/, site/ and lazy-lock.json in $config_dir"
rm -rf "$config_dir/plugins" "$config_dir/site"
mv "$stage/plugins" "$stage/site" "$config_dir/"
cp "$stage/lazy-lock.json" "$config_dir/lazy-lock.json"

if [[ $# -ge 1 ]]; then
	out=$(realpath "$1")
	echo "==> Packing $config_dir -> $out"
	# Leave out tarballs sitting in the config dir (including earlier outputs).
	tar -C "$(dirname "$config_dir")" --exclude="$name/*.tar" -cf "$out" "$name"
	echo "==> Verifying $out"
	if ! "$script_dir/verify.sh" "$out"; then
		echo "error: $out is broken, don't copy it to the offline machine" >&2
		exit 1
	fi
	echo
fi
echo "==> Runtime dependencies on THIS machine (run scripts/check-deps.sh on the offline one too)"
"$script_dir/check-deps.sh" || true
