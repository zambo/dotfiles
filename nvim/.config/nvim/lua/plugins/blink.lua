return {
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    dependencies = {
      "fang2hou/blink-copilot",
      opts = {
        max_completions = 1, -- Global default for max completions
        max_attempts = 2, -- Global default for max attempts
      },
    },
    ---@type blink.cmp.Config
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-copilot",
            score_offset = 100,
            async = true,
            -- Local options override global options
            -- max_completions = 3,
          },
        },
      },
      snippets = {
        preset = "luasnip",
      },
      keymap = {
        ["<Tab>"] = {
          "snippet_forward",
          function()
            if LazyVim.has("sidekick.nvim") then
              return require("sidekick").nes_jump_or_apply()
            end
          end,
          function()
            return vim.lsp.inline_completion.get()
          end,
          "fallback",
        },
      },
    },
  },
  {
    "saghen/blink.compat",
    optional = true, -- make optional so it's only enabled if any extras need it
    opts = {},
    version = not vim.g.lazyvim_blink_main and "*",
  },
}
