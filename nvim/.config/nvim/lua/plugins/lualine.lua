return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = function(_, opts)
      -- Ensure sections table exists
      opts.sections = opts.sections or {}
      opts.sections.lualine_c = opts.sections.lualine_c or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      -- Add CodeCompanion spinner to existing lualine_x (only if plugin is loaded)
      if LazyVim.has("codecompanion.nvim") then
        table.insert(opts.sections.lualine_x, {
          "codecompanion-lualine",
          spinner_interval = 150,
        })
      end

      table.insert(opts.sections.lualine_x, {
        "encoding",
      })

      table.insert(
        opts.sections.lualine_c,
        { "lsp_progress" } -- Shows LSP loading status,
      )

      -- Add Sidekick status indicators (only if plugin is loaded)
      if LazyVim.has("sidekick.nvim") then
        local icons = {
          Error = { " ", "DiagnosticError" },
          Inactive = { " ", "MsgArea" },
          Warning = { " ", "DiagnosticWarn" },
          Normal = { LazyVim.config.icons.kinds.Copilot, "Special" },
        }

        -- Sidekick main status icon
        table.insert(opts.sections.lualine_x, {
          function()
            local status = require("sidekick.status").get()
            return status and vim.tbl_get(icons, status.kind, 1)
          end,
          cond = function()
            return require("sidekick.status").get() ~= nil
          end,
          color = function()
            local status = require("sidekick.status").get()
            local hl = status and (status.busy and "DiagnosticWarn" or vim.tbl_get(icons, status.kind, 2))
            return { fg = Snacks.util.color(hl) }
          end,
        })

        -- Sidekick CLI session counter
        table.insert(opts.sections.lualine_x, {
          function()
            local status = require("sidekick.status").cli()
            return " " .. (#status > 1 and #status or "")
          end,
          cond = function()
            return #require("sidekick.status").cli() > 0
          end,
          color = function()
            return { fg = Snacks.util.color("Special") }
          end,
        })
      end

      -- Extend extensions
      opts.extensions = opts.extensions or {}
      vim.list_extend(opts.extensions, {
        "aerial",
        "mason",
        "nvim-dap-ui",
        "quickfix",
        "trouble",
      })

      return opts
    end,
  },
}
