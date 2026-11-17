#!/usr/bin/env bash
# Install the programs packed by scripts/fetch-tools.sh. Run it from the extracted
# nvim-tools/ directory (it's copied there as install.sh). No network needed.
#
# Usage: ./install.sh [prefix]   (default: ~/.local; use sudo for e.g. /usr/local)
#   nvim  -> <prefix>/lib/nvim-linux-x86_64, linked from <prefix>/bin/nvim
#   rest  -> <prefix>/bin
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
prefix=$(realpath -m "${1:-$HOME/.local}")

mkdir -p "$prefix/bin" "$prefix/lib"
if [[ ! -w $prefix/bin || ! -w $prefix/lib ]]; then
	echo "error: can't write to $prefix (try sudo, or a prefix you own)" >&2
	exit 1
fi

if [[ -d $src/nvim-linux-x86_64 ]]; then
	echo "==> nvim -> $prefix/lib/nvim-linux-x86_64"
	rm -rf "$prefix/lib/nvim-linux-x86_64"
	cp -r "$src/nvim-linux-x86_64" "$prefix/lib/"
	ln -sfn "$prefix/lib/nvim-linux-x86_64/bin/nvim" "$prefix/bin/nvim"
fi

for f in "$src"/bin/*; do
	echo "==> $(basename "$f") -> $prefix/bin"
	install -m 755 "$f" "$prefix/bin/"
done

# Warn about older copies that would still win in PATH (e.g. from apt in /usr/bin).
hash -r
shadowed=0
for f in "$prefix/bin/nvim" "$src"/bin/*; do
	name=$(basename "$f")
	active=$(command -v "$name" || true)
	if [[ $active != "$prefix/bin/$name" ]]; then
		echo "warning: '$name' resolves to ${active:-nothing}, not $prefix/bin/$name" >&2
		shadowed=1
	fi
done
if ((shadowed)); then
	echo "         Put $prefix/bin first in PATH, e.g. add to ~/.bashrc:" >&2
	echo "           export PATH=\"$prefix/bin:\$PATH\"" >&2
	echo "         or remove the older copies (sudo apt remove neovim fzf ripgrep fd-find)." >&2
fi

echo
echo "Installed:"
cat "$src/VERSIONS"
