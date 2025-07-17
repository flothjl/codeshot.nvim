local M = {}

local font_path = ""

M.options = {
	theme = "dracula",
	font = font_path, -- Default to bundled font
}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
	vim.api.nvim_create_user_command("Codeshot", function()
		M.screenshot_selection()
	end, { range = true })

	vim.keymap.set(
		"v",
		"<leader>cs",
		":<C-u>Codeshot<CR>",
		{ noremap = true, silent = true, desc = "Codeshot: Screenshot selection" }
	)
end

function M.screenshot_selection()
	local codeshot_bin = "codeshot"
	if vim.fn.executable(codeshot_bin) == 0 then
		vim.notify(
			"Unable to find 'codeshot' in your $PATH.\nPlease install with:\n  go install github.com/flothjl/codeshot@latest",
			vim.log.levels.ERROR
		)
		return
	end

	local theme = M.options.theme
	local font = M.options.font
	local lang = vim.bo.filetype
	local ts = os.date("%Y%m%d-%H%M%S")
	local outfile = vim.fn.getcwd() .. "/codeshot-" .. ts .. ".png"

	-- Get visual selection (charwise and linewise)
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local start_row, start_col = start_pos[2] - 1, start_pos[3] - 1
	local end_row, end_col = end_pos[2] - 1, end_pos[3] - 1

	local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
	if #lines == 0 then
		vim.notify("Nothing selected!", vim.log.levels.WARN)
		return
	end

	lines[1] = string.sub(lines[1], start_col + 1)
	lines[#lines] = string.sub(lines[#lines], 1, end_col)
	local code = table.concat(lines, "\n")

	-- Write to temp file
	local tmp = os.tmpname() .. ".txt"
	local f, err = io.open(tmp, "w")
	if not f then
		vim.notify("Failed to write temp file: " .. (err or ""), vim.log.levels.ERROR)
		return
	end
	f:write(code)
	f:close()

	-- Build and run codeshot command
	local cmd = string.format(
		"%s --file '%s' --lang %s --theme %s --font '%s' --out '%s'",
		codeshot_bin,
		tmp,
		lang,
		theme,
		font,
		outfile
	)
	local result = vim.fn.system(cmd)
	os.remove(tmp)

	if vim.v.shell_error ~= 0 then
		vim.notify("codeshot failed:\n" .. result, vim.log.levels.ERROR)
		return
	end

	vim.notify("Screenshot saved to:\n" .. outfile, vim.log.levels.INFO)
end

return M
