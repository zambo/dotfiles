return {
  "stevearc/conform.nvim",
  optional = true,
  opts = function(_, opts)
    local util = require("conform.util")

    -- Disable LSP formatting in favor of conform
    opts.format_after_save = nil
    opts.lsp_fallback = false -- Never fall back to LSP formatting

    opts.formatters_by_ft = opts.formatters_by_ft or {}

    local ft_list = {
      "css",
      "graphql",
      "handlebars",
      "html",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "less",
      "markdown",
      "markdown.mdx",
      "scss",
      "typescript",
      "typescriptreact",
      "vue",
      "yaml",
    }

    for _, ft in ipairs(ft_list) do
      opts.formatters_by_ft[ft] = { "prettierd" }
    end

    opts.formatters = opts.formatters or {}
    opts.formatters.prettierd = {
      require_cwd = true,
      cwd = util.root_file({
        ".prettierrc",
        ".prettierrc.json",
        ".prettierrc.js",
        "prettier.config.js",
        ".prettierrc.yaml",
        ".prettierrc.yml",
      }),
    }
  end,
}
