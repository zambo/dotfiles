-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local util = require("util")
local map = vim.keymap.set

util.cowboy()

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Edit inside Word
vim.keymap.set("n", "<C-c>", "ciw")

vim.keymap.set("n", "<M-Left>", "b", { desc = "Move backwards" })
vim.keymap.set("n", "<M-Right>", "w", { desc = "Move forwards" })

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)
-- map("n", "<Leader>O", "O<Esc>^Da", opts)
