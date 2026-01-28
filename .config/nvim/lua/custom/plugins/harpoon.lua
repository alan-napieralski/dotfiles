return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },

	config = function()
		local harpoon = require("harpoon")

		local harpoon_config = {
			settings = {
				-- Persist Harpoon edits when closing/leaving the menu window.
				save_on_toggle = true,
				-- Also sync those changes to Harpoon’s on-disk JSON storage.
				sync_on_ui_close = true,
				-- Use the active neovim-project directory as the key.
				key = function()
					local project_path = require("neovim-project.utils.path")
					return vim.fn.expand(project_path.dir_pretty or project_path.cwd() or vim.loop.cwd())
				end,
			},
		}

		-- Initial setup (may run before neovim-project finishes loading a session).
		harpoon:setup(harpoon_config)

		-- Re-run setup after session load so Harpoon reads the correct project file.
		-- (Harpoon loads its data file on setup and doesn't automatically reload it when the key changes.)
		local harpoon_group = vim.api.nvim_create_augroup("custom-harpoon", { clear = true })
		vim.api.nvim_create_autocmd("User", {
			group = harpoon_group,
			pattern = "SessionLoadPost",
			callback = function()
				harpoon:setup(harpoon_config)
			end,
		})

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end)
		vim.keymap.set("n", "<leader>e", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end)
		vim.keymap.set("n", "<leader>j", function()
			harpoon:list():select(1)
		end)
		vim.keymap.set("n", "<leader>k", function()
			harpoon:list():select(2)
		end)
		vim.keymap.set("n", "<leader>l", function()
			harpoon:list():select(3)
		end)
		vim.keymap.set("n", "<leader>;", function()
			harpoon:list():select(4)
		end)

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<C-p>", function()
			harpoon:list():prev()
		end)

		vim.keymap.set("n", "<C-n>", function()
			harpoon:list():next()
		end)
	end,
}
