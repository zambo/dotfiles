return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, {
      function()
        return "😄"
      end,
    })
  end,
}
--
-- return {
--   "nvim-lualine/lualine.nvim",
--   optional = true,
--   event = "VeryLazy",
--   opts = function(_, opts)
--     -- if (vim.g.colors_name or ""):find("catppuccin") then
--     --   opts.highlights = require("catppuccin.groups.integrations.bufferline").get()
--     -- end
--     -- opts.theme = "ayu"
--     -- t
--     opts.options.component_separators = { left = "", right = "" }
--     opts.options.section_separators = { left = "", right = "" }
--
--     opts.sections.lualine_a = { { "mode", icon = "" } }
--     opts.sections.lualine_c[4] = {
--       LazyVim.lualine.pretty_path({
--         filename_hl = "Bold",
--         modified_hl = "MatchParen",
--         directory_hl = "Conceal",
--       }),
--     }
--
--     if vim.g.lualine_info_extras == true then
--       table.insert(opts.sections.lualine_x, 2, { "lsp_status" })
--       table.insert(opts.sections.lualine_x, 2, formatter)
--       table.insert(opts.sections.lualine_x, 2, linter)
--     end
--
--     opts.sections.lualine_y = { "progress" }
--     opts.sections.lualine_z = {
--       { "location", separator = "" },
--       {
--         function()
--           return ""
--         end,
--         padding = { left = 0, right = 1 },
--       },
--     }
--     opts.extensions = {
--       "lazy",
--       "man",
--       "mason",
--       "nvim-dap-ui",
--       "overseer",
--       "quickfix",
--       "toggleterm",
--       "trouble",
--       "neo-tree",
--       "symbols-outline",
--     }
--   end,
-- }
