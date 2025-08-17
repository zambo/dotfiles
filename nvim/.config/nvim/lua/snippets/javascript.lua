-- This file will be automatically loaded by LazyVim's LuaSnip configuration
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  s(
    "tw-jsonpre",
    fmt(
      [[<pre className='bg-yellow-50 text-yellow-950 border border-yellow-200 p-8 my-8'>{{JSON.stringify({}, null, 2)}}</pre>{}]],
      {
        i(1, "object"),
        i(0),
      }
    )
  ),
}
