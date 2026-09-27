-- nvim-treesitter `main` branch: it only installs parsers/queries. Highlighting,
-- folding and indent are enabled per buffer below with Neovim's built-in APIs.
local ensure_installed = {
	"asm", "bash", "c", "cpp", "diff", "go", "gomod", "gosum", "html",
	"javascript", "jsdoc", "json", "just", "lua", "luadoc", "luap", "make",
	"markdown", "markdown_inline", "printf", "python", "query", "regex",
	"rust", "toml", "tsx", "typescript", "vim", "vimdoc", "xml", "yaml",
}

-- Parsers and queries live in <config>/site so they ship with the config
-- (the offline machine can't download or compile them itself).
local function setup()
	require("nvim-treesitter").setup({ install_dir = vim.fn.stdpath("config") .. "/site" })
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		-- Parsers are downloaded + compiled (needs network and the `tree-sitter` CLI),
		-- so only do it when lazy builds the plugin (`:Lazy build nvim-treesitter`,
		-- or on update) rather than on every startup. `:TSInstall <lang>` for one-offs.
		build = function()
			setup()
			local ts = require("nvim-treesitter")
			ts.install(ensure_installed):wait(300000)
			ts.update():wait(300000)
		end,
		config = function()
			setup()
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
				callback = function(ev)
					local lang = vim.treesitter.language.get_lang(ev.match)
					if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
						return
					end
					vim.wo[0][0].foldmethod = "expr"
					vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					if vim.treesitter.query.get(lang, "indents") then
						vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
					end
				end,
			})
		end,
	},
}
