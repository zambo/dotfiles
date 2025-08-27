-- Helper function to create Code Companion lualine component-- Helper function to create Code Companion lualine component
local function create_codecompanion_component()
  local M = require("lualine.component"):extend()
  M.processing = false
  M.spinner_index = 1
  local spinner_symbols = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local spinner_symbols_len = 10

  function M:init(options)
    M.super.init(self, options)
    local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = "CodeCompanionRequest*",
      group = group,
      callback = function(request)
        if request.match == "CodeCompanionRequestStarted" then
          self.processing = true
        elseif request.match == "CodeCompanionRequestFinished" then
          self.processing = false
        end
      end,
    })
  end

  function M:update_status()
    if self.processing then
      self.spinner_index = (self.spinner_index % spinner_symbols_len) + 1
      return spinner_symbols[self.spinner_index]
    else
      return nil
    end
  end

  return M
end

local commit_template = [[
You are an expert at following the Conventional Commit specification.

Given the git diff listed below, please generate a commit message. Try to keep it short and concise, using a more natural language style.

Follow the Conventional Commit format, starting with a type (feat, fix, docs, style, refactor, perf, test, chore), followed by an optional scope in parentheses, and then a brief description.

When unsure about the module names to use in the commit message, you can refer to the last 20 commit messages in this repository.

If the changes do not fit any specific type, use 'chore' as the type.

Write commit message for the diffs with commitizen convention. Wrap the whole message in a markdown code block with language `gitcommit`

```diff
%s
```
]]

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
    config = function()
      require("mcphub").setup()
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
      "ravitemer/codecompanion-history.nvim",
      {
        "saghen/blink.cmp",
        opts = {
          sources = {
            default = { "codecompanion", "lsp", "buffer", "snippets", "path" },
            providers = {
              codecompanion = {
                name = "CodeCompanion",
                module = "codecompanion.providers.completion.blink",
                enabled = true,
              },
            },
          },
        },
      },
    },

    config = true,
    cmd = {
      "CodeCompanion",
      "CodeCompanionActions",
      "CodeCompanionChat",
      "CodeCompanionCmd",
    },
    opts = {
      adapters = {
        mistral = function()
          return require("codecompanion.adapters").extend("mistral", {
            env = {
              url = "https://codestral.mistral.ai",
              api_key = "cmd:op read op://personal/mistral.ai/credential --no-newline",
              chat_url = "/v1/chat/completions",
            },
            tools = {
              web_search = { enabled = true },
              web_fetch = { enabled = true },
            },
            schema = {
              model = {
                default = "codestral-latest",
              },
            },
          })
        end,
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "cmd:op read op://personal/anthropic/credential --no-newline",
            },
            tools = {
              web_search = { enabled = true },
              web_fetch = { enabled = true },
            },
            schema = {
              model = {
                default = "claude-opus-4-20250514",
              },
            },
          })
        end,
      },
      prompt_library = {
        ["Generate a Commit Message"] = {
          strategy = "chat",
          description = "Generate a commit message",
          opts = {
            index = 10,
            is_default = true,
            is_slash_cmd = true,
            short_name = "commit",
            auto_submit = true,
          },
          prompts = {
            {
              role = "user",
              content = function()
                local diff = vim.fn.system("git diff --no-ext-diff --staged")
                local log = vim.fn.system('git log --pretty=format:"%s" -n 20')
                local prompt = string.format(commit_template, diff, log)
                -- Remove all newlines and excess whitespace for output
                return prompt
              end,
              opts = {
                contains_code = true,
              },
            },
          },
        },
      },
      slash_commands = {
        ["url"] = {
          callback = function(url)
            -- This allows @url command in chat
            return "Fetching content from: " .. url
          end,
          description = "Fetch content from a URL",
        },
        ["web"] = {
          callback = function(query)
            -- This allows @web command for web search
            return "Searching web for: " .. query
          end,
          description = "Search the web",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            show_result_in_chat = true, -- Show mcp tool results in chat
            make_vars = true, -- Convert resources to #variables
            make_slash_commands = true, -- Add prompts as /slash commands
          },
        },
        history = {
          enabled = true,
          opts = {
            -- Keymap to open history from chat buffer (default: gh)
            keymap = "<Leader>ah",
            -- Keymap to save the current chat manually (when auto_save is disabled)
            save_chat_keymap = "<Leader>as",
            -- Save all chats by default (disable to save only manually using 'sc')
            auto_save = true,
            -- Number of days after which chats are automatically deleted (0 to disable)
            expiration_days = 1,
            -- Picker interface ("telescope" or "snacks" or "fzf-lua" or "default")
            picker = "snacks",
            ---Automatically generate titles for new chats
            auto_generate_title = true,
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = false,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            ---Enable detailed logging for history extension
            enable_logging = false,
            ---Add error handling for API requests
            -- on_error = function(err)
            --   -- Silently handle API overload errors
            --   if err and type(err) == "string" and err:match("Overloaded") then
            --     return true -- suppress error
            --   end
            --   return false -- show error
            -- end,
          },
        },
      },
      strategies = {
        chat = {
          adapter = "copilot", -- Changed to use Claude for chat
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
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function()
      return {
        sections = {
          lualine_x = {
            -- Other lualine components in "x" section
            { require("mcphub.extensions.lualine") },
            -- Code Companion spinner component
            { create_codecompanion_component() },
          },
        },
      }
    end,
  },
}
