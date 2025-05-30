local formatter = function()
  local formatters = require("conform").list_formatters(0)
  if #formatters == 0 then
    return ""
  end

  return "󰛖 "
end

local linter = function()
  local linters = require("lint").linters_by_ft[vim.bo.filetype]
  if #linters == 0 then
    return ""
  end

  return "󱉶 "
end

return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.options.theme = "auto"
    opts.options.component_separators = { left = "", right = "" }
    opts.options.section_separators = { left = "", right = "" }

    opts.sections.lualine_a = { { "mode", icon = "" } }
    opts.sections.lualine_c[4] = {
      LazyVim.lualine.pretty_path({
        filename_hl = "Bold",
        modified_hl = "MatchParen",
        directory_hl = "Conceal",
      }),
    }

    if vim.g.lualine_info_extras == true then
      table.insert(opts.sections.lualine_x, 2, { "lsp_status" })
      table.insert(opts.sections.lualine_x, 2, formatter)
      table.insert(opts.sections.lualine_x, 2, linter)
    end

    opts.sections.lualine_y = { "progress" }
    opts.sections.lualine_z = {
      { "location", separator = "" },
      {
        function()
          return ""
        end,
        padding = { left = 0, right = 1 },
      },
    }
    opts.extensions = {
      "lazy",
      "man",
      "mason",
      "nvim-dap-ui",
      "overseer",
      "quickfix",
      "toggleterm",
      "trouble",
      "neo-tree",
      "symbols-outline",
    }
  end,
}
