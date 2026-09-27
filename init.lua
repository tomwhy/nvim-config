-- Leaders must be set before lazy.nvim loads so plugin keymaps pick them up.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")
require("config.lsp")
require("config.keymaps")
require("config.autocmds")
