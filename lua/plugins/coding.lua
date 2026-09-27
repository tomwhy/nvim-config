return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		-- Not lazy: loading registers completion capabilities for every LSP client.
		-- blink defers its own work until completion is actually used.
		lazy = false,
		dependencies = { "rafamadriz/friendly-snippets" },
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- <CR> accepts, <C-Space> opens, <C-e> closes, <C-n>/<C-p> select,
			-- <C-b>/<C-f> scroll docs (same keys as the old nvim-cmp setup).
			keymap = { preset = "enter" },
			completion = {
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
			},
			signature = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			-- The prebuilt Rust matcher is vendored in plugins/blink.cmp/target/release.
			-- While it matches the checked-out tag it's only checksum-verified locally
			-- (no network); after `:Lazy update` bumps the tag it's re-downloaded.
			-- It's built for x86_64 glibc Linux; elsewhere blink warns and uses Lua.
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
	},
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		---@module 'conform'
		---@type conform.setupOpts
		opts = {
			formatters_by_ft = {
				c = { "clang_format" },
				cpp = { "clang_format" },
			},
			default_format_opts = { lsp_format = "fallback" },
			formatters = {
				clang_format = {
					-- Prefer the versioned binary, like the old `%!clang-format-20` mapping.
					command = function()
						return vim.fn.executable("clang-format-20") == 1 and "clang-format-20" or "clang-format"
					end,
				},
			},
		},
	},
	{
		"folke/ts-comments.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
		---@module 'render-markdown'
		---@type render.md.UserConfig
		opts = {
			completions = { lsp = { enabled = true } },
		},
	},
}
