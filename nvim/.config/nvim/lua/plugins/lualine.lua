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

      -- Add CodeCompanion spinner to existing lualine_x
      table.insert(opts.sections.lualine_x, {
        "codecompanion-lualine",
        spinner_interval = 150,
      })
      table.insert(opts.sections.lualine_x, {
        "encoding",
      })

      table.insert(
        opts.sections.lualine_c,
        { "lsp_progress" } -- Shows LSP loading status,
      )

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
