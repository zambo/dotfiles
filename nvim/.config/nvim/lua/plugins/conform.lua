return {
  "stevearc/conform.nvim",
  optional = true,
  opts = function(_, opts)
    -- Define supported file types for prettier
    local prettier_supported = {
      "css",
      "graphql",
      "handlebars",
      "html",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "less",
      "scss",
      "typescript",
      "typescriptreact",
      "vue",
      "yaml",
    }

    -- Define supported file types for biome
    local biome_supported = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "json",
      "jsonc",
    }

    opts.formatters_by_ft = opts.formatters_by_ft or {}

    -- Configure prettier for supported file types
    for _, ft in ipairs(prettier_supported) do
      opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      table.insert(opts.formatters_by_ft[ft], "prettier")
    end

    -- Configure biome for supported file types
    for _, ft in ipairs(biome_supported) do
      opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
      table.insert(opts.formatters_by_ft[ft], "biome")
    end

    -- Configure markdown formatters
    opts.formatters_by_ft["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" }
    opts.formatters_by_ft["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" }

    opts.formatters = opts.formatters or {}

    -- Prettier configuration
    opts.formatters.prettier = {
      condition = function(_, ctx)
        return vim.fs.find({
          ".prettierrc",
          ".prettierrc.json",
          ".prettierrc.js",
          "prettier.config.js",
          ".prettierrc.yaml",
          ".prettierrc.yml",
        }, { upward = true, path = ctx.dirname })[1] ~= nil or vim.g.lazyvim_prettier_needs_config ~= true
      end,
    }

    -- Biome configuration
    opts.formatters.biome = {
      require_cwd = true,
    }

    -- Markdown-toc configuration
    opts.formatters["markdown-toc"] = {
      condition = function(_, ctx)
        for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
          if line:find("<!%-%- toc %-%->") then
            return true
          end
        end
      end,
    }

    -- Markdownlint-cli2 configuration
    opts.formatters["markdownlint-cli2"] = {
      condition = function(_, ctx)
        local diag = vim.tbl_filter(function(d)
          return d.source == "markdownlint"
        end, vim.diagnostic.get(ctx.buf))
        return #diag > 0
      end,
    }

    return opts
  end,
}
