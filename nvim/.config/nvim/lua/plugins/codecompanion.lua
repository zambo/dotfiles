-- Fuel iX API integration for CodeCompanion

-- Set to true to disable the plugin. Useful for testing configs with different lua files.
-- E.g.: codecompanion-minimal.lua
if false then
  return {}
end

-- This is my setup for using Fuel iX as an OpenAI-compatible API provider.
-- It dynamically fetches available models and caches them locally to avoid
-- hitting the API on every Neovim startup.

-- ============================================================================
-- Configuration
-- ============================================================================

local FUELIX_API_URL = "https://proxy.fuelix.ai/v1"
local CACHE_FILE = vim.fn.stdpath("cache") .. "/fuelix_models.json"
local CACHE_DURATION = 24 * 60 * 60 -- 24 hours - models don't change that often

-- Model Configuration - single source of truth for model names
local MODELS = {
  GPT_4O = "gpt-4o",
  GPT_4O_MINI = "gpt-4o-mini",
  GPT_4_1 = "gpt-4-1",
  GPT_5_2 = "gpt-5-2",
  HAIKU = "claude-haiku-4-5",
  SONNET = "claude-sonnet-4-5",
}

-- Debug mode - set FUELIX_DEBUG=1 to enable diagnostic logging
local DEBUG = os.getenv("FUELIX_DEBUG") == "0"

-- I use 1Password's new environments feature to mount the API key as an env var
-- See: https://developer.1password.com/docs/environments/
-- Alternative: op read 'op://Private/Fuel iX API Key/credential' --no-newline
-- See: https://developer.1password.com/docs/cli/secret-references
local FUELIX_API_KEY = os.getenv("FUEL_IX_API_KEY")

-- Fallback models in case the API is down or unreachable
local FALLBACK_MODELS = {
  [MODELS.GPT_4O] = { display = MODELS.GPT_4O },
  [MODELS.GPT_4O_MINI] = { display = MODELS.GPT_4O_MINI },
  [MODELS.GPT_4_1] = { display = MODELS.GPT_4_1 },
  [MODELS.GPT_5_2] = { display = MODELS.GPT_5_2 },
  [MODELS.HAIKU] = { display = MODELS.HAIKU },
  [MODELS.SONNET] = { display = MODELS.SONNET },
}

-- ============================================================================
-- Utility Functions
-- ============================================================================
-- Simple file I/O helpers - could extract these to a shared utility module
-- but keeping them here for simplicity and portability

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*all")
  f:close()
  return content
end

