local map = vim.keymap.set
local o = vim.opt
local lazy = require("lazy")

map({ "n" }, "<A-a>i", "<cmd>CodeCompanion<cr><esc>", { remap = true, desc = "Open CodeCompanion Inline" })

map({ "n" }, "<A-a>c", "<cmd>CodeCompanionChat<cr><esc>", { remap = true, desc = "Open CodeCompanion Chat" })

map({ "n" }, "<A-a>a", "<cmd>CodeCompanionActions<cr><esc>", { remap = true, desc = "Open CodeCompanion Actions" })

map({ "n" }, "<C-r>", "<cmd>luafile %<cr><esc>", { remap = true, desc = "Open CodeCompanion Test" })

-- Lazy options
map("n", "<leader>l", "<Nop>")
map("n", "<leader>ll", "<cmd>Lazy<cr>", { desc = "Lazy" })
-- stylua: ignore start
map("n", "<leader>ld", function() vim.fn.system({ "xdg-open", "https://lazyvim.org" }) end, { desc = "LazyVim Docs" })
map("n", "<leader>lg", function() vim.fn.system({ "xdg-open", "https://github.com/LazyVim/LazyVim" }) end, { desc = "LazyVim Repo" })
map("n", "<leader>lx", "<cmd>LazyExtras<cr>", { desc = "Extras" })
map("n", "<leader>lc", function() LazyVim.news.changelog() end, { desc = "LazyVim Changelog" })

map("n", "<leader>lr", '<cmd>luafile %<cr>',  { desc = "Lazy Reload Config" })
map("n", "<leader>lu", function() lazy.update() end, { desc = "Lazy Update" })
map("n", "<leader>lC", function() lazy.check() end, { desc = "Lazy Check" })
map("n", "<leader>ls", function() lazy.sync() end, { desc = "Lazy Sync" })
-- stylua: ignore end

-- Disable LazyVim bindings
map("n", "<leader>L", "<Nop>")
map("n", "<leader>fT", "<Nop>")

-- Identation
map("n", "<", "<<", { desc = "Deindent" })
map("n", ">", ">>", { desc = "Indent" })

-- End of the word backwards
map("n", "E", "ge")

-- U for redo
map("n", "U", "<C-r>", { desc = "Redo" })
