return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		dependencies = { "echasnovski/mini.icons" },
		opts = {
			grep = {
				rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 --hidden -e",
			},
		},
		init = function()
			-- Use fzf-lua for vim.ui.select (code actions etc.), loading it on first use.
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				require("fzf-lua").register_ui_select()
				return vim.ui.select(...)
			end
		end,
	},
	{
		"folke/snacks.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			indent = { enabled = true },
			rename = { enabled = true },
			terminal = { enabled = true },
			words = { enabled = true }, -- highlight/jump LSP references (replaces vim-illuminate)
		},
		keys = {
			{ "]r", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference" },
			{ "[r", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference" },
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		opts = {
			spec = {
				{ "<leader>t", group = "TODO" },
				{ "<leader>f", group = "Find" },
				{ "<leader>c", group = "LSP" },
				{ "<leader>cd", group = "Definitions" },
				{ "<leader>cr", group = "Rename" },
				{ "<leader>r", group = "Search/Replace", mode = { "n", "x" } },
				{ "<leader>g", group = "Git" },
				{ "<leader>gh", group = "Hunks" },
			},
		},
		keys = {
			{
				"<leader>?",
				function() require("which-key").show({ global = false }) end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			signs_staged = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
			},
			current_line_blame = true,
			on_attach = function(buffer)
				local gs = require("gitsigns")
				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

				map("n", "]h", function() gs.nav_hunk("next") end, "Next Hunk")
				map("n", "[h", function() gs.nav_hunk("prev") end, "Prev Hunk")
				map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage/Unstage Hunk")
				map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
				map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
				map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
			end,
		},
	},
	{
		"stevearc/oil.nvim",
		lazy = false, -- oil must load early to take over directory buffers
		dependencies = { "echasnovski/mini.icons" },
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			view_options = { show_hidden = true },
		},
	},
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TodoFzfLua", "TodoQuickFix" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},
	{
		"MagicDuck/grug-far.nvim",
		cmd = "GrugFar",
		opts = {},
		keys = function()
			local function grug() return require("grug-far") end
			local function cword() return vim.fn.expand("<cword>") end
			return {
				{ "<leader>rp", function() grug().open({ prefills = { search = cword() } }) end, desc = "Project Replace (word)" },
				{ "<leader>rp", function() grug().with_visual_selection() end, mode = "x", desc = "Project Replace (selection)" },
				{
					"<leader>rf",
					function()
						grug().open({ prefills = { search = cword(), paths = vim.fn.fnameescape(vim.fn.expand("%:p")) } })
					end,
					desc = "Replace in File",
				},
				{
					"<leader>rf",
					function()
						grug().with_visual_selection({ prefills = { paths = vim.fn.fnameescape(vim.fn.expand("%:p")) } })
					end,
					mode = "x",
					desc = "Replace in File (selection)",
				},
				{
					"<leader>re",
					function()
						local ext = vim.bo.buftype == "" and vim.fn.expand("%:e") or ""
						grug().open({ prefills = { search = cword(), filesFilter = ext ~= "" and "*." .. ext or nil } })
					end,
					desc = "Replace in Files of This Type",
				},
				{ "<leader>ro", function() grug().open() end, desc = "Open Search/Replace" },
				{
					"<leader>rt",
					function() grug().toggle_instance({ instanceName = "main", staticTitle = "Search/Replace" }) end,
					desc = "Toggle Search/Replace",
				},
			}
		end,
	},
}
