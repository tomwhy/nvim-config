# Neovim config

A [lazy.nvim](https://github.com/folke/lazy.nvim) configuration built to run on a machine
**without network access**. Plugins, Treesitter parsers and blink.cmp's matcher binary are
all vendored inside the config directory. You refresh them on a machine that has network,
then copy the whole directory over.

- Theme: [material.nvim](https://github.com/marko-cerovac/material.nvim) (`darker`)
- Pickers: [fzf-lua](https://github.com/ibhagwan/fzf-lua)
- Syntax: [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch)
- LSP: Neovim's built-in client with [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
  definitions; completion by [blink.cmp](https://github.com/saghen/blink.cmp)

For keys, see [KEYBINDINGS.md](KEYBINDINGS.md).

## Requirements

- **Neovim 0.12 or newer.** nvim-treesitter's `main` branch needs it.
- **x86_64 Linux with glibc.** The vendored parsers and blink.cmp binary are compiled for
  that. On anything else, run `scripts/update.sh` on a machine of the same architecture.
- External programs: `fzf`, `ripgrep`, `git`, plus optional tools and language servers.
  Run `scripts/check-deps.sh` to see exactly what's missing (see below).

## Layout

```
init.lua                 entry point: leader keys, then loads lua/config/*
lua/config/
  options.lua            editor options
  lazy.lua               lazy.nvim setup (root = plugins/, no network checks)
  lsp.lua                enabled servers, diagnostics, LSP keymaps
  keymaps.lua            global keymaps
  autocmds.lua           autocommands
lua/plugins/*.lua        plugin specs, grouped by area (ui, editor, coding, lsp, treesitter)
after/lsp/<server>.lua   per-server overrides of nvim-lspconfig's defaults
lazy-lock.json           exact plugin commits
scripts/                 update.sh, verify.sh, check-deps.sh, fetch-tools.sh, install-tools.sh
plugins/                 vendored plugins         (gitignored, created by update.sh)
site/                    compiled Treesitter parsers (gitignored, created by update.sh)
```

`plugins/` and `site/` are not in git. `lazy-lock.json` pins the plugin versions, and
`scripts/update.sh` rebuilds both directories. A fresh `git clone` therefore needs one run of
the update script before Neovim can use it. Tarballs made by the script already contain both.

## Installing on the offline machine

Copy the tarball made by `scripts/update.sh` (see below) to the machine, then:

```bash
mv ~/.config/nvim ~/.config/nvim.bak    # keep the old config until the new one works
tar -xf nvim-offline.tar -C ~/.config   # the tarball holds a single "nvim" directory
~/.config/nvim/scripts/check-deps.sh    # see which programs still need installing
```

If programs are missing or too old (the offline machine can't use `apt`), install them from
the tools tarball made by [`scripts/fetch-tools.sh`](#scriptsfetch-toolssh-programs-for-the-offline-machine-needs-network):

```bash
tar -xf nvim-tools.tar                  # creates nvim-tools/
nvim-tools/install.sh                   # installs into ~/.local (no sudo needed)
# or: sudo nvim-tools/install.sh /usr/local
```

The installer puts `nvim` in `<prefix>/lib/nvim-linux-x86_64`, links it from
`<prefix>/bin/nvim`, puts clangd and pylsp's Python in `<prefix>/lib/clangd` and
`<prefix>/lib/pylsp` with `clangd` and `pylsp` in `<prefix>/bin` pointing at them, and copies
`fzf`, `rg`, `fd` and `ast-grep` into `<prefix>/bin`. It
warns if an older copy (from `apt`, for example) still comes first in `PATH`. If so, add
`export PATH="$HOME/.local/bin:$PATH"` to `~/.bashrc` or remove the old packages. Then
open a new shell and run `check-deps.sh` again. Running the installer again upgrades the
tools in place.

Start `nvim`. Nothing is downloaded at startup.

## Scripts

Both scripts can be run from any directory. They find the config from their own location.

### `scripts/check-deps.sh`: what's missing on this machine

Lists every external program the plugins use, with a status for each:

| Mark | Meaning |
|---|---|
| `✓` | found (version shown where a minimum applies) |
| `!` | found, but older than the recommended version |
| `✗` | required and missing, too old, or broken (its `--version` fails) |
| `-` | optional and missing |

```bash
scripts/check-deps.sh            # programs Neovim uses at runtime
scripts/check-deps.sh --update   # programs scripts/update.sh needs
```

- **Required:** `nvim` ≥ 0.12, `git`, `fzf` ≥ 0.37 (≥ 0.53 recommended), `rg` ≥ 14.
- **Optional tools:** `fd`, `man`, `ast-grep`, `clang-format`, `xdg-open`.
- **Language servers:** each line says which language it's for. Install only the ones you
  need.

The exit status is `1` if anything required is missing or too old, and `0` otherwise, so the
script also works in other scripts. Run it on the machine you actually edit on.

On Ubuntu, most of it is:

```bash
sudo apt install fzf ripgrep fd-find git
```

Older distributions ship `fzf`/`rg` versions below the minimums. The script will flag them;
use `scripts/fetch-tools.sh` (below) to get current releases in that case.

### `scripts/fetch-tools.sh`: programs for the offline machine (needs network)

```bash
scripts/fetch-tools.sh ~/nvim-tools.tar
```

Downloads the latest x86_64 Linux release of each tool from GitHub and packs them, with
an `install.sh` (a copy of `scripts/install-tools.sh`), into one tarball (about 470 MB, mostly clangd):

| Tool | Build | Runs on |
|---|---|---|
| `nvim` | official release tarball | glibc ≥ 2.34 (Ubuntu 22.04+, RHEL 9+) |
| `fzf` | static Go binary | any x86_64 Linux |
| `rg`, `fd` | static musl builds | any x86_64 Linux |
| `ast-grep` | glibc build (skipped if `unzip` is missing) | glibc ≥ 2.34 |
| `clangd` | official release, with its built-in headers (skipped if `unzip` is missing) | glibc ≥ 2.18 |
| `pylsp` | `python-lsp-server` installed into a standalone Python ([python-build-standalone](https://github.com/astral-sh/python-build-standalone)), so it doesn't depend on the offline machine's Python | glibc ≥ 2.17 |

`nvim-tools/VERSIONS` lists the versions that were packed. The networked machine needs
`curl`, `tar` and `unzip`. Install the tarball on the offline machine as described
[above](#installing-on-the-offline-machine).

pylsp is `python-lsp-server[pyflakes,pycodestyle]`: completion, hover, definitions,
references and rename through jedi, plus pyflakes (unused imports, undefined names) and
pycodestyle (PEP 8 style) diagnostics. The bundled Python is used only by pylsp.

Not included: `git` and `man`, which come from the system's packages, `clang-format`, and
the other language servers (gopls, ts_ls, rust-analyzer). `tree-sitter` isn't needed on the offline machine because the parsers are already
compiled into `site/`.

### `scripts/update.sh`: refresh everything (needs network)

```bash
scripts/update.sh                       # update this config in place
scripts/update.sh ~/nvim-offline.tar    # ...and pack it for the offline machine
```

Steps, in order:

1. Runs `check-deps.sh --update`, and stops before changing anything if a tool is missing:
   `nvim` ≥ 0.12, `git`, `curl`, `tree-sitter` ≥ 0.26.1, a C compiler.
2. Copies the config (without `plugins/`, `site/`, `.git` and `*.tar`) into a scratch
   directory next to it, and runs nvim there with empty data/state/cache directories.
3. `:Lazy sync` downloads the latest version of every plugin in `lua/plugins/` and rewrites
   `lazy-lock.json`.
4. Downloads the blink.cmp matcher binary that matches its new version.
5. Downloads and compiles every parser listed in `lua/plugins/treesitter.lua` into `site/`.
6. Makes the `site/queries` links relative, runs `verify.sh` on the new build, and only if
   it passes replaces `plugins/`, `site/` and `lazy-lock.json` in the config directory. If any
   step failed, the config directory is left as it was.
7. If you passed a path, writes a tarball of the config directory there (leaving out any
   `*.tar` files in it) and runs `verify.sh` on the tarball. If that fails, don't copy it.
8. Prints the `check-deps.sh` report for the machine it ran on.

Every run starts from scratch and downloads everything, so the result never depends on what
an earlier run (or your everyday Neovim) left behind. It takes a few minutes each time.

### `scripts/verify.sh`: check a config or tarball works offline

```bash
scripts/verify.sh ~/nvim-offline.tar    # a tarball made by update.sh
scripts/verify.sh ~/.config/nvim        # or a config directory
```

Starts Neovim headless the way the offline machine will: the network cut off (when
`unshare -rn` is allowed), empty data/state/cache directories, and a tarball extracted
somewhere other than where it was built. It checks that there are no broken links, that
startup prints no errors, that every plugin is installed at its `lazy-lock.json` commit and
loads, that every parser in `lua/plugins/treesitter.lua` loads with its highlight queries
and highlighting starts, and that blink.cmp's binary loads. It exits 1 if anything fails.
`update.sh` runs it for you; it is also handy on the offline machine after extracting.
It doesn't check external programs; that's `check-deps.sh`.

One-time setup for the networked machine (Ubuntu):

```bash
sudo apt install build-essential curl git
npm install -g tree-sitter-cli          # or: cargo install tree-sitter-cli
```

## Typical update cycle

On the networked machine:

```bash
git clone <this-repo> ~/work/nvim       # first time only; or extract a previous tarball
cd ~/work/nvim && git pull
scripts/update.sh ~/nvim-offline.tar
scripts/fetch-tools.sh ~/nvim-tools.tar # when the tools need updating too
git diff lazy-lock.json                 # review what changed
git commit -am "Update plugins"
```

Then copy `~/nvim-offline.tar` (and `~/nvim-tools.tar`) over and install it as described
[above](#installing-on-the-offline-machine).

**Keep the directory named `nvim`.** The tarball holds a directory with the same name as the
config directory, so `tar -xf … -C ~/.config` only lands in `~/.config/nvim` if it's called
`nvim`. A different name also makes Neovim use separate data directories while the script
runs; that's harmless.

### Rolling back

- **On the offline machine:** move `~/.config/nvim.bak` back into place.
- **On the networked machine**, to return the plugins to the versions of an earlier commit:
  ```bash
  git checkout <commit> -- lazy-lock.json
  nvim --headless "+Lazy! restore" "+Lazy! build nvim-treesitter" +qa
  tar -C ~/work -cf ~/nvim-offline.tar nvim
  ```

## Common changes

After any change below, run `scripts/update.sh` on the networked machine so the offline copy
gets the new files.

- **Add a plugin:** add a spec to the matching file in `lua/plugins/`.
- **Remove a plugin:** delete its spec. The next update's `:Lazy sync` deletes it from
  `plugins/`.
- **Add a Treesitter language:** add it to `ensure_installed` in `lua/plugins/treesitter.lua`.
- **Add a language server:**
  1. Add its name to `vim.lsp.enable({...})` in `lua/config/lsp.lua`. The name is the file
     name in nvim-lspconfig's `lsp/` folder.
  2. Put any settings in `after/lsp/<name>.lua`.
  3. Add a `check optional …` line to `scripts/check-deps.sh` so the report covers it.
- **Change keymaps:** update [KEYBINDINGS.md](KEYBINDINGS.md) to match.

## Troubleshooting

- **No syntax highlighting for a language:** the parser isn't in `site/parser/`. Add the
  language to `ensure_installed` and run the update script. `:checkhealth nvim-treesitter`
  shows what's installed.
- **blink.cmp warns that it's using the Lua matcher:** the vendored binary doesn't match this
  machine or blink's version. Completion still works; run the update script on a matching
  machine to fix it.
- **A picker or grep does nothing:** run `scripts/check-deps.sh`. It's almost always a
  missing `fzf` or `rg`.
- **A language server doesn't start:** `:checkhealth vim.lsp` shows which servers are
  enabled and why one isn't attaching.
- **General plugin state:** `:Lazy` lists every plugin and its load status.
