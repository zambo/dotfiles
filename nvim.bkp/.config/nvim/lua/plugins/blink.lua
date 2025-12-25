return {
  "saghen/blink.cmp",
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {

    keymap = {
      -- Use Tab to jump to the next edit suggestion when using sidekick
      -- https://github.com/folke/sidekick.nvim#:~:text=sidekick%20after%20install.-,Integrate,-%3CTab%3E%20in
      ["<Tab>"] = {
        "snippet_forward",
        function() -- sidekick next edit suggestion
          return require("sidekick").nes_jump_or_apply()
        end,
        function() -- if you are using Neovim's native inline completions
          return vim.lsp.inline_completion.get()
        end,
        "fallback",
      },
    },
  },
}
