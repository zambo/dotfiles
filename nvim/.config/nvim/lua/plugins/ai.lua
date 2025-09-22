-- local anthropic = require("codecompanion.adapters.http.anthropic")

-- Model fetching and caching from models.dev
local function get_claude_models()
  local cache_file = vim.fn.stdpath("cache") .. "/claude_models.json"
  local cache_duration = 24 * 60 * 60 -- 24 hours

  -- Check cache
  local stat = vim.loop.fs_stat(cache_file)
  if stat and (os.time() - stat.mtime.sec) < cache_duration then
    local f = io.open(cache_file, "r")
    if f then
      local content = f:read("*all")
      f:close()
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        return data
      end
    end
  end

  -- Fetch fresh models
  local curl = require("plenary.curl")
  local res = curl.get({
    url = "https://models.dev/api.json",
    timeout = 5000,
    headers = { ["User-Agent"] = "Neovim/CodeCompanion" },
  })

  if res.status == 200 then
    local ok, data = pcall(vim.json.decode, res.body)
    if ok and data.anthropic and data.anthropic.models then
      -- Transform models
      local models = {}
      for id, info in pairs(data.anthropic.models) do
        models[id] = {
          display = info.name or id,
          opts = {
            has_vision = info.attachment or false,
            max_tokens = info.limit and info.limit.output or 4096,
          },
        }
      end

      -- Cache it
      vim.fn.mkdir(vim.fn.fnamemodify(cache_file, ":h"), "p")
      local f = io.open(cache_file, "w")
      if f then
        f:write(vim.json.encode(models))
        f:close()
      end

      return models
    end
  end

  -- Fallback
  return {
    ["claude-3-5-sonnet-20241022"] = { display = "Claude 3.5 Sonnet" },
    ["claude-3-5-haiku-20241022"] = { display = "Claude 3.5 Haiku" },
    ["claude-3-opus-20240229"] = { display = "Claude 3 Opus" },
  }
end

