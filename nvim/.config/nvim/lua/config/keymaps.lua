-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Custom window cycling function that only includes focusable, non-floating windows
local function cycle_windows(direction)
  local wins = vim.api.nvim_list_wins()
  -- filter to only focusable, non-floating windows
  local focusable = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).focusable ~= false
  end, wins)

  local current = vim.api.nvim_get_current_win()
  local count = #focusable
  if count <= 1 then
    return
  end

  for i, w in ipairs(focusable) do
    if w == current then
      local next_i = ((i - 1 + direction) % count) + 1
      vim.api.nvim_set_current_win(focusable[next_i])
      return
    end
  end
end

-- ─────────────────────────────────────────────────────────────
-- Terminal management
-- ─────────────────────────────────────────────────────────────

-- Slot 1 is always the "main" bottom terminal.
-- cwd captured via vim.fn.getcwd() (stable from any buffer, including terminal
-- buffers) instead of LazyVim.root() which re-evaluates differently inside
-- terminal buffers and causes Snacks to treat it as a different terminal.
local MAIN_TERM_COUNT = 1
local MAIN_TERM_TITLE = "main"

local function main_term_opts()
  return {
    count = MAIN_TERM_COUNT,
    cwd = vim.fn.getcwd(),
    win = {
      position = "bottom",
      wo = { winbar = MAIN_TERM_TITLE .. ": %{get(b:, 'term_title', '')}" },
    },
  }
end

-- Returns the lowest free count slot >= 2 (slot 1 is reserved for main).
local function next_term_count()
  local used = {}
  for _, t in pairs(Snacks.terminal.list()) do
    local info = vim.b[t.buf] and vim.b[t.buf].snacks_terminal or {}
    if info.id then
      used[info.id] = true
    end
  end
  local n = 2
  while used[n] do
    n = n + 1
  end
  return n
end

-- Shared label helper
local function term_label(id, cwd)
  local short = vim.fn.fnamemodify(cwd or vim.fn.getcwd(), ":~:.")
  return (id == MAIN_TERM_COUNT and "[main] " or "[term " .. tostring(id) .. "] ") .. short
end

-- Terminal picker (<leader>ft, mirrors <leader>fb for buffers).
-- NOTE: snacks.win objects are userdata — not safe to put in picker items
-- (Snacks.picker deepcopies opts). Store only the buf integer; re-look up
-- the live terminal by buf at confirm time.
local function terminal_picker()
  local terms = Snacks.terminal.list()
  local items = {}

  for _, term in pairs(terms) do
    if term:buf_valid() then
      local info = vim.b[term.buf] and vim.b[term.buf].snacks_terminal or {}
      local id = info.id or "?"
      table.insert(items, {
        text = term_label(id, info.cwd),
        buf = term.buf,
        id = id,
      })
    end
  end

  table.sort(items, function(a, b)
    if a.id == MAIN_TERM_COUNT then
      return true
    end
    if b.id == MAIN_TERM_COUNT then
      return false
    end
    return tostring(a.id) < tostring(b.id)
  end)

  if #items == 0 then
    Snacks.notify.info("No terminals open", { title = "Terminals" })
    return
  end

  Snacks.picker({
    title = "Terminals",
    items = items,
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.schedule(function()
        for _, t in pairs(Snacks.terminal.list()) do
          if t.buf == item.buf then
            t:show():focus()
            return
          end
        end
      end)
    end,
  })
end

-- which-key expand: dynamically lists open terminals as numbered keys.
-- Called fresh each time the <c-\> popup opens, same mechanism as
-- <leader>b (buffers) and <leader>w (windows).
local function expand_terminals()
  local ret = {}
  local sorted = {}
  for _, t in pairs(Snacks.terminal.list()) do
    if t:buf_valid() then
      local info = vim.b[t.buf] and vim.b[t.buf].snacks_terminal or {}
      table.insert(sorted, { buf = t.buf, id = info.id or 999, cwd = info.cwd })
    end
  end
  table.sort(sorted, function(a, b)
    if a.id == MAIN_TERM_COUNT then
      return true
    end
    if b.id == MAIN_TERM_COUNT then
      return false
    end
    return a.id < b.id
  end)
  for i, entry in ipairs(sorted) do
    local buf = entry.buf -- capture by value for closure
    ret[#ret + 1] = {
      tostring(i),
      function()
        -- re-look up live terminal at execution time
        for _, t in pairs(Snacks.terminal.list()) do
          if t.buf == buf then
            t:show():focus()
            return
          end
        end
      end,
      desc = term_label(entry.id, entry.cwd),
    }
  end
  return ret
end

-- ── ctrl+/ ───────────────────────────────────────────────────
-- Always toggles the same "main" bottom terminal.
map({ "n", "t" }, "<c-/>", function()
  Snacks.terminal(nil, main_term_opts())
end, { desc = "Toggle main terminal" })
-- <c-_> is how some terminals encode ctrl+/ — keep in sync
map({ "n", "t" }, "<c-_>", function()
  Snacks.terminal(nil, main_term_opts())
end, { desc = "which_key_ignore" })

