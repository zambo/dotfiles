-- zk: wiki-link helpers, active only for buffers inside a zk notebook.
local ok, zk_util = pcall(require, "zk.util")
if not ok or zk_util.notebook_root(vim.fn.expand("%:p")) == nil then
  return
end

local zk = require("zk")

-- Strip `|alias` and `#anchor` so `[[Emiliano|Emi]]` yields `Emiliano`.
local function link_target(inner)
  return vim.trim((inner:gsub("[|#].*$", "")))
end

-- Return the `[[...]]` target covering `col` (0-based) on `line`, if any.
local function link_at(line, col)
  local init = 1
  while true do
    local s, e, inner = line:find("%[%[(.-)%]%]", init)
    if not s then
      return nil
    end
    if col >= s - 1 and col <= e - 1 then
      return link_target(inner)
    end
    init = e + 1
  end
end

local function create(title, edit)
  zk.new({
    title = title,
    edit = edit,
    notebook_path = vim.fn.expand("%:p"),
  })
end

local function create_from_link()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local title = link_at(vim.api.nvim_get_current_line(), col)
  if not title or title == "" then
    return vim.notify("No [[wiki-link]] under cursor", vim.log.levels.WARN)
  end
  create(title, true)
end

-- Create every note that the zk LSP reports as a dead link in this buffer.
local function create_missing()
  local seen, titles = {}, {}
  for _, d in ipairs(vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })) do
    local line = vim.api.nvim_buf_get_lines(0, d.lnum, d.lnum + 1, false)[1] or ""
    local title = link_at(line, d.col)
    local key = title and title:lower()
    if title and title ~= "" and not seen[key] then
      seen[key] = true
      table.insert(titles, title)
    end
  end
  if #titles == 0 then
    return vim.notify("No dead links found", vim.log.levels.INFO)
  end
  for _, title in ipairs(titles) do
    create(title, false)
  end
  vim.notify("Created " .. #titles .. " note(s): " .. table.concat(titles, ", "))
  -- Re-index so the dead-link diagnostics clear.
  vim.defer_fn(function()
    zk.index({ notebook_path = vim.fn.expand("%:p") })
  end, 500)
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("n", "<leader>zc", create_from_link, "Create note from link")
map("n", "<leader>zC", create_missing, "Create all missing linked notes")
map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", "Backlinks")
map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", "Outgoing links")
map("v", "<leader>zn", ":'<,'>ZkNewFromTitleSelection<CR>", "New note from selection (title)")
