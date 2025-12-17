return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      snippets = {
        preset = "luasnip",
      },
    },
  },
  -- Configure LuaSnip to load Lua-format snippets
  {
    "L3MON4D3/LuaSnip",
    optional = true,
    config = function()
      -- Load Lua snippets from lua/snippets/
      require("luasnip.loaders.from_lua").lazy_load({ paths = { vim.fn.stdpath("config") .. "/lua/snippets" } })
    end,
  },
}
