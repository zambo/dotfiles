return {
  "editorconfig/editorconfig-vim",
  lazy = false, -- Or true if you prefer lazy-loading
  config = function()
    -- Optional: Add any specific EditorConfig settings here if needed
    vim.g.editorconfig_enable = true -- (EditorConfig plugin often works without this)
  end,
}
