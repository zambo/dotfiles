return {
  {
    "echasnovski/mini.align",
    opts = {},
    keys = {
      { "ga", mode = { "n", "v" } },
      { "gA", mode = { "n", "v" } },
    },
  },
  { "wakatime/vim-wakatime", lazy = false },
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  {
    "saghen/blink.cmp",
    dependencies = {
      { "disrupted/blink-cmp-conventional-commits" },
    },
    opts = {
      signature = {
        enabled = true,
      },
      sources = {
        default = {
          "lazydev", -- Add this before path
          "lsp",
          "codecompanion", -- Add this before path
          "buffer",
          "path",
          "conventional_commits",
        },
        providers = {
          conventional_commits = {
            name = "Conventional Commits",
            module = "blink-cmp-conventional-commits",
            enabled = function()
              return vim.bo.filetype == "gitcommit"
            end,
            ---@module 'blink-cmp-conventional-commits'
            ---@type blink-cmp-conventional-commits.Options
            -- opts = {}, -- none so far
          },
          path = {
            score_offset = -3,
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
  },

  {
    "Wansmer/treesj",
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },
  { "markdown-preview.nvim", enabled = false },

  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    opts = {
      theme = "light",
    },
    keys = {
      {
        "<leader>cp",
        function()
          require("peek").open()
        end,
      },
    },
  },
}
