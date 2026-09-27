#!/usr/bin/env bash
# Report which external programs the config's plugins need, and which are
# missing or too old on this machine. Run it on the machine you use Neovim on.
#
# Usage: scripts/check-deps.sh            runtime dependencies
#        scripts/check-deps.sh --update   tools scripts/update.sh needs
# Exits 1 if anything required is missing or too old.
set -uo pipefail

if [[ -t 1 ]]; then
	green=$'\e[32m' yellow=$'\e[33m' red=$'\e[31m' dim=$'\e[2m' bold=$'\e[1m' reset=$'\e[0m'
else
	green="" yellow="" red="" dim="" bold="" reset=""
fi

required_missing=0
optional_missing=0

version_of() { timeout 5 "$1" --version 2>&1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1; }
# version_ge A B: true if A >= B
version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

section() { printf '\n%s%s%s\n' "$bold" "$1" "$reset"; }

# check <required|optional> <min version|-> <recommended version|-> <used for> <cmd> [alt cmd...]
check() {
	local level=$1 min=$2 rec=$3 purpose=$4
	shift 4
	local name found="" cmd
	name=$(IFS='|'; echo "$*")
	for cmd in "$@"; do
		if command -v "$cmd" >/dev/null 2>&1; then found=$cmd; break; fi
	done

	local mark color detail
	if [[ -z $found ]]; then
		if [[ $level == required ]]; then
			mark="✗" color=$red; ((required_missing++))
		else
			mark="-" color=$yellow; ((optional_missing++))
		fi
		detail="missing"
		[[ $min != - ]] && detail+=" (need >= $min)"
	else
		mark="✓" color=$green detail=$(command -v "$found")
		if [[ $min != - || $rec != - ]]; then
			local ver
			ver=$(version_of "$found")
			detail="${ver:-?}  $detail"
			if [[ -z $ver && $min != - ]]; then
				mark="✗" color=$red detail="found, but '$found --version' failed (broken install?)  $(command -v "$found")"
				if [[ $level == required ]]; then ((required_missing++)); else ((optional_missing++)); fi
			elif [[ $min != - ]] && ! version_ge "$ver" "$min"; then
				mark="✗" color=$red detail="${ver:-?} is too old (need >= $min)"
				if [[ $level == required ]]; then ((required_missing++)); else ((optional_missing++)); fi
			elif [[ $rec != - ]] && ! version_ge "${ver:-0}" "$rec"; then
				mark="!" color=$yellow detail+="  (>= $rec recommended)"
			fi
		fi
	fi
	printf '  %s%s%s %-34s %s\n      %s%s%s\n' "$color" "$mark" "$reset" "$name" "$detail" "$dim" "$purpose" "$reset"
}

if [[ ${1:-} == --update ]]; then
	section "Needed by scripts/update.sh"
	check required 0.12.0 - "runs lazy.nvim / nvim-treesitter headless"  nvim
	check required -      - "plugin updates (lazy.nvim)"                   git
	check required -      - "downloads (blink.cmp binary, parser sources)" curl
	check required 0.26.1 - "compiling Treesitter parsers"                 tree-sitter
	check required -      - "compiling Treesitter parsers"                 cc gcc clang
else
	section "Required"
	check required 0.12.0 - "everything (nvim-treesitter main needs 0.12)"          nvim
	check required -      - "gitsigns, lazy.nvim"                                    git
	check required 0.37   0.53 "fzf-lua: every picker (<C-o>, <leader>f..., code actions)" fzf
	check required 14     15 "live grep (<leader>ff, <leader>/), grug-far, TODO search" rg

	section "Optional tools"
	check optional -    - "fzf-lua file finder (falls back to rg/find)"    fd fdfind
	check optional -    - "generating tags for <leader>fts / <leader>ftr" ctags
	check optional -    - "<leader>fm man page picker, man hover"        man
	check optional 0.36 - "grug-far ast-grep engine (<localleader>e)"    ast-grep
	check optional -    - "<leader>k formatting for C/C++"               clang-format-20 clang-format
	check optional -    - "oil gx (open file externally)"                xdg-open open

	section "Language servers (only needed for the languages you edit)"
	check optional - - "C/C++ (clangd)"                             clangd
	check optional - - "Python (pylsp)"                             pylsp
	check optional - - "Go (gopls)"                                 gopls
	check optional - - "gopls: locating GOROOT / module cache"      go
	check optional - - "JS/TS (ts_ls)"                              typescript-language-server
	check optional - - "Rust (rust-analyzer)"                       rust-analyzer
	check optional - - "rust-analyzer: finding the workspace root"  cargo
fi

echo
if ((required_missing > 0)); then
	printf '%s%d required missing/too old%s, %d optional missing\n' "$red" "$required_missing" "$reset" "$optional_missing"
	exit 1
fi
printf '%sAll required dependencies found%s, %d optional missing\n' "$green" "$reset" "$optional_missing"
