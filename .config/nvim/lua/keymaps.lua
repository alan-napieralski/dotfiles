-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Resize with Option + Arrow keys
vim.keymap.set("n", "<A-Up>", ":resize -2<CR>", { silent = true })
vim.keymap.set("n", "<A-Down>", ":resize +2<CR>", { silent = true })
vim.keymap.set("n", "<A-Right>", ":vertical resize -2<CR>", { silent = true })
vim.keymap.set("n", "<A-Left>", ":vertical resize +2<CR>", { silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- vim: ts=2 sts=2 sw=2 et
--
--
vim.o.autochdir = true
-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertLeave", "TextChanged" }, {
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		if
			vim.bo[buf].modified
			and not vim.bo[buf].readonly
			and vim.fn.expand("%") ~= ""
			and vim.bo[buf].buftype == ""
		then
			vim.api.nvim_command("write")
		end
	end,
})

-- refactor.nvim

vim.keymap.set("x", "<leader>re", ":Refactor extract ")
vim.keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

vim.keymap.set("x", "<leader>rv", ":Refactor extract_var ")

vim.keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

vim.keymap.set("n", "<leader>rI", ":Refactor inline_func")

vim.keymap.set("n", "<leader>rb", ":Refactor extract_block")
vim.keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")

-- flote
vim.keymap.set("n", "<leader>n", function()
	-- check if a Flote buffer is open
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf):match("flote") then
			-- Flote buffer found → toggle window
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(win) == buf then
					vim.api.nvim_win_close(win, true) -- close Flote window
					return
				end
			end
			-- if buffer exists but window is not open, open it
			vim.cmd("Flote")
			return
		end
	end
	-- no Flote buffer found → open Flote
	vim.cmd("Flote")
end, { desc = "Toggle Flote" })

-- Diagnostics
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)
