-- Disable render-markdown due to treesitter "Index out of bounds" errors
--
-- The plugin crashes when parsing certain markdown buffers, particularly
-- during rapid buffer updates. The root cause is stale treesitter nodes
-- that become out of sync with actual buffer content.
--
-- This can be re-enabled once the upstream plugin is fixed or when
-- a more robust workaround is available.

return {
  "MeanderingProgrammer/render-markdown.nvim",
  enabled = true,
}