local function write_file(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w")
  if f then
    f:write(content)
    f:close()
  end
end

-- Debug logging helper - only outputs when FUELIX_DEBUG=1
local function log_debug(msg)
  if DEBUG then
    vim.notify("[Fuel iX Debug] " .. msg, vim.log.levels.DEBUG)
  end
end

-- Makes an authenticated request to the Fuel iX models API
-- Returns: response object from plenary.curl with { status, body } or nil on error
local function make_fuelix_api_request()
  local curl = require("plenary.curl")
  return curl.get({
    url = FUELIX_API_URL .. "/models",
    timeout = 5000,
    headers = { ["Authorization"] = "Bearer " .. FUELIX_API_KEY },
  })
end

-- ============================================================================
-- Model Management
-- ============================================================================

-- Fetches Fuel iX models from cache or API
-- This runs on startup but uses the cache to avoid slowing things down
-- Returns: { [model_id] = { display = "model_name" } }
local function get_fuel_ix_models()
  local stat = vim.loop.fs_stat(CACHE_FILE)

  -- Use cached models if they're fresh enough
  if stat and (os.time() - stat.mtime.sec) < CACHE_DURATION then
    local content = read_file(CACHE_FILE)
    if content then
      local ok, data = pcall(vim.json.decode, content)
      if ok and data then
        log_debug("Using cached models")
        return data
      end
    end
  end

  -- Cache is stale or missing, fetch from API
  -- Using synchronous request here, there were some issues with async
  log_debug("Fetching models from API")
  local res = make_fuelix_api_request()

  if res.status == 200 then
    local ok, data = pcall(vim.json.decode, res.body)
    if ok and data and data.data then
      local models = {}
      for _, info in ipairs(data.data) do
        models[info.id] = { display = info.id }
      end
      write_file(CACHE_FILE, vim.json.encode(models))
      log_debug(string.format("Cached %d models from API", #data.data))
      return models
    end
  end

  -- Something went wrong - fall back to known good models
  log_debug(string.format("API request failed with status %d, using fallback models", res.status))
  return FALLBACK_MODELS
end

-- Clears the model cache, forcing a fresh API fetch on next access
-- Useful when Fuel iX adds new models or I want to force a refresh
local function refetch_fuel_ix_models()
  vim.loop.fs_unlink(CACHE_FILE)
  vim.notify("Fuel iX model cache cleared. Models will be re-fetched on next use.", vim.log.levels.INFO)
end

-- ============================================================================
-- Health Check
-- ============================================================================

-- Performs a basic health check against the Fuel iX API
-- Validates:
--  1. API key presence
--  2. Network connectivity
--  3. Model list endpoint responsiveness
--
-- Returns:
--   { ok = boolean, message = string, details = table }
local function fuel_ix_health_check()
  local details = {
    api_key = { ok = false, msg = "" },
    connectivity = { ok = false, msg = "" },
    models = { ok = false, msg = "" },
    cache = { ok = true, msg = "" },
  }

  -- Check 1: API key is configured
  if not FUELIX_API_KEY or FUELIX_API_KEY == "" or FUELIX_API_KEY == "your_api_key_here" then
    details.api_key.msg = "API key not set"
    return {
      ok = false,
      message = "❌ Health check failed: FUEL_IX_API_KEY is not configured",
      details = details,
    }
  end
  details.api_key.ok = true
  details.api_key.msg = "Configured (" .. FUELIX_API_KEY:sub(1, 8) .. "...)"

  -- Check cache status
  local stat = vim.loop.fs_stat(CACHE_FILE)
  if stat then
    local age_hours = math.floor((os.time() - stat.mtime.sec) / 3600)
    local is_fresh = (os.time() - stat.mtime.sec) < CACHE_DURATION
    details.cache.msg = string.format("%s (%dh old)", is_fresh and "Fresh" or "Stale", age_hours)
  else
    details.cache.msg = "No cache file"
  end

  -- Check 2: API connectivity
  local res = make_fuelix_api_request()
  if res.status ~= 200 then
    details.connectivity.msg = string.format("HTTP %s", res.status)
    return {
      ok = false,
      message = string.format("❌ Health check failed: API returned status %d", res.status),
      details = details,
    }
  end
  details.connectivity.ok = true
  details.connectivity.msg = "Connected"

  -- Check 3: Models can be fetched and parsed
  local ok, decoded = pcall(vim.json.decode, res.body)
  if not ok or type(decoded) ~= "table" or type(decoded.data) ~= "table" then
    details.models.msg = "Invalid response format"
    return {
      ok = false,
      message = "❌ Health check failed: Could not parse API response",
      details = details,
    }
  end

  local model_count = #decoded.data
  details.models.ok = true
  details.models.msg = string.format("%d models available", model_count)

  return {
    ok = true,
    message = string.format("✓ Fuel iX healthy: %d models available", model_count),
    details = details,
  }
end

-- Displays health check results via vim.notify
local function display_health_check_result(result)
  local lines = { "Fuel iX Health Check", "====================", "" }
  for check, info in pairs(result.details) do
    local icon = info.ok and "✓" or "❌"
    table.insert(lines, string.format("%s %s: %s", icon, check:upper(), info.msg))
  end
  table.insert(lines, "")
  table.insert(lines, result.message)

  local msg = table.concat(lines, "\n")
  local level = result.ok and vim.log.levels.INFO or vim.log.levels.ERROR
  vim.notify(msg, level)
end

-- ============================================================================
-- Plugin Configuration
-- ============================================================================

return {
  {
    ---@type CodeCompanion
    "olimorris/codecompanion.nvim",
    enabled = true,

    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/codecompanion-history.nvim",
      "ravitemer/mcphub.nvim",
      "franco-ruggeri/codecompanion-spinner.nvim",
    },

    opts = {
      -- ──────────────────────────────────────────────────────────────────
      -- Interactions
      -- ──────────────────────────────────────────────────────────────────
      interactions = {
        chat = {
          -- I prefer Sonnet for chat, but simply change the default as needed
          adapter = { name = "fuel_ix", model = MODELS.SONNET },
          variables = {
            ["buffer"] = {
              opts = {
                -- Only share diffs by default to save on tokens
                default_params = "diff",
              },
            },
          },
          opts = {
            completion_provider = "blink",
          },
        },

        inline = {
          -- Haiku for inline edits - faster and cheaper for quick changes
          adapter = { name = "fuel_ix", model = MODELS.HAIKU },
          keymaps = {
            accept_change = {
              modes = { n = "ga" },
              description = "Accept the suggested change",
            },
            reject_change = {
              modes = { n = "gr" },
              opts = { nowait = true },
              description = "Reject the suggested change",
            },
          },
        },

        cmd = {
          -- Also use Haiku for commands - quick responses are key here
          adapter = { name = "fuel_ix", model = MODELS.HAIKU },
          opts = {
            completion_provider = "blink",
          },
        },

        background = {
          chat = {
            callbacks = {
              ["on_ready"] = {
                actions = { "interactions.background.builtin.chat_make_title" },
                enabled = true,
              },
            },
            opts = {
              enabled = true,
            },
          },
        },
      },

      rules = {
        opts = {
          chat = {
            autoload = false,
          },
        },
      },

      -- ──────────────────────────────────────────────────────────────────
      -- Custom Actions
      -- ──────────────────────────────────────────────────────────────────
      actions = {
        {
          name = "Refetch Fuel iX Models",
          desc = "Clear cache and fetch latest models from Fuel iX API",
          callback = function()
            refetch_fuel_ix_models()
          end,
        },
        {
          name = "Fuel iX Health Check",
          desc = "Validate API key and connectivity to Fuel iX",
          callback = function()
            display_health_check_result(fuel_ix_health_check())
          end,
        },
      },

      -- ──────────────────────────────────────────────────────────────────
      -- Display
      -- ──────────────────────────────────────────────────────────────────
      display = {
        action_palette = {
          enabled = true,
        },
        chat = {
          enabled = true,
          auto_scroll = false, -- I prefer manual control over scrolling
          -- show_settings = true,
        },
        inline = {
          enabled = true,
          -- layout = "vertical", -- Works better with my split layout
          diff = {
            enabled = true,
            keymap = {
              accept = "<Leader>ai", -- Accept inline suggestion
              reject = "<Leader>ar", -- Reject inline suggestion
            },
          },
        },
      },

      -- ──────────────────────────────────────────────────────────────────
      -- Adapters
      -- ──────────────────────────────────────────────────────────────────
      adapters = {

        -- ACP (AI Coding Partner) adapter for opencode CLI
        -- I sometimes use this for terminal-based workflows
        acp = {
          opencode = function()
            return require("codecompanion.adapters").extend("opencode", {
              commands = {
                default = { "opencode", "acp" },
                fuel_ix_sonnet_4_5 = { "opencode", "acp", "-m", "fuel_ix/" .. MODELS.SONNET },
                fuel_ix_haiku_4_5 = { "opencode", "acp", "-m", "fuel_ix/" .. MODELS.HAIKU },
                fuel_ix_gpt_4_1 = { "opencode", "acp", "-m", "fuel_ix/" .. MODELS.GPT_4_1 },
                fuel_ix_gpt_5_2 = { "opencode", "acp", "-m", "fuel_ix/" .. MODELS.GPT_5_2 },
              },
            })
          end,
        },

        -- HTTP adapter for Fuel iX API
        -- This is the main adapter I use for all CodeCompanion interactions
        http = {
          fuel_ix = function()
            local openai = require("codecompanion.adapters.http.openai")
            return {
              name = "fuel_ix",
              formatted_name = "Fuel iX",
              roles = {
                llm = "assistant",
                user = "user",
              },

              opts = {
                -- NOTE: Streaming caveats:
                -- 1. Not all models support streaming
                -- 2. May conflict with nvim markdown plugins (render-markdown, marksman etc.)
                stream = true,
                -- Vision support is experimental - not all models support images
                vision = true,
              },
              features = {
                text = true,
                tokens = true,
              },

              url = FUELIX_API_URL .. "/chat/completions",

              headers = {
                ["Authorization"] = "Bearer " .. FUELIX_API_KEY,
                ["Content-Type"] = "application/json",
              },

              handlers = {
                setup = function(self)
                  if self.opts and self.opts.stream then
                    self.parameters.stream = true
                  end
                  return true
                end,

                -- Fuel iX uses an OpenAI-compatible API, so we just delegate everything
                -- to the built-in OpenAI adapter handlers
                tokens = function(self, data)
                  return openai.handlers.tokens(self, data)
                end,
                form_parameters = function(self, params, messages)
                  return openai.handlers.form_parameters(self, params, messages)
                end,
                form_messages = function(self, messages)
                  return openai.handlers.form_messages(self, messages)
                end,
                chat_output = function(self, data, context)
                  return openai.handlers.chat_output(self, data, context)
                end,
                inline_output = function(self, data, context)
                  return openai.handlers.inline_output(self, data, context)
                end,
                on_exit = function(self, data)
                  return openai.handlers.on_exit(self, data)
                end,
              },

              schema = {
                model = {
                  order = 1,
                  mapping = "parameters",
                  type = "enum",
                  desc = "Model to use for completions",
                  default = MODELS.SONNET,
                  -- This dynamically fetches available models from Fuel iX
                  -- Falls back to hardcoded list if the API is unreachable
                  choices = function()
                    return get_fuel_ix_models()
                  end,
                },
              },
            }
          end,
        },
      },

      -- ──────────────────────────────────────────────────────────────────
      -- Prompt Library
      -- ──────────────────────────────────────────────────────────────────
       prompt_library = {
         markdown = {
           dirs = {
             -- I keep my custom prompts in my nvim config as markdown files
             -- See: https://codecompanion.olimorris.dev/configuration/prompt-library
             "~/.config/nvim/prompts",
           },
         },
         mapping = {
           -- Use Haiku for commit message generation - smaller model for focused task
           ["commit-message"] = {
             adapter = { name = "fuel_ix", model = MODELS.HAIKU },
           },
         },
       },

      -- ──────────────────────────────────────────────────────────────────
      -- Extensions
      -- ──────────────────────────────────────────────────────────────────
      extensions = {
        -- See: https://github.com/topics/codecompanion
        spinner = {},

        history = {
          enabled = true,
          opts = {
            keymap = "<Leader>ah", -- Access history
            save_chat_keymap = "<Leader>as", -- Save current chat
            auto_save = true,
            expiration_days = 15, -- Never expire - I like keeping all my chats
            picker = "snacks", -- Using snacks.nvim for the picker UI
            auto_generate_title = true, -- Disabled - I prefer manual titles
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            enable_logging = false,
          },
        },

        mcphub = {
          enabled = true,
          callback = "mcphub.extensions.codecompanion",
          opts = {
            -- I have MCP installed but not using these features yet
            -- Keeping them disabled for now to avoid any unexpected behavior
            make_tools = true,
            show_server_tools_in_chat = true,
            add_mcp_prefix_to_tool_names = true,
            show_result_in_chat = true,
            format_tool = "markdown",
            make_vars = true,
            make_slash_commands = true,
          },
        },
      },
    },

    -- Register user commands after plugin loads
    config = function(_, opts)
      require("codecompanion").setup(opts)

      -- Command to run health check
      vim.api.nvim_create_user_command("FuelIxHealth", function()
        display_health_check_result(fuel_ix_health_check())
      end, {
        desc = "Run Fuel iX health check",
      })

      -- Command to refetch models
      vim.api.nvim_create_user_command("FuelIxRefetch", function()
        refetch_fuel_ix_models()
      end, {
        desc = "Refetch Fuel iX models",
      })
    end,
  },
}
