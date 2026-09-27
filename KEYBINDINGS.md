# Keybindings

`<leader>` is **Space**, `<localleader>` is **`\`**. Press `<leader>` and wait for
which-key to list what follows; `<leader>?` shows the keys local to the current buffer.

Modes: **n** normal, **x** visual, **i** insert. Keys marked *(default)* are Neovim or
plugin defaults that this config keeps; everything else is defined in `lua/`.

## Navigation

| Key | Mode | Action |
|---|---|---|
| `<C-o>` | n | Find files (fzf-lua) — **replaces** jump back |
| `<M-->` | n | Jump back (what `<C-o>` normally does) |
| `<M-=>` | n | Jump forward (same as `<C-i>`) |
| `<leader>o` | n | Open oil file explorer on the current file's directory |
| `` <leader>` `` | n | Toggle floating terminal |

## Find — `<leader>f`

| Key | Mode | Action |
|---|---|---|
| `<leader>ff` | n | Live grep in project (includes hidden files) |
| `<leader>fw` | n | Grep word under cursor |
| `<leader>/` | n | Live grep in current buffer |
| `<leader>fb` | n | Open buffers |
| `<leader>fs` | n | Document symbols (LSP, or Treesitter when no LSP) |
| `<leader>fr` | n | Workspace symbols (LSP buffers only) |
| `<leader>fm` | n | Man pages |
| `<leader>fts` | n | Search tags |
| `<leader>ftr` | n | Tags matching word under cursor |

## TODO / diagnostics — `<leader>t`

| Key | Mode | Action |
|---|---|---|
| `<leader>tt` | n | List TODO/FIXME/… comments |
| `<leader>td` | n | Workspace diagnostics |
| `<C-w>d` | n | Diagnostic popup for the cursor line *(default)* |
| `]d` / `[d` | n | Next / previous diagnostic *(default)* |

## LSP — `<leader>c`

Only active in buffers with a language server attached.

| Key | Mode | Action |
|---|---|---|
| `K` | n | Hover documentation *(default)* |
| `<F12>` / `<leader>cdd` | n | Go to definition |
| `<leader>cdp` | n | Peek definition (picker with preview) |
| `<S-F12>` / `<leader>cdr` | n | References (excluding the declaration) |
| `<leader>cdi` | n | Implementations |
| `<leader>ca` | n | Code action |
| `<leader>crr` | n | Rename symbol |
| `<leader>ch` | n | Toggle inlay hints |
| `]r` / `[r` | n | Next / previous reference to the symbol under cursor |
| `<C-k>o` | n | Switch between C/C++ source and header (clangd only) |
| `<leader>k` | n, x | Format buffer / selection (clang-format for C/C++, else LSP) |

Neovim's own LSP defaults also work: `grn` rename, `gra` code action, `grr` references,
`gri` implementation, `grt` type definition, `gO` document symbols, `<C-s>` (insert) signature help.

## Search & replace (grug-far) — `<leader>r`

| Key | Mode | Action |
|---|---|---|
| `<leader>rp` | n | Replace across project, word under cursor prefilled |
| `<leader>rp` | x | Replace across project, selection prefilled |
| `<leader>rf` | n, x | Replace in current file only |
| `<leader>re` | n | Replace in files with the current file's extension |
| `<leader>ro` | n | Open empty search/replace |
| `<leader>rt` | n | Show/hide a persistent search/replace window |

Inside the grug-far buffer (normal mode — it opens in insert mode, so `<Esc>` first):

| Key | Action |
|---|---|
| `<localleader>r` | Replace all |
| `<localleader>j` / `<localleader>k` | Apply next / previous match only |
| `<localleader>s` | Sync edits made in the results back to files |
| `<localleader>q` | Send results to quickfix |
| `<localleader>t` | History |
| `<localleader>e` | Swap engine (ripgrep / ast-grep) |
| `<localleader>c` | Close |
| `<Enter>` | Go to location |
| `g?` | Help (all keys) |

## Git — `<leader>g`

Only active in files tracked by git.

| Key | Mode | Action |
|---|---|---|
| `]h` / `[h` | n | Next / previous hunk |
| `<leader>ghs` | n, x | Stage / unstage hunk |
| `<leader>ghr` | n, x | Reset hunk |
| `<leader>ghp` | n | Preview hunk inline |
| `<leader>ghb` | n | Blame line (full commit message) |

## Completion (blink.cmp)

| Key | Mode | Action |
|---|---|---|
| `<C-Space>` | i | Open menu / toggle documentation |
| `<CR>` | i | Accept |
| `<C-n>` / `<C-p>`, `<Down>` / `<Up>` | i | Next / previous item |
| `<C-e>` | i | Close menu |
| `<C-b>` / `<C-f>` | i | Scroll documentation |
| `<C-k>` | i | Toggle signature help |
| `<Tab>` / `<S-Tab>` | i | Jump to next / previous snippet field |

## Inside pickers (fzf-lua)

| Key | Action |
|---|---|
| `<Enter>` | Open (multiple selections go to quickfix) |
| `<C-s>` / `<C-v>` / `<C-t>` | Open in split / vsplit / tab |
| `<Tab>` | Select multiple |
| `<M-q>` | Send selection to quickfix |
| `<M-h>` / `<M-i>` | Toggle hidden / gitignored files |
| `<C-g>` | Grep: switch between regex and fuzzy filtering |
| `<F1>` | Help (all keys) |

## Inside oil

| Key | Action |
|---|---|
| `<CR>` | Open file / enter directory |
| `-` | Parent directory |
| `_` | Open current working directory |
| `<C-s>` / `<C-h>` / `<C-t>` | Open in vsplit / split / tab |
| `<C-p>` | Preview |
| `g.` | Toggle hidden files |
| `<C-c>` | Close |
| `g?` | Help (all keys) |

Edit the buffer like text to rename, move, create or delete files; `:w` applies it.
Moving a file also updates LSP imports/references.

## Terminal

| Key | Action |
|---|---|
| `<Esc><Esc>` | Leave terminal mode (quick double press) |
| `q` | Hide terminal (normal mode) |

## Editing *(defaults)*

| Key | Mode | Action |
|---|---|---|
| `gcc` / `gc` | n / x | Toggle comment (Treesitter-aware) |
| `za` / `zc` / `zo` | n | Toggle / close / open fold (Treesitter folds, start open) |
| `zR` / `zM` | n | Open / close all folds |
