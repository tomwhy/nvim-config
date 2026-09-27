local group = vim.api.nvim_create_augroup("user_config", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function() vim.hl.on_yank() end,
})

-- Keep LSP imports/references in sync when files are moved in oil.
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "OilActionsPost",
	callback = function(event)
		local action = event.data.actions[1]
		if action and action.type == "move" then
			Snacks.rename.on_rename_file(action.src_url, action.dest_url)
		end
	end,
})
