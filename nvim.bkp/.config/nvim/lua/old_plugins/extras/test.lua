-- Example: Simple and safe Neovim settings for testing CopilotChat
return {
  {
    "github/copilot.vim",
    enabled = true,
  },
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
    opts = {},
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = true,
    opts = {
      -- You can add more options here if needed
      debug = false,
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle CopilotChat" },
    },
  },
}
