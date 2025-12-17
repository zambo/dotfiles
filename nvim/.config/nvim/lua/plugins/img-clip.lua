return {
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    enabled = true, -- Re-enabled: wasn't the issue
    opts = {
      -- add options here
      -- or leave it empty to use the default settings
    },
    keys = {
      -- suggested keymap
      { "<leader>pi", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
}
