---@type vim.lsp.Config
return {
	cmd = {
		"clangd",
		"--background-index",
		"--limit-results=0",
		"--limit-references=0",
		"--header-insertion=never",
	},
	filetypes = { "c", "cpp" },
	root_markers = { "compile_commands.json" },
}
