-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local util = require("util")
local map = vim.keymap.set

util.cowboy()

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Edit inside Word
map("n", "<C-c>", "ciw")

map("n", "<M-Left>", "b", { desc = "Move backwards" })
map("n", "<M-Right>", "w", { desc = "Move forwards" })

-- CodeCompanion
-- map({ "n", "v" }, "<C-a>", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })
-- map({ "n", "v" }, "<Leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
-- map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])

-- Snacks Explorer: Reveal instead of toggle
-- map("n", "<leader>e", function()
--   Snacks.explorer.reveal({
--     hidden = true,
--   })
-- end, { desc = "Reveal Explorer" })

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)
-- map("n", "<Leader>O", "O<Esc>^Da", opts)
