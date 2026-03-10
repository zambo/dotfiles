-- Set to true to disable the plugin. Useful for testing configs with different lua files.
local DISABLE_PLUGIN = true
-- E.g.: codecompanion-minimal.lua
if DISABLE_PLUGIN then
  return {}
end

return {
  "folke/sidekick.nvim",
  ---@module 'sidekick'
  ---@type sidekick.Config
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "tmux",
        enabled = true,
        create = "terminal",
        split = {
          vertical = true, -- vertical or horizontal split
          size = 0.5, -- size of the split (0-1 for percentage)
        },
      },
      win = {
        layout = "float", -- float, split, tab
      },
    },
    tools = {
      opencode = {
        cmd = { "opencode" },
        -- HACK: https://github.com/sst/opencode/issues/445
        env = { OPENCODE_THEME = "system" },
      },
    },
    ---@type table<string, sidekick.context.Fn>
    context = {},
  },
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end

        -- if you are using Neovim's native inline completions
        if vim.lsp.inline_completion.get() then
          return
        end

        -- any other things (like snippets) you want to do on <tab> go here.

        -- fall back to normal tab
        return "<tab>"
      end,
      mode = { "i", "n" },
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
    },
    {
      "<c-.>",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>aa",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    -- Example of a keybinding to open Claude directly
    {
      "<leader>ac",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
  },
}
