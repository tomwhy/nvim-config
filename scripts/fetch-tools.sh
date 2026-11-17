#!/usr/bin/env bash
# Download the latest prebuilt x86_64 Linux releases of the programs the config
# needs at runtime (nvim, fzf, rg, fd, ast-grep) and pack them, together with
# scripts/install-tools.sh, into one tarball to carry to the offline machine.
#
# Usage: scripts/fetch-tools.sh [output.tar]   (default: ./nvim-tools.tar)
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
out=$(realpath "${1:-nvim-tools.tar}")

for cmd in curl tar gzip; do
	command -v "$cmd" >/dev/null || { echo "error: $cmd is required" >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage=$work/nvim-tools
mkdir -p "$stage/bin" "$work/dl"

# latest_asset <owner/repo> <asset name regex>: prints "<tag> <download url>"
latest_asset() {
	local json tag url
	json=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")
	tag=$(grep -oE '"tag_name": *"[^"]*"' <<<"$json" | head -1 | cut -d'"' -f4)
	url=$(grep -oE '"browser_download_url": *"[^"]*"' <<<"$json" | cut -d'"' -f4 |
		grep -E "/$2\$" | head -1)
	if [[ -z $tag || -z $url ]]; then
		echo "error: no asset matching '$2' in the latest $1 release" >&2
		return 1
	fi
	echo "$tag $url"
}

# fetch <name> <owner/repo> <asset regex>: downloads into $work/dl, records the version,
# and sets $file to the downloaded path
fetch() {
	local name=$1 tag url
	read -r tag url < <(latest_asset "$2" "$3")
	echo "==> $name $tag"
	file=$work/dl/$(basename "$url")
	curl -fL --progress-bar -o "$file" "$url"
	printf '%-10s %s\n' "$name" "$tag" >>"$stage/VERSIONS"
}

# install the first file named <binary> found in the extracted archive into bin/
take() {
	local found
	found=$(find "$work/x" -type f -name "$1" | head -1)
	[[ -n $found ]] || { echo "error: $1 not found in archive" >&2; exit 1; }
	install -m 755 "$found" "$stage/bin/$1"
	rm -rf "$work/x"
}
extract() { mkdir -p "$work/x" && tar -C "$work/x" -xzf "$file"; }

fetch nvim neovim/neovim 'nvim-linux-x86_64\.tar\.gz'
tar -C "$stage" -xzf "$file"

fetch fzf junegunn/fzf 'fzf-[0-9.]+-linux_amd64\.tar\.gz'
extract && take fzf

# nvim (and ast-grep below) need glibc >= 2.34. These musl builds are static and run anywhere.
fetch ripgrep BurntSushi/ripgrep 'ripgrep-[0-9.]+-x86_64-unknown-linux-musl\.tar\.gz'
extract && take rg

fetch fd sharkdp/fd 'fd-v[0-9.]+-x86_64-unknown-linux-musl\.tar\.gz'
extract && take fd

if command -v unzip >/dev/null; then
	# ast-grep's musl build is dynamically linked against musl, so use the glibc one.
	fetch ast-grep ast-grep/ast-grep 'app-x86_64-unknown-linux-gnu\.zip'
	# The zip also holds `sg`, an alias that clashes with shadow-utils' sg; leave it out.
	mkdir -p "$work/x" && unzip -q "$file" -d "$work/x" && take ast-grep
else
	echo "warning: unzip not found, skipping ast-grep (optional)" >&2
fi

install -m 755 "$script_dir/install-tools.sh" "$stage/install.sh"

echo "==> Packing -> $out"
tar -C "$work" -cf "$out" nvim-tools
echo
cat "$stage/VERSIONS"
