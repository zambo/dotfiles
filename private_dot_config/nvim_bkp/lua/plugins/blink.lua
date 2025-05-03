return {
  "saghen/blink.cmp",
  optional = true,
  dependencies = { "giuxtaposition/blink-cmp-copilot" },
  opts = {
    sources = {
      default = { "copilot" },
      per_filetype = {
        codecompanion = {
          name = "codecompanion",
          -- module = "codecompanion",
          -- kind = "CodeCompanion",
          -- score_offset = 100,
          -- async = true,
        },
      },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-cmp-copilot",
          kind = "Copilot",
          score_offset = 100,
          async = true,
        },
      },
      -- snippets = {
      --   preset = "luasnip",
      -- },
    },
  },
}
