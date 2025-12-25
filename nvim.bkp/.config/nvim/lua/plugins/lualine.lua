return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- Optional display of navic in lualine: https://www.lazyvim.org/extras/editor/navic#lualinenvim-optional
      if not vim.g.trouble_lualine then
        table.insert(opts.sections.lualine_c, { "navic", color_correction = "dynamic" })
      end
    end,
  },
}
