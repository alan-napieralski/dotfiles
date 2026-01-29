-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`
--
-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- -- Enable break indent
-- vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- vim: ts=2 sts=2 sw=2 expandtab
--
vim.diagnostic.config({
	virtual_text = true, -- show error messages inline
	signs = true, -- show error signs in the gutter
	underline = true, -- underline problematic code
	update_in_insert = false,
	severity_sort = true,
})

-- disable swap files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Then override the background highlights
vim.cmd([[
  hi Normal guibg=NONE ctermbg=NONE
  hi NormalNC guibg=NONE ctermbg=NONE
  hi EndOfBuffer guibg=NONE ctermbg=NONE
  hi VertSplit guibg=NONE ctermbg=NONE
]])

-- Numiko Settings
vim.filetype.add({
	extension = {
		css = "postcss",
		scss = "postcss",
		module = "php", -- Drupal
		theme = "php", -- Drupal
		install = "php", -- Drupal
		inc = "php", -- Drupal
	},
	filename = {
		[".html.twig"] = "twig", -- catch this if it's a full filename
	},
	pattern = {
		[".*%.html%.twig"] = "twig", -- catch general *.html.twig
	},
})

-- postcss
vim.filetype.add({
	extension = {
		scss = "scss",
		sass = "sass",
	},
	pattern = {
		[".*%.scss"] = "scss",
		[".*%.sass"] = "sass",
	},
})

-- treat css as css filetype
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.css",
	command = "set filetype=css",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.module", "*.install", "*.test", "*.inc", "*.profile", "*.view" },
	callback = function()
		vim.bo.filetype = "php"
	end,
})

vim.diagnostic.config({
	float = {
		focusable = false,
		style = "minimal",
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
		wrap = true, -- 👈 enable wrapping
	},
})

vim.diagnostic.config({
	float = {
		wrap = true,
		max_width = 80, -- or whatever width you prefer
	},
})
