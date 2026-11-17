local map = vim.keymap.set

-- <C-o> opens the file finder, so the jumplist lives on <M--> / <M-=>.
map("n", "<M-->", "<C-o>", { desc = "Go back" })
map("n", "<M-=>", "<C-i>", { desc = "Go forward" })
map("n", "<C-o>", "<cmd>FzfLua files<cr>", { desc = "Find Files" })

-- Find
map("n", "<leader>/", "<cmd>FzfLua lgrep_curbuf<cr>", { desc = "Search File" })
map("n", "<leader>ff", "<cmd>FzfLua live_grep<cr>", { desc = "Search String" })
map("n", "<leader>fw", "<cmd>FzfLua grep_cword<cr>", { desc = "Search word" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fm", "<cmd>FzfLua manpages<cr>", { desc = "man" })
map("n", "<leader>fs", function()
	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		require("fzf-lua").treesitter()
	else
		require("fzf-lua").lsp_document_symbols()
	end
end, { desc = "Goto Symbol" })

-- Diagnostics / TODOs
map("n", "<leader>td", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "Diagnostics" })
map("n", "<leader>tt", "<cmd>TodoFzfLua<cr>", { desc = "Show TODOs" })

-- Misc
-- Yank into the system clipboard ("+) instead of the unnamed register.
map({ "n", "x" }, "<leader>Y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>o", function() require("oil").open() end, { desc = "open oil" })
map("n", "<leader>`", function() Snacks.terminal() end, { desc = "Open terminal" })
map({ "n", "v" }, "<leader>k", function() require("conform").format({ async = true }) end, { desc = "format" })
-- Search/replace (grug-far) keys live under <leader>r in plugins/editor.lua.