-- ── ctrl+\ (which-key group) ─────────────────────────────────
-- Registered via vim.schedule so which-key is available at call time.
vim.schedule(function()
  require("which-key").add({
    {
      "<c-\\>",
      group = "terminal",
      mode = { "n" },
      expand = expand_terminals,
    },
  })
end)

-- mergetool
vim.keymap.set("n", "<leader>gml", ":diffget LO<CR>", { desc = "Get LOCAL" })
vim.keymap.set("n", "<leader>gmr", ":diffget RE<CR>", { desc = "Get REMOTE" })
vim.keymap.set("n", "<leader>gmb", ":diffget BA<CR>", { desc = "Get BASE" })

-- Static actions under ctrl+\
map("n", "<c-\\>p", terminal_picker, { desc = "Pick terminal" })
map("n", "<c-\\>r", function()
  Snacks.terminal(nil, {
    count = next_term_count(),
    cwd = vim.fn.getcwd(),
    win = { position = "right" },
  })
end, { desc = "New terminal (right)" })
map("n", "<c-\\>d", function()
  Snacks.terminal(nil, {
    count = next_term_count(),
    cwd = vim.fn.getcwd(),
    win = { position = "bottom" },
  })
end, { desc = "New terminal (bottom)" })
map("n", "<c-\\>f", function()
  Snacks.terminal(nil, {
    count = next_term_count(),
    cwd = vim.fn.getcwd(),
    win = { position = "float", border = "rounded" },
  })
end, { desc = "New terminal (float)" })
map("n", "<c-\\>b", function()
  Snacks.terminal(nil, {
    count = next_term_count(),
    cwd = vim.fn.getcwd(),
    win = { position = "current" },
    -- buflisted = true so the terminal appears in buffer navigation (<leader>fb)
    -- immediately, without needing to switch away and back first.
    bo = { buflisted = true },
  })
end, { desc = "New terminal (buffer)" })

-- ── <leader>ft → terminal picker (mirrors <leader>fb for buffers) ──
-- Override LazyVim's default (<leader>ft opens a new float terminal).
map("n", "<leader>ft", terminal_picker, { desc = "Terminals" })
map("n", "<leader>fT", terminal_picker, { desc = "which_key_ignore" })

-- ── terminal mode: ctrl+\ opens the which-key group ──────────
map("t", "<c-\\>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, false, true), "n", true)
  vim.schedule(function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<c-\\>", true, false, true), "n", false)
  end)
end, { desc = "Terminal menu" })

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
-- map("n", "\x1b[1;6C", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- map("n", "\x1b[1;6D", "<cmd>bprev<cr>", { desc = "Previous buffer" })

-- cmd + shift + bracket to switch windows (cycles through windows)
-- this leverages combo I have set on my keyboard to switch tabs in browser
-- vim.keymap.del("n", "\x1b[1;6C", { silent = true }) -- Remove any existing mapping
-- vim.keymap.del("n", "\x1b[1;6D", { silent = true })
-- map("n", "\x1b[1;6C", "<cmd>wincmd w<cr>", { desc = "Next Window" })
-- map("n", "\x1b[1;6D", "<cmd>wincmd p<cr>", { desc = "Previous Window" })

-- CodeCompanion command abbreviations and keymaps (only if plugin is loaded)
if LazyVim.has("codecompanion.nvim") then
  -- Expand 'cc' into 'CodeCompanion' in the command line
  vim.cmd([[cab cc CodeCompanion]])
  vim.cmd([[cab ccc CodeCompanionChat]])
end

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
-- map("n", "<C-S-Right>", ":bnext<CR>", { desc = "Next buffer" })
-- map("n", "<C-S-Left>", ":bprevious<CR>", { desc = "Previous buffer" })
map({ "n", "i" }, "<C-S-Right>", function()
  cycle_windows(1)
end, { desc = "Next window" })
map({ "n", "i" }, "<C-S-Left>", function()
  cycle_windows(-1)
end, { desc = "Previous window" })

-- For terminal mode, we need to first exit terminal mode before sending the window command
map("t", "<C-S-Right>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, false, true), "n", true)
  vim.schedule(function()
    cycle_windows(1)
  end)
end, { desc = "Next window" })
map("t", "<C-S-Left>", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, false, true), "n", true)
  vim.schedule(function()
    cycle_windows(-1)
  end)
end, { desc = "Previous window" })

-- AI/CodeCompanion group under <leader>a (only if plugin is loaded)
if LazyVim.has("codecompanion.nvim") then
  map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "Actions" })
  map({ "n", "v" }, "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Chat" })
  map("v", "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add to Chat" })
  map({ "n", "v" }, "<leader>ai", "<cmd>CodeCompanion<cr>", { desc = "Inline Chat" })
  map({ "n", "v" }, "<leader>ac", function()
    require("codecompanion").prompt("cc")
  end, { desc = "Generate Commit Message" })
  map({ "n", "v" }, "<leader>aj", function()
    require("codecompanion").prompt("jw")
  end, { desc = "Generate Jira Task Description" })
end

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