-- Debug wrapper to log model usage
local function create_debug_adapter(base_adapter)
  local adapter = base_adapter

  -- Wrap the setup handler to add debugging
  local original_setup = adapter.handlers and adapter.handlers.setup
  if not adapter.handlers then
    adapter.handlers = {}
  end

  adapter.handlers.setup = function(self, ...)
    -- Log the model being used
    vim.notify(string.format("[CodeCompanion] Model: %s", self.schema.model.default), vim.log.levels.INFO)

    if original_setup then
      return original_setup(self, ...)
    end
    return true
  end

  return adapter
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
    "Davidyz/VectorCode",
    version = "*", -- optional, depending on whether you're on nightly or release
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "VectorCode", -- if you're lazy-loading VectorCode
  },
  {
    dir = "~/Development/ai-nvim/anthropic.nvim",
    name = "anthropic.nvim",
    dev = true,
    enabled = false,
    config = function()
      require("anthropic_auth").setup({ -- Changed from "anthropic" to "anthropic_auth"
        auth_method = "auto",
        auto_refresh = true,
        debug = true,
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
        ["claude-oauth"] = function()
          local utils = require("codecompanion.utils.adapters")
          local tokens = require("codecompanion.utils.tokens")

          return require("codecompanion.adapters").extend("anthropic", {
            env = { bearer_token = "CLAUDE_CODE_OAUTH_TOKEN" },
            headers = {
              ["content-type"] = "application/json",
              ["authorization"] = "Bearer ${bearer_token}",
              ["anthropic-version"] = "2023-06-01",
              ["anthropic-beta"] = "claude-code-20250219,oauth-2025-04-20,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14",
            },
            schema = {
              model = {
                default = "claude-opus-4-1-20250805",
                choices = {
                  ["claude-opus-4-1-20250805"] = { display = "Claude Opus 4.1" },
                  ["claude-opus-4-20250514"] = { display = "Claude Opus 4" },
                  ["claude-sonnet-4-20250514"] = { display = "Claude Sonnet 4" },
                  ["claude-3-7-sonnet-20250219"] = { display = "Claude 3.7 Sonnet" },
                  ["claude-3-5-sonnet-20241022"] = { display = "Claude 3.5 Sonnet" },
                  ["claude-3-5-haiku-20241022"] = { display = "Claude 3.5 Haiku" },
                  ["claude-3-opus-20240229"] = { display = "Claude 3 Opus" },
                },
              },
            },
            handlers = {
              setup = function(self)
                if self.headers and self.headers["x-api-key"] then
                  self.headers["x-api-key"] = nil
                end

                if self.opts and self.opts.stream then
                  self.parameters.stream = true
                end

                return true
              end,

              form_messages = function(self, messages)
                local has_tools = false

                -- Extract system messages
                local system = vim
                  .iter(messages)
                  :filter(function(msg)
                    return msg.role == "system"
                  end)
                  :map(function(msg)
                    return {
                      type = "text",
                      text = msg.content,
                      cache_control = nil,
                    }
                  end)
                  :totable()

                -- CRITICAL: Add Claude Code system message FIRST
                table.insert(system, 1, {
                  type = "text",
                  text = "You are Claude Code, Anthropic's official CLI for Claude.",
                  cache_control = { type = "ephemeral" },
                })

                -- Process non-system messages
                messages = vim
                  .iter(messages)
                  :filter(function(msg)
                    return msg.role ~= "system"
                  end)
                  :totable()

                -- Convert messages to Anthropic format
                messages = vim.tbl_map(function(message)
                  -- Handle images
                  if message.opts and message.opts.tag == "image" and message.opts.mimetype then
                    if self.opts and self.opts.vision then
                      message.content = {
                        {
                          type = "image",
                          source = {
                            type = "base64",
                            media_type = message.opts.mimetype,
                            data = message.content,
                          },
                        },
                      }
                    else
                      return nil
                    end
                  end

                  -- Filter out unwanted fields
                  message = filter_out_messages({
                    message = message,
                    allowed_words = { "content", "role", "reasoning", "tool_calls" },
                  })

                  -- Convert string content to proper format
                  if message.role == self.roles.user or message.role == self.roles.llm then
                    if message.role == self.roles.user and message.content == "" then
                      message.content = "<prompt></prompt>"
                    end

                    if type(message.content) == "string" then
                      message.content = {
                        { type = "text", text = message.content },
                      }
                    end
                  end

                  -- Handle tools
                  if message.tool_calls and vim.tbl_count(message.tool_calls) > 0 then
                    has_tools = true
                  end

                  if message.role == "tool" then
                    message.role = self.roles.user
                  end

                  if has_tools and message.role == self.roles.llm and message.tool_calls then
                    message.content = message.content or {}
                    for _, call in ipairs(message.tool_calls) do
                      table.insert(message.content, {
                        type = "tool_use",
                        id = call.id,
                        name = call["function"].name,
                        input = vim.json.decode(call["function"].arguments),
                      })
                    end
                    message.tool_calls = nil
                  end

                  return message
                end, messages)

                messages = utils.merge_messages(messages)

                -- Add cache control for performance
                local breakpoints_used = 0
                for i = #messages, 1, -1 do
                  local msgs = messages[i]
                  if msgs.role == self.roles.user then
                    for _, msg in ipairs(msgs.content or {}) do
                      if msg.type == "text" and msg.text ~= "" then
                        if
                          tokens.calculate(msg.text) >= (self.opts.cache_over or 300)
                          and breakpoints_used < (self.opts.cache_breakpoints or 4)
                        then
                          msg.cache_control = { type = "ephemeral" }
                          breakpoints_used = breakpoints_used + 1
                        end
                      end
                    end
                  end
                end

                return {
                  system = next(system) and system or nil,
                  messages = messages,
                }
              end,
            },
          })
        end,
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
      },
      prompt_library = {

        ["Generate a Commit Message"] = {
          strategy = "chat",
          description = "Generate a commit message",
          opts = { index = 10, is_default = true, is_slash_cmd = true, short_name = "commit", auto_submit = true },
          prompts = {
            {
              role = "system",
              content = [[
Generate a Conventional Commit message from the staged diff. First line ≤ 72 chars; include a clear body with rationale and breaking-change note if applicable.

Instructions:
- Output ONLY the commit message, wrapped in a markdown code block with language `gitcommit`.
- Do NOT include the diff or any explanation in your output.
- Do NOT include image links or raw URLs in the commit message.
- If there is nothing to commit, reply with: Nothing to commit.
- Always close the code block.
]],
              tools = {
                { name = "get_changed_files", params = { source_control_state = { "staged" } } },
              },
            },
            {
              role = "user",
              content = "@{get_changed_files} \n\n List staged files",
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
          opts = {
            -- MCP Tools
            make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
            show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
            add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
            show_result_in_chat = true, -- Show tool results directly in chat buffer
            format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffe
            -- MCP Resources
            make_vars = true, -- Convert MCP resources to #variables for prompts
            -- MCP Prompts
            make_slash_commands = true, -- Add MCP prompts as /slash commands
          },
        },
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
        vectorcode = {
          opts = {}, -- https://github.com/Davidyz/VectorCode/blob/main/docs/neovim/README.md#tools
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
    opts = function(opts)
      return {
        tabline = {
          -- lualine_y = {
          --   {
          --     function()
          --       return require("vectorcode.integrations").lualine(opts)[1]()
          --     end,
          --     cond = function()
          --       if package.loaded["vectorcode"] == nil then
          --         return false
          --       else
          --         return require("vectorcode.integrations").lualine(opts).cond()
          --       end
          --     end,
          --   },
          -- },
        },
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
