return {
  {
    "m4xshen/hardtime.nvim",
    lazy = false,
    enabled = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      restricted_keys = {
        ["<UP>"] = { "n", "x" },
        ["<DOWN>"] = { "n", "x" },
        ["<LEFT>"] = { "n", "x" },
        ["<RIGHT>"] = { "n", "x" },
      },
      disabled_keys = {
        ["<Up>"] = {},
        ["<Down>"] = {},
        ["<Left>"] = {},
        ["<Right>"] = {},
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}

      -- Add CodeCompanion keybindings
      vim.list_extend(opts.spec, {
        -- Keep Ctrl+A for quick actions
        {
          "<C-a>",
          "<cmd>CodeCompanionActions<cr>",
          desc = "CodeCompanion Actions",
          mode = { "n", "v" },
        },

        -- Organize under <Leader>a
        {
          "<leader>a",
          group = "AI/CodeCompanion",
          {
            "<leader>aa", -- Actions
            "<cmd>CodeCompanionActions<cr>",
            desc = "Actions",
            mode = { "n", "v" },
          },
          {
            "<leader>ac", -- Chat
            "<cmd>CodeCompanionChat Toggle<cr>",
            desc = "Toggle Chat",
            mode = { "n", "v" },
          },
          {
            "<leader>ad", -- Add to chat (visual)
            "<cmd>CodeCompanionChat Add<cr>",
            desc = "Add to Chat",
            mode = "v",
          },
          -- You can add more CodeCompanion commands here
          {
            "<leader>ai", -- Inline
            "<cmd>CodeCompanionChat Inline<cr>",
            desc = "Inline Chat",
            mode = { "n", "v" },
          },
        },
      })

      return opts
    end,
  },
}
