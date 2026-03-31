-- Tree-sitter grammar for @env-spec dotenv superset format.
--
-- Grammar source lives at:
--   <nvim_config>/tree-sitter-envspec/
--
-- To regenerate parser.c after grammar.js changes (requires tree-sitter-cli):
--   cd ~/.config/nvim/tree-sitter-envspec && tree-sitter generate
-- Then: :TSInstall envspec  (or :TSUpdate envspec)
--
-- To iterate on highlights without recompiling:
--   Edit tree-sitter-envspec/queries/envspec/highlights.scm, then :e

-- ─── Filetype detection ───────────────────────────────────────────────────────
-- Run at module load time (top-level), before any plugin init.
vim.filetype.add({
  filename = {
    [".env"] = "envspec",
  },
  pattern = {
    ["%.env%..*"] = { "envspec", { priority = math.huge } },
    [".*/%.env$"] = { "envspec", { priority = math.huge } },
    [".+%.env$"] = { "envspec", { priority = math.huge } },
    [".+%.env%..*"] = { "envspec", { priority = math.huge } },
  },
})

return {
  -- ─── nvim-treesitter ─────────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      -- Add grammar dir to runtimepath early so queries/envspec/*.scm is found.
      local dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"
      if vim.fn.isdirectory(dir) == 1 then
        vim.opt.runtimepath:prepend(dir)
      end
    end,
    opts = function(_, opts)
      local dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"

      -- Register the parser entry so :TSInstall envspec knows where to find it.
      require("nvim-treesitter.parsers").envspec = {
        install_info = {
          url = dir,
          files = { "src/parser.c" },
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = "envspec",
      }

      -- Tell Neovim core that the "envspec" filetype uses the "envspec" parser.
      vim.treesitter.language.register("envspec", "envspec")

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "envspec" })
    end,
  },

  -- ─── mini.hipatterns — decorator name highlighting ───────────────────────
  -- decorator_comment is an opaque token so tree-sitter can't capture @name
  -- sub-parts. mini.hipatterns fills the gap for envspec buffers only.
  {
    "echasnovski/mini.hipatterns",
    optional = true,
    opts = function(_, opts)
      opts.highlighters = opts.highlighters or {}

      opts.highlighters.envspec_decorator = {
        pattern = function(buf)
          if vim.bo[buf].filetype ~= "envspec" then
            return nil
          end
          return "@[a-zA-Z][a-zA-Z0-9_]*"
        end,
        group = "@attribute",
      }

      opts.highlighters.envspec_decorator_value = {
        pattern = function(buf)
          if vim.bo[buf].filetype ~= "envspec" then
            return nil
          end
          return "@[a-zA-Z][a-zA-Z0-9_]*%f[=]=[^ \t#]+"
        end,
        group = "@constant",
      }

      return opts
    end,
  },
}
