#!/usr/bin/env bash
# Download the latest prebuilt x86_64 Linux releases of the programs the config
# needs at runtime (nvim, fzf, rg, fd, ast-grep) and the clangd and pylsp
# language servers, and pack them, together with scripts/install-tools.sh, into
# one tarball to carry to the offline machine.
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
mkdir -p "$stage/bin" "$stage/lib" "$work/dl"

# latest_asset <owner/repo> <asset name regex>: prints "<tag> <download url>"
# (the highest version if several assets match)
latest_asset() {
	local json tag url
	json=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")
	tag=$(grep -oE '"tag_name": *"[^"]*"' <<<"$json" | head -1 | cut -d'"' -f4)
	url=$(grep -oE '"browser_download_url": *"[^"]*"' <<<"$json" | cut -d'"' -f4 |
		grep -E "/$2\$" | sort -V | tail -1)
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

# clangd needs the lib/clang/<version>/include next to its bin/, so it's kept
# whole in lib/ and linked from bin/.
if command -v unzip >/dev/null; then
	fetch clangd clangd/clangd 'clangd-linux-[0-9.]+\.zip'
	mkdir -p "$work/x" && unzip -q "$file" -d "$work/x"
	mv "$work"/x/clangd_* "$stage/lib/clangd" && rm -rf "$work/x"
	ln -s ../lib/clangd/bin/clangd "$stage/bin/clangd"
else
	echo "warning: unzip not found, skipping clangd (optional)" >&2
fi

# pylsp and its compiled dependencies only work with the Python they were
# installed for, so bring a standalone, relocatable Python along and install
# pylsp into it. bin/pylsp runs it from wherever install.sh puts it.
fetch python astral-sh/python-build-standalone \
	'cpython-3\.[0-9]+\.[0-9]+%2B[0-9]+-x86_64-unknown-linux-gnu-install_only_stripped\.tar\.gz'
tar -C "$stage/lib" -xzf "$file"
mv "$stage/lib/python" "$stage/lib/pylsp"
# The release tag is a date; record the Python version instead.
sed -i "s/^python .*/$(printf '%-10s %s' python "$("$stage/lib/pylsp/bin/python3" -c 'import platform; print(platform.python_version())')")/" "$stage/VERSIONS"
echo "==> pylsp (pip install python-lsp-server[pyflakes,pycodestyle])"
PIP_DISABLE_PIP_VERSION_CHECK=1 PIP_NO_CACHE_DIR=1 "$stage/lib/pylsp/bin/python3" -m pip install \
	--quiet --only-binary=:all: --no-warn-script-location "python-lsp-server[pyflakes,pycodestyle]"
printf '%-10s %s\n' pylsp "$("$stage/lib/pylsp/bin/python3" -m pylsp --version 2>&1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)" >>"$stage/VERSIONS"
cat >"$stage/bin/pylsp" <<'WRAPPER'
#!/bin/sh
# pylsp from the standalone Python installed by nvim-tools/install.sh
exec "$(dirname "$(readlink -f "$0")")/../lib/pylsp/bin/python3" -m pylsp "$@"
WRAPPER
chmod 755 "$stage/bin/pylsp"
# Drop the parts of Python pylsp doesn't use (Tcl/Tk, IDLE, pip, C headers).
(
	cd "$stage/lib/pylsp"
	rm -rf include share lib/tcl* lib/tk* lib/itcl* lib/libtcl* lib/libtk* \
		lib/python3.*/{idlelib,tkinter,turtledemo,ensurepip} \
		lib/python3.*/lib-dynload/_tkinter* lib/python3.*/site-packages/pip*
)

install -m 755 "$script_dir/install-tools.sh" "$stage/install.sh"

echo "==> Packing -> $out"
tar -C "$work" -cf "$out" nvim-tools
echo
cat "$stage/VERSIONS"
