-- Spinner component for CodeCompanion lualine
local function create_codecompanion_component()
  local M = require("lualine.component"):extend()
  M.processing = false
  M.spinner_index = 1
  local spinner_symbols = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
  local spinner_symbols_len = #spinner_symbols
  function M:init(options)
    M.super.init(self, options)
    local group = vim.api.nvim_create_augroup("CodeCompanionHooks", {})
    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = "CodeCompanionRequest*",
      group = group,
      callback = function(ev)
        if ev.match == "CodeCompanionRequestStarted" then
          self.processing = true
        elseif ev.match == "CodeCompanionRequestFinished" then
          self.processing = false
        end
      end,
    })
  end
  function M:update_status()
    if self.processing then
      self.spinner_index = (self.spinner_index % spinner_symbols_len) + 1
      return spinner_symbols[self.spinner_index]
    end
    return nil
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

-- Anthropic OAuth adapter (use Claude Pro subscription instead of API tokens)
local function anthropic_oauth_adapter()
  -- Check if we have an OAuth token
  local ok, claude_adapter = pcall(require, "anthropic.claude_code_adapter")
  if ok then
    local adapter = claude_adapter.create()
    if adapter then
      return adapter
    end
  end

  -- Fallback to API key
  return require("codecompanion.adapters").extend("anthropic", {
    env = {
      api_key = "cmd:op read op://personal/anthropic/credential --no-newline",
    },
  })
end

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = { markdown = true, help = true },
    },
  },
  {
    dir = "~/Development/ai-nvim/anthropic.nvim",
    name = "anthropic.nvim",
    dev = true,
    config = function()
      require("anthropic").setup({
        oauth_enabled = true,
        purge_oauth_after_key = true,
        auto_refresh = true,
        debug = true,
        warn_experimental = false,
      })
    end,
  },
  {
    "ravitemer/mcphub.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    build = "npm install -g mcp-hub@latest",
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
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat", "CodeCompanionCmd" },
    opts = {
      adapters = {
        mistral = function()
          return require("codecompanion.adapters").extend("mistral", {
            env = {
              url = "https://codestral.mistral.ai",
              api_key = "cmd:op read op://personal/mistral.ai/credential --no-newline",
              chat_url = "/v1/chat/completions",
            },
            tools = { web_search = { enabled = true }, web_fetch = { enabled = true } },
            schema = { model = { default = "codestral-latest" } },
          })
        end,
        -- claude_oauth = function()
        --   vim.notify("[CodeCompanion] 🚀 Loading dynamic Claude adapter...", vim.log.levels.INFO)
        --   local dynamic_adapter = require("anthropic.claude_code_adapter_dynamic").create()
        --
        --   if dynamic_adapter then
        --     vim.notify("[CodeCompanion] ✅ Using OAuth with dynamic models!", vim.log.levels.INFO)
        --     return dynamic_adapter
        --   else
        --     vim.notify("[CodeCompanion] ⚠️  OAuth not available, falling back to API key", vim.log.levels.WARN)
        --     vim.notify("[CodeCompanion] 💡 Run :Anthropic auth to set up OAuth", vim.log.levels.INFO)
        --     return require("codecompanion.adapters").extend("anthropic", {
        --       env = {
        --         api_key = "cmd:op read op://personal/anthropic/credential --no-newline",
        --       },
        --     })
        --   end
        -- end,
      },
      prompt_library = {
        ["Generate a Commit Message"] = {
          strategy = "chat",
          description = "Generate a commit message",
          opts = { index = 10, is_default = true, is_slash_cmd = true, short_name = "commit", auto_submit = true },
          prompts = {
            {
              role = "user",
              content = function()
                local diff = vim.fn.system("git diff --no-ext-diff --staged")
                local log = vim.fn.system('git log --pretty=format:"%s" -n 20')
                return string.format(commit_template, diff, log)
              end,
              opts = { contains_code = true },
            },
          },
        },
      },
      slash_commands = {
        url = {
          callback = function(url)
            return "Fetching content from: " .. url
          end,
          description = "Fetch content from a URL",
        },
        web = {
          callback = function(q)
            return "Searching web for: " .. q
          end,
          description = "Search the web",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = { show_result_in_chat = true, make_vars = true, make_slash_commands = true },
        },
        history = {
          enabled = true,
          opts = {
            keymap = "<Leader>ah",
            save_chat_keymap = "<Leader>as",
            auto_save = true,
            expiration_days = 1,
            picker = "snacks",
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            enable_logging = false,
          },
        },
      },
      strategies = {
        chat = { adapter = "copilot" },
        inline = { adapter = "copilot" },
        command = { adapter = "copilot" },
      },
    },
  },
  {
    "NickvanDyke/opencode.nvim",
    dependencies = { { "folke/snacks.nvim", opts = { input = { enabled = true } } } },
    opts = {},
    keys = {
      {
        "<leader>oA",
        function()
          require("opencode").ask()
        end,
        desc = "Ask opencode",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@cursor: ")
        end,
        desc = "Ask opencode about this",
        mode = "n",
      },
      {
        "<leader>oa",
        function()
          require("opencode").ask("@selection: ")
        end,
        desc = "Ask opencode about selection",
        mode = "v",
      },
      {
        "<leader>ot",
        function()
          require("opencode").toggle()
        end,
        desc = "Toggle embedded opencode",
      },
      {
        "<leader>on",
        function()
          require("opencode").command("session_new")
        end,
        desc = "New session",
      },
      {
        "<leader>oy",
        function()
          require("opencode").command("messages_copy")
        end,
        desc = "Copy last message",
      },
      {
        "<S-C-u>",
        function()
          require("opencode").command("messages_half_page_up")
        end,
        desc = "Scroll messages up",
      },
      {
        "<S-C-d>",
        function()
          require("opencode").command("messages_half_page_down")
        end,
        desc = "Scroll messages down",
      },
      {
        "<leader>op",
        function()
          require("opencode").select_prompt()
        end,
        desc = "Select prompt",
        mode = { "n", "v" },
      },
      {
        "<leader>oe",
        function()
          require("opencode").prompt("Explain @cursor and its context")
        end,
        desc = "Explain code near cursor",
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
            {
              function()
                -- Check if MCPHub is loaded
                if not vim.g.loaded_mcphub then
                  return "󰐻 -"
                end

                local count = vim.g.mcphub_servers_count or 0
                local status = vim.g.mcphub_status or "stopped"
                local executing = vim.g.mcphub_executing

                -- Show "-" when stopped
                if status == "stopped" then
                  return "󰐻 -"
                end

                -- Show spinner when executing, starting, or restarting
                if executing or status == "starting" or status == "restarting" then
                  local frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
                  local frame = math.floor(vim.loop.now() / 100) % #frames + 1
                  return "󰐻 " .. frames[frame]
                end

                return "󰐻 " .. count
              end,
              color = function()
                if not vim.g.loaded_mcphub then
                  return { fg = "#6c7086" } -- Gray for not loaded
                end

                local status = vim.g.mcphub_status or "stopped"
                if status == "ready" or status == "restarted" then
                  return { fg = "#50fa7b" } -- Green for connected
                elseif status == "starting" or status == "restarting" then
                  return { fg = "#ffb86c" } -- Orange for connecting
                else
                  return { fg = "#ff5555" } -- Red for error/stopped
                end
              end,
            },
          },
        },
      }
    end,
  },
}
