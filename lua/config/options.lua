local opt = vim.opt

opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.laststatus = 3 -- single global statusline
opt.winborder = "single" -- default border for floats (hover, signature help, ...)

opt.undofile = true -- keep undo history across restarts
opt.ignorecase = true -- case-insensitive search...
opt.smartcase = true -- ...unless the pattern has a capital
opt.scrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.updatetime = 250 -- faster CursorHold (swap writes, LSP highlights)

-- Treesitter folding is set per-buffer in plugins/treesitter.lua; start unfolded.
opt.foldlevelstart = 99

vim.g.snacks_animate = false
