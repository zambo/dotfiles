return {
  "MeanderingProgrammer/render-markdown.nvim",
  enabled = true,
  opts = {
    -- LazyVim's markdown extra clears heading icons and disables checkboxes.
    heading = {
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    },
    checkbox = { enabled = true },
    pipe_table = { style = "full" },
    anti_conceal = { enabled = true },
  },
}
