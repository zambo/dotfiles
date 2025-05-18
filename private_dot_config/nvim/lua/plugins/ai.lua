return {
  { "zbirenbaum/copilot.lua", dev = false },
  {
    "olimorris/codecompanion.nvim",
    enabled = true,
    cmd = { "CodeCompanion" },
    opts = {
      adapters = {
        mistral = function()
          return require("codecompanion.adapters").extend("mistral", {
            env = {
              url = "https://codestral.mistral.ai",
              api_key = "cmd:op read op://personal/mistral.ai/credential --no-newline",
              chat_url = "/v1/chat/completions",
            },
            schema = {
              model = {
                default = "codestral-latest",
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "mistral",
        },
        inline = {
          adapter = "copilot",
        },
        command = {
          adapter = "copilot",
        },
      },
    },
  },
}
