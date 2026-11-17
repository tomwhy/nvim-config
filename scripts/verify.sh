#!/usr/bin/env bash
# Check that a config directory, or a tarball made by scripts/update.sh, works
# as the offline machine will use it: no network, no data/state/cache from an
# earlier run, and (for a tarball) extracted somewhere other than where it was
# built. Starts nvim headless and runs scripts/verify.lua against it: startup
# errors, every plugin installed at its lazy-lock.json commit and loadable,
# every Treesitter parser present with queries, blink.cmp's binary.
#
# Usage: scripts/verify.sh <config-dir | config.tar>
# Exits 1 if any check fails.
set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "usage: $0 <config-dir | config.tar>" >&2
	exit 2
fi
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
target=$(realpath "$1")

scratch=$(mktemp -d "${TMPDIR:-/tmp}/nvim-verify.XXXXXX")
trap 'rm -rf "$scratch"' EXIT

if [[ -d $target ]]; then
	config_dir=$target
else
	mkdir "$scratch/extract"
	tar -C "$scratch/extract" -xf "$target"
	dirs=("$scratch"/extract/*/)
	if [[ ${#dirs[@]} -ne 1 ]]; then
		echo "error: expected one top-level directory in $target" >&2
		exit 1
	fi
	config_dir=${dirs[0]%/}
fi

broken=$(find -L "$config_dir/plugins" "$config_dir/site" -type l)
if [[ -n $broken ]]; then
	echo "  FAIL  no broken links: $broken" >&2
	exit 1
fi
echo "  ok    no broken links"

# Cut the network off when the kernel allows it without root, so anything
# that would try to download (and fail on the offline machine) fails here too.
offline=()
if unshare -rn true 2>/dev/null; then
	offline=(unshare -rn)
else
	echo "  note  can't disable the network here (unshare -rn); checking without that"
fi

XDG_CONFIG_HOME=$(dirname "$config_dir") NVIM_APPNAME=$(basename "$config_dir") \
	XDG_DATA_HOME=$scratch/data XDG_STATE_HOME=$scratch/state XDG_CACHE_HOME=$scratch/cache \
	timeout 120 "${offline[@]}" nvim --headless -i NONE +"luafile $script_dir/verify.lua"
