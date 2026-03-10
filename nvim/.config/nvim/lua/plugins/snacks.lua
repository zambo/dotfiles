---@class snacks.Config

-- Files and directories to ignore within snacks nvim context (grep, explorer, files)
local ignoreList = {
  ".git",
  "node_modules",
  ".cache",
  ".next",
  "dist",
  "^build",
  ".DS_Store",
  "thumbs.db",
  "storybook-static",
}

return {
  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      -- debug = true,
      dashboard = {
        preset = {
          header = [[
╻╺┳╸
┃ ┃ 
╹ ╹ 

██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗
██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝
██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗
██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║
╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║
 ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝

┏━┓┏┓╻ ┏┳┓╻ ╻
┃ ┃┃┗┫ ┃┃┃┗┳┛
┗━┛╹ ╹ ╹ ╹ ╹ 

███╗   ███╗ █████╗  ██████╗██╗  ██╗██╗███╗   ██╗███████╗ 
████╗ ████║██╔══██╗██╔════╝██║  ██║██║████╗  ██║██╔════╝ 
██╔████╔██║███████║██║     ███████║██║██╔██╗ ██║█████╗   
██║╚██╔╝██║██╔══██║██║     ██╔══██║██║██║╚██╗██║██╔══╝   
██║ ╚═╝ ██║██║  ██║╚██████╗██║  ██║██║██║ ╚████║███████╗ 
╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ 
]],
        },
      },
      picker = {
        actions = {
          sidekick_send = function(...)
            return require("sidekick.cli.picker.snacks").send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = {
                "sidekick_send",
                mode = { "n", "i" },
              },
            },
          },
        },
        sources = {
          explorer = {
            -- Show hidden and ignored files within the explorer picker
            hidden = true, -- show hidden files
            ignored = true, -- show ignored files
            exclude = ignoreList,
            -- NOTE: Custom preview behavior for explorer picker by drowning-cat
            -- https://github.com/folke/snacks.nvim/discussions/1306#discussioncomment-12248922
            on_show = function(picker)
              local show = false
              local gap = 1
              local clamp_width = function(value)
                return math.max(20, math.min(100, value))
              end
              --
              local position = picker.resolved_layout.layout.position
              local rel = picker.layout.root
              local update = function(win) ---@param win snacks.win
                local border = win:border_size().left + win:border_size().right
                win.opts.row = vim.api.nvim_win_get_position(rel.win)[1]
                win.opts.height = 0.8
                if position == "left" then
                  win.opts.col = vim.api.nvim_win_get_width(rel.win) + gap
                  win.opts.width = clamp_width(vim.o.columns - border - win.opts.col)
                end
                if position == "right" then
                  win.opts.col = -vim.api.nvim_win_get_width(rel.win) - gap
                  win.opts.width = clamp_width(vim.o.columns - border + win.opts.col)
                end
                win:update()
              end
              local preview_win = Snacks.win.new({
                relative = "editor",
                external = false,
                focusable = false,
                border = "rounded",
                backdrop = false,
                show = show,
                bo = {
                  filetype = "snacks_float_preview",
                  buftype = "nofile",
                  buflisted = false,
                  swapfile = false,
                  undofile = false,
                },
                on_win = function(win)
                  update(win)
                  picker:show_preview()
                end,
              })
              rel:on("WinLeave", function()
                vim.schedule(function()
                  if not picker:is_focused() then
                    picker.preview.win:close()
                  end
                end)
              end)
              rel:on("WinResized", function()
                update(preview_win)
              end)
              picker.preview.win = preview_win
              picker.main = preview_win.win
            end,
            on_close = function(picker)
              picker.preview.win:close()
            end,
            layout = {
              preset = "sidebar",
              preview = false, ---@diagnostic disable-line
            },
            actions = {
              -- `<A-p>`
              toggle_preview = function(picker) --[[Override]]
                picker.preview.win:toggle()
              end,
            },
          },
          files = {
            -- Show hidden and ignored files within the files picker
            hidden = true, -- show hidden files
            ignored = true, -- show ignored files
            exclude = ignoreList,
          },
          grep = {
            -- Show hidden and ignored files within the grep picker
            hidden = true, -- show hidden files
            ignored = true, -- show ignored files
            exclude = ignoreList,
          },
        },
      },
    },
  },
}
