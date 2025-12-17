return {
  "Bekaboo/dropbar.nvim",
  -- optional, but required for fuzzy finder support
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
  opts = {
    bar = {
      padding = {
        left = 2,
        right = 2,
      },
    },
    menu = {
      win_configs = {
        border = "rounded",
        -- Add vertical spacing around menu
        row = 1, -- This creates top margin
      },
      entry = {
        padding = {
          left = 2, -- Internal item left padding
          right = 2, -- Internal item right padding
        },
      },
    },
    icons = {
      ui = {
        bar = {
          separator = "  ", -- Add more space between items
        },
      },
    },
  },
  config = function(_, opts)
    require("dropbar").setup(opts)

    local dropbar_api = require("dropbar.api")

    vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
    vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
    vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
  end,
}
