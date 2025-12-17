-- Fuel iX model fetching and caching
--
-- TODOs:
-- - [ ] Add filtering
-- - [ ] Maybe something with regex, regardless of model version
-- - [ ] Add expiration to cache
-- - [ ] Add error handling/logging
-- - [ ] Add command to manually refetch models
-- - [ ] Add option to disable caching
-- - [ ] Add option to set cache duration
-- - [ ] Add option to set custom API key per user
-- - [ ] Add unit tests (if possible)
-- - [ ] Document the code
-- - [ ] Consider async fetching with a loading state
-- - [ ] Not sure if this is posisble wiht codecompanion schema though
-- - [ ] Consider using plenary's async http instead of sync

-- API endpoint for fetching Fuel iX models
local FUELIX_API = "https://api.fuelix.ai/v1/models"

-- Path to cache file for storing model list
-- So we don't have to fetch it every time and can speed up things
local CACHE_FILE = vim.fn.stdpath("cache") .. "/fuelix_models.json"

-- Fallback model list if fetching or cache fails
local FALLBACK_MODELS = {
  ["gpt-4o"] = { display = "gpt-4o" },
  ["gpt-4o-mini"] = { display = "gpt-4o-mini" },
  ["claude-sonnet-4-5"] = { display = "claude-sonnet-4-5" },
  ["claude-haiku-4-5"] = { display = "claude-haiku-4-5" },
}

-- Get API key from environment variable or other secure storage
-- 1password CLI example:
-- op read 'op://Personal/Fuel iX - API Key/API Key' --
-- Optionally, but not recommended, set it here directly
local FUELIX_API_KEY = os.getenv("FUEL_IX_API_KEY") or ""

-- Helper to read entire contents of a file
local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

-- Helper to load prompts from markdown files in a directory
local function load_prompts(dir)
  local prompts = {}
  local files = vim.fn.globpath(dir, "*.md", false, true)
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r") -- filename without extension
    local f = io.open(file, "r")
    if f then
      prompts[name] = f:read("*all")
      f:close()
    end
  end
  return prompts
end

-- Load prompts from the specified directory
-- For usage, call the function with the filename. Example: prompt_texts["commit"]
local prompt_texts = load_prompts(vim.fn.stdpath("config") .. "/lua/prompts")

-- Helper to write contents to a file, creating parent directories if needed
local function write_file(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if f then
    f:write(content)
    f:close()
  end
end

-- Fetch Fuel iX models, using cache if available and fresh, otherwise fetch from API
local function get_fuel_ix_models()
  local cache_duration = 24 * 60 * 60 -- 24 hours
  local stat = vim.loop.fs_stat(CACHE_FILE)
  if stat and (os.time() - stat.mtime.sec) < cache_duration then
    local content = read_file(CACHE_FILE)
    if content then
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        return data
      end
    end
  end

  -- Fetch fresh models synchronously from API
  local curl = require("plenary.curl")
  local res = curl.get({
    url = FUELIX_API,
    timeout = 5000,
    headers = { ["Authorization"] = "Bearer " .. FUELIX_API_KEY },
  })

  if res.status == 200 then
    local ok, data = pcall(vim.json.decode, res.body)
    if ok and data and data.data then
      local models = {}
      for _, info in ipairs(data.data) do
        models[info.id] = { display = info.id }
      end
      write_file(CACHE_FILE, vim.json.encode(models))
      return models
    end
  end

  -- Return fallback models if cache and API both fail
  return FALLBACK_MODELS
end

-- Clear the cached model list, forcing a refetch on next access
local function refetch_fuel_ix_models()
  vim.loop.fs_unlink(CACHE_FILE)
  vim.notify("Fuel iX model cache cleared. Next access will refetch models.", vim.log.levels.INFO)
end

return {
  {
    "olimorris/codecompanion.nvim",
    enabled = true, -- Re-enabled: wasn't the issue

    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter", -- DISABLED - might be parsing markdown and causing crash
      "ravitemer/codecompanion-history.nvim", -- DISABLED - causing crash
    },
    opts = {
      -- NOTE: The log_level is in `opts.opts`
      opts = {
        log_level = "ERROR", -- Reduced from DEBUG to prevent excessive logging
        send_code = true, -- Disable auto-send
      },
      -- Disable prompt rendering which may cause issues
      display = {
        action_palette = {
          enabled = false,
        },
        chat = {
          enabled = false, -- Disable chat rendering
        },
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
                  choices = function()
                    return get_fuel_ix_models()
                  end,
                },
              },
            }
          end,
        },
      },

      prompt_library = {
        -- markdown = {
        --   dirs = {
        --     vim.fn.stdpath("config") .. "/lua/prompts",
        --   },
        -- },

        markdown = {
          dirs = {
            vim.fn.getcwd() .. "../prompts", -- Can be relative
          },
        },

        -- ["Generate a Commit Message"] = {
        --   strategy = "chat",
        --   description = "Generate a commit message",
        --   opts = { index = 10, is_default = true, is_slash_cmd = true, short_name = "commit", auto_submit = true },
        --   prompts = {
        --     {
        --       role = "system",
        --       content = prompt_texts["commit"],
        --       tools = {
        --         { name = "get_changed_files", params = { source_control_state = { "staged" } } },
        --       },
        --     },
        --     {
        --       role = "user",
        --       content = "@{get_changed_files}",
        --       opts = { contains_code = true },
        --     },
        --   },
        -- },

        -- {},
      },
      extensions = {
        history = {
          enabled = true, -- DISABLED to prevent crash
          opts = {
            keymap = "<Leader>ah",
            save_chat_keymap = "<Leader>as",
            auto_save = true,
            expiration_days = 0,
            picker = "snacks",
            auto_generate_title = false, -- DISABLED
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            enable_logging = false,
          },
        },
        mcphub = {
          enabled = true, -- DISABLED to prevent crash
          callback = "mcphub.extensions.codecompanion",
          opts = {
            -- MCP Tools
            make_tools = false, -- DISABLED
            show_server_tools_in_chat = false,
            add_mcp_prefix_to_tool_names = false,
            show_result_in_chat = true,
            format_tool = nil,
            -- MCP Resources
            make_vars = false, -- DISABLED
            -- MCP Prompts
            make_slash_commands = false, -- DISABLED
          },
        },
      },
    },
  },
}
