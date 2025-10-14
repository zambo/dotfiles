return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      opts.debug = vim.uv.cwd():find("noice%.nvim")
      opts.debug = false
      opts.presets.lsp_doc_border = true
      opts.routes = opts.routes or {}
      table.insert(opts.routes, {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      })
      local focused = true
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          focused = true
        end,
      })
      vim.api.nvim_create_autocmd("FocusLost", {
        callback = function()
          focused = false
        end,
      })

      table.insert(opts.routes, 1, {
        filter = {
          ["not"] = {
            event = "lsp",
            kind = "progress",
          },
          cond = function()
            return not focused and false
          end,
        },
        view = "notify_send",
        opts = { stop = false, replace = true },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(event)
          vim.schedule(function()
            require("noice.text.markdown").keys(event.buf)
          end)
        end,
      })
      return opts
    end,
  },

  {
    "folke/which-key.nvim",
    enabled = true,
    opts = {
      preset = "helix",
      debug = vim.uv.cwd():find("which%-key"),
      win = {},
      spec = {},
    },
  },

  {
    "sphamba/smear-cursor.nvim",
    enabled = true,
    cond = not (vim.env.KITTY_PID or vim.g.neovide) and vim.fn.has("nvim-0.10") == 1,
  },

  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        -- mode = "tabsgcc",
      },
    },
  },

  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      ---@type table<string, {updated:number, total:number, enabled: boolean, status:string[]}>
      local mutagen = {}

      local function mutagen_status()
        local cwd = vim.uv.cwd() or "."
        mutagen[cwd] = mutagen[cwd]
          or {
            updated = 0,
            total = 0,
            enabled = vim.fs.find("mutagen.yml", { path = cwd, upward = true })[1] ~= nil,
            status = {},
          }
        local now = vim.uv.now() -- timestamp in milliseconds
        local refresh = mutagen[cwd].updated + 10000 < now
        if #mutagen[cwd].status > 0 then
          refresh = mutagen[cwd].updated + 1000 < now
        end
        if mutagen[cwd].enabled and refresh then
          ---@type {name:string, status:string, idle:boolean}[]
          local sessions = {}
          local lines = vim.fn.systemlist("mutagen project list")
          local status = {}
          local name = nil
          for _, line in ipairs(lines) do
            local n = line:match("^Name: (.*)")
            if n then
              name = n
            end
            local s = line:match("^Status: (.*)")
            if s then
              table.insert(sessions, {
                name = name,
                status = s,
                idle = s == "Watching for changes",
              })
            end
          end
          for _, session in ipairs(sessions) do
            if not session.idle then
              table.insert(status, session.name .. ": " .. session.status)
            end
          end
          mutagen[cwd].updated = now
          mutagen[cwd].total = #sessions
          mutagen[cwd].status = status
          if #sessions == 0 then
            vim.notify("Mutagen is not running", vim.log.levels.ERROR, { title = "Mutagen" })
          end
        end
        return mutagen[cwd]
      end

      local error_color = { fg = Snacks.util.color("DiagnosticError") }
      local ok_color = { fg = Snacks.util.color("DiagnosticInfo") }
      table.insert(opts.sections.lualine_x, {
        cond = function()
          return mutagen_status().enabled
        end,
        color = function()
          return (mutagen_status().total == 0 or mutagen_status().status[1]) and error_color or ok_color
        end,
        function()
          local s = mutagen_status()
          local msg = s.total
          if #s.status > 0 then
            msg = msg .. " | " .. table.concat(s.status, " | ")
          end
          return (s.total == 0 and "󰋘 " or "󰋙 ") .. msg
        end,
      })
    end,
  },
  {
    "snacks.nvim",
    opts = {
      picker = {
        -- Global defaults for all sources
        hidden = true,
        ignored = true,
        sources = {
          -- File-based pickers: show hidden/ignored but exclude heavy directories
          files = {
            hidden = true,
            ignored = true,
            exclude = {
              "node_modules",
              ".git",
              "dist",
              "build",
              "target",
              "__pycache__",
              ".next",
              ".nuxt",
              "vendor",
              ".venv",
              "venv",
            },
          },
          smart = {
            hidden = true,
            ignored = true,
            exclude = {
              "node_modules",
              ".git",
              "dist",
              "build",
              "target",
              "__pycache__",
              ".next",
              ".nuxt",
              "vendor",
              ".venv",
              "venv",
            },
          },
          git_files = {
            hidden = true,
            ignored = true,
          },
          recent = {
            hidden = true,
            ignored = true,
          },
          -- Search-based pickers: exclude heavy directories entirely
          grep = {
            hidden = true,
            ignored = true,
            exclude = {
              "node_modules",
              ".git",
              "dist",
              "build",
              "target",
              "__pycache__",
              ".next",
              ".nuxt",
              "vendor",
              ".venv",
              "venv",
              "*.log",
              "*.min.js",
              "*.min.css",
            },
          },
          grep_buffers = {
            hidden = true,
            ignored = true,
          },
          grep_word = {
            hidden = true,
            ignored = true,
            exclude = {
              "node_modules",
              ".git",
              "dist",
              "build",
              "target",
              "__pycache__",
              ".next",
              ".nuxt",
              "vendor",
              ".venv",
              "venv",
              "*.log",
              "*.min.js",
              "*.min.css",
            },
          },
          git_grep = {
            hidden = true,
            ignored = true,
            exclude = {
              "node_modules",
              "dist",
              "build",
              "target",
              "__pycache__",
              ".next",
              ".nuxt",
              "vendor",
              ".venv",
              "venv",
            },
          },
        },
      },
      explorer = {
        hidden = true,
        ignored = true,
        exclude = {
          ".DS_Store",
          "*.tmp",
          "*.swp",
          "*~",
        },
        filters = {
          -- Custom filters for explorer (more lenient than search)
          custom = {
            -- Only hide system/temp files, but show package dirs for navigation
            ".DS_Store",
            "*.tmp",
            "*.swp",
            "*~",
            "Thumbs.db",
          },
        },
      },
      dashboard = {
        preset = {
          pick = function(cmd, opts)
            return LazyVim.pick(cmd, opts)()
          end,
          header = [[                   ░▒▓███████▓▒░▒▓████████▓▒░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░                      
                  ░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░                      
                  ░▒▓█▓▒░         ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░                      
                   ░▒▓██████▓▒░   ░▒▓█▓▒░  ░▒▓████████▓▒░░▒▓██████▓▒░                       
                         ░▒▓█▓▒░  ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░                          
                         ░▒▓█▓▒░  ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░                          
                  ░▒▓███████▓▒░   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░  ░▒▓█▓▒░                          
                                                                                            
                                                                                            
░▒▓████████▓▒░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓███████▓▒░▒▓████████▓▒░▒▓███████▓▒░  
░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓██████▓▒░ ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░     ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓██████▓▒░ ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░  
                                                                                            
                                                                                            ]],

          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          -- keys = {
          --   { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          --   { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          --   { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          --   { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          --   { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          --   { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          --   { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
          --   { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          --   { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          -- },
        },
      },
    },
  },

  {
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    enabled = false,
    opts = {
      -- startVisible = true,
      -- showBlankVirtLine = true,
      -- highlightColor = { link = "Comment" },
      -- hints = {
      --      Caret = { text = "^", prio = 2 },
      --      Dollar = { text = "$", prio = 1 },
      --      MatchingPair = { text = "%", prio = 5 },
      --      Zero = { text = "0", prio = 1 },
      --      w = { text = "w", prio = 10 },
      --      b = { text = "b", prio = 9 },
      --      e = { text = "e", prio = 8 },
      --      W = { text = "W", prio = 7 },
      --      B = { text = "B", prio = 6 },
      --      E = { text = "E", prio = 5 },
      -- },
      -- gutterHints = {
      --     G = { text = "G", prio = 10 },
      --     gg = { text = "gg", prio = 9 },
      --     PrevParagraph = { text = "{", prio = 8 },
      --     NextParagraph = { text = "}", prio = 8 },
      -- },
      -- disabled_fts = {
      --     "startify",
      -- },
    },
  },
}
