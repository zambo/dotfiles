-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local util = require("util")
local map = vim.keymap.set

-- util.cowboy()

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

-- Disable continuations
-- map("n", "<Leader>o", "o<Esc>^Da", opts)
-- map("n", "<Leader>O", "O<Esc>^Da", opts)

-- Improved Window Picker with multi-mode support
local function window_picker()
  local snacks = require("snacks")

  local win = snacks.picker.util.pick_win({
    filter = function(winid)
      local ok, bufnr = pcall(vim.api.nvim_win_get_buf, winid)
      if not ok then
        return false
      end

      local buftype = vim.bo[bufnr].buftype
      local filetype = vim.bo[bufnr].filetype

      -- Exclude problematic window types
      local excluded_buftypes = {
        "nofile", -- most floating windows
        "prompt", -- command prompts
        "popup", -- popup windows
      }
      local excluded_filetypes = {
        "notify", -- notifications
        "snacks_notifier", -- snacks notifications
        "help", -- help windows (optional)
        "qf", -- quickfix
        "trouble", -- trouble.nvim
        "lazy", -- lazy.nvim
        "mason", -- mason.nvim
        "TelescopePrompt", -- if you still have telescope
      }

      -- Check if window is valid and visible
      if not vim.api.nvim_win_is_valid(winid) then
        return false
      end

      local config = vim.api.nvim_win_get_config(winid)
      -- Include floating windows but exclude some specific ones
      if config.relative ~= "" then
        -- It's a floating window, be more selective
        return not vim.tbl_contains(excluded_filetypes, filetype)
      end

      -- For regular windows, exclude both buftype and filetype
      return not vim.tbl_contains(excluded_buftypes, buftype) and not vim.tbl_contains(excluded_filetypes, filetype)
    end,
    include_floating = true,
  })

  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  else
    -- Fallback: cycle through windows
    vim.cmd("wincmd w")
  end
end

-- Multi-mode window picker mappings
-- Option 1: Replace default window cycling (most intuitive)
-- map("n", "<C-w>w", window_picker, { desc = "Window picker" })
-- map("v", "<C-w>w", window_picker, { desc = "Window picker" })
-- Terminal mode: use the terminal escape sequence properly
-- map("t", "<C-w>w", "<C-\\><C-n><C-w>w", { desc = "Window picker" })

-- Option 2: Double-tap Ctrl+W (fast and intuitive)
-- map({ "n", "v" }, "<C-w><C-w>", window_picker, { desc = "Quick window picker" })
-- map(
--   "t",
--   "<C-w><C-w>",
--   "<C-\\><C-n>:lua " .. "require('config.keymaps').window_picker()<CR>",
--   { desc = "Quick window picker" }
-- )

-- Option 3: Function key (works universally, zero conflicts)
-- map({ "n", "i", "v", "t" }, "<F4>", window_picker, { desc = "Window picker" })

-- Option 4: Leader-based (your original but optimized)
-- map({ "n", "i", "v" }, "<leader>w", window_picker, { desc = "Window picker" })
-- map("t", "<leader>w", "<C-\\><C-n>:lua " .. "require('config.keymaps').window_picker()<CR>", { desc = "Window picker" })

-- Export for terminal mode usage
-- return {
--   window_picker = window_picker,
-- }
