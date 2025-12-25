local M = require("lualine.component"):extend()

-- So, just leaving those icons here, we might be able to use them to change the icon based on status
-- 󰚩
-- 󱚝
-- 󱚟
-- 󱚡
-- 󱚣
-- 󱜙
-- 󱚥

local default_options = {
  icon = "󰚩 ",
  spinner_symbols = {
    "",
    "",
    "",
    "",
    "",
    "",
    "",
  },
  done_symbol = "✓",
  spinner_interval = 10, -- milliseconds between spinner updates
}

function M:init(options)
  M.super.init(self, options)

  self.options = vim.tbl_deep_extend("keep", self.options or {}, default_options)
  self.n_requests = 0
  self.spinner_index = 0
  self.timer = nil
  self.redraw_timer = nil

  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestStarted",
    callback = function()
      self.n_requests = self.n_requests + 1
      if self.n_requests == 1 then
        self:start_spinner()
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "CodeCompanionRequestFinished",
    callback = function()
      self.n_requests = math.max(0, self.n_requests - 1)
      if self.n_requests == 0 then
        self:stop_spinner()
      end
    end,
  })
end

function M:start_spinner()
  if self.timer then
    return
  end

  -- Spinner update timer
  self.timer = vim.uv.new_timer()
  self.timer:start(
    0,
    self.options.spinner_interval,
    vim.schedule_wrap(function()
      self.spinner_index = (self.spinner_index % #self.options.spinner_symbols) + 1
    end)
  )

  -- Separate redraw timer for smoother rendering
  self.redraw_timer = vim.uv.new_timer()
  self.redraw_timer:start(
    0,
    self.options.spinner_interval,
    vim.schedule_wrap(function()
      vim.cmd.redrawstatus()
    end)
  )
end

function M:stop_spinner()
  if self.timer then
    self.timer:stop()
    self.timer:close()
    self.timer = nil
  end
  if self.redraw_timer then
    self.redraw_timer:stop()
    self.redraw_timer:close()
    self.redraw_timer = nil
  end
  self.spinner_index = 0
end

function M:update_status()
  if not package.loaded["codecompanion"] then
    return nil
  end

  local symbol
  if self.n_requests > 0 then
    symbol = self.options.spinner_symbols[self.spinner_index > 0 and self.spinner_index or 1]
  else
    symbol = self.options.done_symbol
  end

  return ("%d %s"):format(self.n_requests, symbol)
end

return M
