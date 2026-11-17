-- Run by scripts/verify.sh inside a headless nvim that loaded the config under
-- test. Prints one line per check and exits non-zero if any failed.
local config = vim.fn.stdpath("config")
local results, failed = {}, 0

local function check(ok, msg, detail)
	if not ok then failed = failed + 1 end
	table.insert(results, (ok and "  ok    " or "  FAIL  ") .. msg .. (not ok and detail and (": " .. detail) or ""))
end

local function messages()
	return vim.api.nvim_exec2("messages", { output = true }).output
end

local function has_error(text)
	return text:find("rror") or text:find("E%d+:")
end

local function run()
	local msgs = messages()
	check(not has_error(msgs), "startup without errors", msgs)

	-- Plugins: all installed, at the commit in lazy-lock.json, and loadable.
	local plugins = require("lazy").plugins()
	local lock = vim.json.decode(table.concat(vim.fn.readfile(config .. "/lazy-lock.json"), "\n"))
	local git = require("lazy.manage.git")
	local missing, wrong = {}, {}
	for _, p in ipairs(plugins) do
		if not p._.installed then
			table.insert(missing, p.name)
		elseif lock[p.name] then
			local info = git.info(p.dir)
			if not info or info.commit ~= lock[p.name].commit then table.insert(wrong, p.name) end
		end
	end
	check(#missing == 0, #plugins .. " plugins installed", table.concat(missing, ", "))
	check(#wrong == 0, "plugins at the commits in lazy-lock.json", table.concat(wrong, ", "))
	local ok, err = pcall(vim.cmd, "Lazy! load all")
	msgs = messages()
	check(ok and not has_error(msgs), "all plugins load", ok and msgs or tostring(err))

	-- Treesitter: every parser in ensure_installed is present and has highlight queries.
	local spec = table.concat(vim.fn.readfile(config .. "/lua/plugins/treesitter.lua"), "\n")
	local list = spec:match("ensure_installed%s*=%s*(%b{})")
	local langs, bad = {}, {}
	for lang in (list or ""):gmatch('"([^"]+)"') do
		table.insert(langs, lang)
		local okp = pcall(vim.treesitter.language.add, lang)
		local okq, query = pcall(vim.treesitter.query.get, lang, "highlights")
		if not (okp and okq and query) then table.insert(bad, lang) end
	end
	check(#langs > 0, "ensure_installed found in lua/plugins/treesitter.lua")
	check(#bad == 0, #langs .. " Treesitter parsers load with highlight queries", table.concat(bad, ", "))

	-- Highlighting actually starts through the FileType autocmd.
	vim.cmd("enew")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1" })
	vim.bo.filetype = "lua"
	check(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "Treesitter highlighting starts on a lua buffer")

	local okb, errb = pcall(require, "blink.cmp.fuzzy.rust")
	check(okb, "blink.cmp fuzzy-matcher binary loads", tostring(errb))
end

local ok, err = xpcall(run, debug.traceback)
check(ok, "verify.lua ran to completion", err)
io.stdout:write(table.concat(results, "\n") .. "\n")
vim.cmd(failed == 0 and "qa!" or "cq")
