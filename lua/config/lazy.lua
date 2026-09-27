-- Plugins are vendored in <config>/plugins so this config works offline.
-- lazy.nvim uses that directory as its root: plugins already present are loaded
-- straight from disk, and on a machine with network `:Lazy update` / `:Lazy restore`
-- (using lazy-lock.json) still work. Copy the whole config dir to deploy.
local root = vim.fn.stdpath("config") .. "/plugins"
local lazypath = root .. "/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local out = vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "lazy.nvim not found in " .. root .. " and cloning failed:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	root = root,
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	spec = {
		{ import = "plugins" },
	},
	install = { colorscheme = { "material", "habamax" } },
	-- No background update checks: they need network.
	checker = { enabled = false },
	change_detection = { notify = false },
	rocks = { enabled = false },
})
