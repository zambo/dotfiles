-- Simply getting the models using curl for now.
-- Must check how to hook into codecompanion's model listing later.
-- curl https://api.fuelix.ai/v1/models --header "Authorization: Bearer $(op read op://Private/Fuel\ iX\ -\ Default\ API\ Key/API\ Key --no-newline)" | jq '[.data[].id]' | pbcopy
-- TODO: Remove this hardcoded list when codecompanion supports dynamic model listing.

local tempHardcodedModelResponse = {
  "gemini-1.5-pro",
  "gpt-4o",
  "gpt-4o-2024-05-13",
  "dall-e-3",
  "claude-3-5-sonnet",
  "claude-3-5-sonnet-20240620",
  "gemini-1.5-flash",
  "gpt-4o-2024-08-06",
  "gpt-4o-mini",
  "gpt-4o-mini-2024-07-18",
  "text-embedding-3-large",
  "text-embedding-3-small",
  "imagen-3",
  "gpt-4-0125-preview",
  "text-embedding-ada-002",
  "llama-3.2-90b",
  "gemini-2.0-flash",
  "claude-3-7-sonnet",
  "gpt-4.1-2025-04-14",
  "claude-sonnet-4",
  "llama-4-maverick-17b-128e",
  "whisper-1",
  "gemini-2.5-pro",
  "llama-4-scout-17b-16e",
  "claude-3-5-haiku",
  "gpt-5-2025-08-07",
  "gemini-2.5-flash",
  "gemini-2.5-flash-ca",
  "imagen-3-fast",
  "gpt-5-nano-2025-08-07",
  "gpt-5-mini-2025-08-07",
  "gpt-5-chat-2025-08-07",
  "imagen-4",
  "imagen-4-ultra",
  "gpt-4o-mini-2024-07-18-ptu",
  "gpt-5",
  "gpt-5-mini",
  "gpt-5-nano",
  "gpt-5-chat",
  "claude-3-5-haiku-20241022",
  "claude-4-sonnet",
  "claude-sonnet-4-20250514",
  "claude-sonnet-4-legacy",
  "claude-sonnet-4-5",
  "claude-sonnet-4-5-20250929",
  "gemini-2.5-flash-lite",
  "claude-haiku-4-5",
  "claude-haiku-4-5-20251015",
  "claude-haiku-4-5-20251001",
}

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
    },
    opts = {
      -- NOTE: The log_level is in `opts.opts`
      opts = {
        log_level = "DEBUG", -- or "TRACE"
      },
      adapters = {
        http = {
          fuel_ix = function()
            local openai = require("codecompanion.adapters.http.openai")
            return {
              -- something
              name = "fuel_ix",
              formatted_name = "Fuel iX",
              roles = {
                llm = "assistant",
                user = "user",
              },
              opts = {
                stream = true,
                vision = false,
              },
              features = {
                text = true,
                tokens = true,
              },
              url = "https://api.fuelix.ai/v1/chat/completions",
              env = {
                api_key = "cmd:op read 'op://Private/Fuel iX - Default API Key/API Key' --no-newline",
              },
              headers = {
                Authorization = "Bearer ${api_key}",
                ["Content-Type"] = "application/json",
              },
              handlers = {
                setup = function(self)
                  if self.opts and self.opts.stream then
                    self.parameters.stream = true
                  end
                  return true
                end,

                --- Use the OpenAI adapter for the bulk of the work
                tokens = function(self, data)
                  return openai.handlers.tokens(self, data)
                end,
                form_parameters = function(self, params, messages)
                  return openai.handlers.form_parameters(self, params, messages)
                end,
                form_messages = function(self, messages)
                  return openai.handlers.form_messages(self, messages)
                end,
                chat_output = function(self, data)
                  return openai.handlers.chat_output(self, data)
                end,
                inline_output = function(self, data, context)
                  return openai.handlers.inline_output(self, data, context)
                end,
                on_exit = function(self, data)
                  return openai.handlers.on_exit(self, data)
                end,
              },
              schema = {
                ---@type CodeCompanion.Schema
                model = {
                  order = 1,
                  mapping = "parameters",
                  type = "enum",
                  desc = "ID of the model to use. See the model endpoint compatibility table for details on which models work with the Chat API.",
                  default = "claude-sonnet-4-5",
                  choices = tempHardcodedModelResponse,
                },
              },
            }
          end,
        },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "<Leader>ah",
            save_chat_keymap = "<Leader>as",
            auto_save = true,
            expiration_days = 0,
            picker = "snacks",
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            enable_logging = false,
          },
        },
      },
    },
  },
}
