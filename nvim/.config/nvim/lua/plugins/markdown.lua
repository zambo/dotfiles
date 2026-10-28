-- LazyVim's markdown extra runs markdownlint-cli2 twice: through nvim-lint and
-- through none-ls. Keep the none-ls one, since the extra's on-save
-- `markdownlint-cli2 --fix` formatter only runs while it has diagnostics.
return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters_by_ft = {
      markdown = {},
    },
  },
}
