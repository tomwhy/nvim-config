-- Server definitions come from nvim-lspconfig (its lsp/*.lua files); local
-- overrides live in after/lsp/<server>.lua. Completion capabilities are added
-- to the "*" config by blink.cmp automatically.
vim.lsp.config("*", {
	root_markers = { ".project", ".git" },
})

vim.lsp.enable({ "clangd", "pylsp", "gopls", "ts_ls", "rust_analyzer" })

vim.diagnostic.config({
	severity_sort = true,
	virtual_text = { current_line = true }, -- message inline on the cursor line only
	float = { source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
	callback = function(ev)
		local fzf = function() return require("fzf-lua") end
		local function map(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
		end
		local function refs() fzf().lsp_references({ includeDeclaration = false }) end

		map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
		map("<leader>crr", vim.lsp.buf.rename, "Rename Symbol")
		map("<F12>", vim.lsp.buf.definition, "Goto Definition")
		map("<leader>cdd", vim.lsp.buf.definition, "Goto Definition")
		map("<leader>cdp", function() fzf().lsp_definitions({ jump1 = false }) end, "Peek Definition")
		map("<S-F12>", refs, "Show References")
		map("<leader>cdr", refs, "Show References")
		map("<leader>cdi", function() fzf().lsp_implementations() end, "Show Implementations")
		map("<leader>fr", function() fzf().lsp_live_workspace_symbols() end, "Goto Workspace Symbol")
		map("<leader>ch", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
		end, "Toggle Inlay Hints")
		-- K (hover) and <C-w>d (diagnostic float) are Neovim defaults.

		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client and client.name == "clangd" then
			map("<C-k>o", "<cmd>LspClangdSwitchSourceHeader<cr>", "Switch Source/Header file")
		end
	end,
})
