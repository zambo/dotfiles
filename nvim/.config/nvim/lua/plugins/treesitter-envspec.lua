-- Registers the tree-sitter-envspec parser and wires up .env* filetype detection.
--
-- The grammar lives at:
--   <nvim_config>/tree-sitter-envspec/
-- (i.e. the tree-sitter-envspec/ directory next to this file's lua/ parent)
--
-- To regenerate parser.c after grammar.js changes (requires tree-sitter-cli):
--   cd <nvim_config>/tree-sitter-envspec && tree-sitter generate
-- Then inside Neovim: :TSInstall envspec  (or :TSUpdate envspec)
--
-- To iterate on highlights.scm without recompiling:
--   Edit tree-sitter-envspec/queries/envspec/highlights.scm, then :e to see changes.

-- ─── Filetype detection ───────────────────────────────────────────────────────
-- Must run at startup (init) so filetype is set before any buffer opens.
-- We use priority = math.huge to override LazyVim/Neovim built-in "env" filetype.
vim.filetype.add({
  -- Exact filename ".env"
  filename = {
    [".env"] = "envspec",
  },
  -- Glob patterns for .env variants, with high priority to override built-in "env"
  pattern = {
    -- .env.local, .env.production, .env.schema (dotfile with extension)
    ["%.env%..*"] = { "envspec", { priority = math.huge } },
    -- /path/to/.env (ends with /.env — the trailing dot-env file)
    [".*/%.env$"] = { "envspec", { priority = math.huge } },
    -- foo.env, api.env (not a dotfile, but ends with .env)
    [".+%.env$"] = { "envspec", { priority = math.huge } },
    -- api.env.schema, foo.env.local
    [".+%.env%..*"] = { "envspec", { priority = math.huge } },
  },
})

return {
  -- ─── Tree-sitter parser registration ────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Grammar lives inside the Neovim config directory, next to lua/.
      local grammar_dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"

      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.envspec = {
        install_info = {
          url = grammar_dir,
          files = { "src/parser.c" },
          -- parser.c is pre-generated and committed; no build step needed.
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = "envspec",
      }

      -- Add "envspec" to the list of parsers nvim-treesitter ensures are installed.
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "envspec" })
    end,

    config = function(_, opts)
      -- Add the grammar dir to runtimepath so Neovim finds queries/envspec/*.scm.
      local grammar_dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"
      if vim.fn.isdirectory(grammar_dir) == 1 then
        vim.opt.runtimepath:append(grammar_dir)
      end

      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- ─── Decorator name highlighting (mini.hipatterns) ────────────────────────
  -- Since decorator_comment is an opaque terminal token in the CST, tree-sitter
  -- cannot capture sub-parts like @name as separate nodes. We use mini.hipatterns
  -- to highlight decorator names with @attribute coloring inside envspec buffers.
  {
    "echasnovski/mini.hipatterns",
    optional = true,
    opts = function(_, opts)
      opts.highlighters = opts.highlighters or {}

      -- Highlight @decoratorName within decorator comment lines.
      -- Applies only in envspec buffers.
      opts.highlighters.envspec_decorator = {
        -- Match @ followed by a valid decorator name (letter then alphanumeric/underscore)
        pattern = function(buf)
          if vim.bo[buf].filetype ~= "envspec" then
            return nil
          end
          -- Match @name at start of decorator (after # and optional space)
          return "@[a-zA-Z][a-zA-Z0-9_]*"
        end,
        group = "@attribute",
      }

      -- Highlight decorator values after = sign within decorator lines.
      -- e.g. @type=string → highlight "string" differently
      opts.highlighters.envspec_decorator_value = {
        pattern = function(buf)
          if vim.bo[buf].filetype ~= "envspec" then
            return nil
          end
          -- Match =value after a decorator name (non-greedy up to next space or #)
          return "@[a-zA-Z][a-zA-Z0-9_]*%f[=]=[^ \t#]+"
        end,
        group = "@constant",
      }

      return opts
    end,
  },
}
