-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Redo
map("n", "U", "<C-r>", { desc = "Redo" })

-- Edit inside Word
map("n", "<C-c>", "ciw")

map("n", "<M-Left>", "b", { desc = "Move backwards" })
map("n", "<M-Right>", "w", { desc = "Move forwards" })

-- sort json using jq (only json files)
map("n", "<leader>cj", ":%!jq -S .<CR>", { desc = "Format JSON with jq" })

-- cmd + shift + bracket to switch buffer
-- this leverages combo I have set on my keyboard to switch tabs in browser
map("n", "\x1b[1;6C", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "\x1b[1;6D", "<cmd>bprev<cr>", { desc = "Previous buffer" })

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])
vim.cmd([[cab ccc CodeCompanionChat]])

map("n", "<leader>e", function()
  local explorer_pickers = Snacks.picker.get({ source = "explorer" })
  for _, v in pairs(explorer_pickers) do
    if v:is_focused() then
      -- Will test this, I might want to simply focus the previous window instead of closing, but this might bug my brain later with the window toggling
      v:close()
    else
      v:focus()
    end
  end
  if #explorer_pickers == 0 then
    Snacks.picker.explorer()
  end
end, { desc = "Focus Snacks Explorer if not active" })

-- Change buffer using cmd shift brackets
map("n", "<C-S-Right>", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<C-S-Left>", ":bprevious<CR>", { desc = "Previous buffer" })

-- AI/CodeCompanion group under <leader>a
map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "Actions" })
map({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Chat" })
map("v", "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add to Chat" })
map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<cr>", { desc = "Inline Chat" })
map({ "n", "v" }, "<leader>ac", function()
  require("codecompanion").prompt("commit-message")
end, { desc = "Generate Commit Message" })

-- map("n", "<leader>acR", function()
--   vim.cmd("Lazy! reload codecompanion.nvim")
--   vim.notify("CodeCompanion reloaded - try again", vim.log.levels.INFO)
-- end, { desc = "Reload CodeCompanion plugin" })
--
-- -- Reload CodeCompanion to pick up prompt changes
-- map("n", "<leader>acr", function()
--   require("plenary.reload").reload_module("codecompanion")
--   require("codecompanion").setup(require("lazy.core.config").plugins["codecompanion.nvim"].opts)
--   vim.notify("CodeCompanion reloaded", vim.log.levels.INFO)
-- end, { desc = "Reload CodeCompanion" })

-- filepath: lua/config/keymaps.lua
map("n", "<leader>ww", function()
  -- Define filter function to avoid duplication
  local function should_include_window(winid)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local buftype = vim.bo[bufnr].buftype
    local filetype = vim.bo[bufnr].filetype

    -- Only exclude very specific unwanted window types (keep your original empty lists mostly)
    local excluded_buftypes = {} -- Keep empty as in your original
    local excluded_filetypes = {} -- Keep empty as in your original

    -- Only exclude windows that are not focusable (but include floating windows)
    local win_config = vim.api.nvim_win_get_config(winid)
    local is_focusable = vim.api.nvim_win_get_config(winid).focusable ~= false

    return is_focusable
      and not vim.tbl_contains(excluded_buftypes, buftype)
      and not vim.tbl_contains(excluded_filetypes, filetype)
  end

  -- Count visible windows using the filter
  local visible_windows = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if should_include_window(winid) then
      table.insert(visible_windows, winid)
    end
  end

  -- Debug: uncomment to see window count
  -- print("Visible windows count:", #visible_windows)

  -- If only 2 windows, just swap to the other one
  if #visible_windows == 2 then
    vim.cmd("wincmd w")
    return
  end

  -- If 3 or more windows, use the picker
  if #visible_windows >= 3 then
    local win = require("snacks.picker.util").pick_win({
      filter = should_include_window,
      include_floating = true,
    })
    if win then
      vim.api.nvim_set_current_win(win)
    end
  end

  -- If only 1 window, do nothing
end, { desc = "Window Picker" })
