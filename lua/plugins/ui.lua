return {
	{
		"marko-cerovac/material.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.material_style = "darker"
			require("material").setup({})
			vim.cmd.colorscheme("material")
		end,
	},
	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {},
		init = function()
			-- Serve plugins that expect nvim-web-devicons (fzf-lua, lualine) from mini.icons.
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = {
			options = { globalstatus = true },
		},
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {
			views = {
				mini = { timeout = 5000 },
			},
			presets = {
				command_palette = true,
			},
			notify = {
				enabled = true,
				view = "mini",
			},
			messages = {
				enabled = true,
				view = "mini",
				view_error = "mini",
				view_warn = "mini",
			},
			lsp = {
				-- Render LSP hover/signature markdown with Treesitter.
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
			},
			routes = {
				{
					-- Send plain echo messages to the mini view.
					filter = {
						event = "msg_show",
						any = {
							{ kind = "" },
							{ kind = "echo" },
							{ kind = "echomsg" },
						},
					},
					view = "mini",
				},
			},
		},
	},
}
