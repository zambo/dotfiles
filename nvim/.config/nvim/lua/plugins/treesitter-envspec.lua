-- Tree-sitter grammar for @env-spec dotenv superset format.
--
-- Grammar source: <nvim_config>/tree-sitter-envspec/
--
-- Regenerate parser.c after grammar.js changes (needs tree-sitter-cli):
--   cd ~/.config/nvim/tree-sitter-envspec && tree-sitter generate
--   then :TSInstall envspec
--
-- Iterate on highlights without recompiling:
--   edit tree-sitter-envspec/queries/envspec/highlights.scm, then :e

-- ─── Filetype detection ───────────────────────────────────────────────────────
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
      local dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"

      -- Add grammar dir to runtimepath so queries/envspec/*.scm is found.
      -- prepend so it wins over any other envspec queries.
      if vim.fn.isdirectory(dir) == 1 then
        vim.opt.runtimepath:prepend(dir)
      end

      -- Register the language mapping early — before any FileType autocmd fires.
      -- Without this, LazyVim's FileType handler doesn't know envspec has a parser.
      vim.treesitter.language.register("envspec", "envspec")
    end,

    opts = function(_, opts)
      local dir = vim.fn.stdpath("config") .. "/tree-sitter-envspec"

      -- Register install info so :TSInstall envspec works.
      require("nvim-treesitter.parsers").envspec = {
        install_info = {
          url = dir,
          files = { "src/parser.c" },
          generate_requires_npm = false,
          requires_generate_from_grammar = false,
        },
        filetype = "envspec",
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "envspec" })
    end,
  },

  -- ─── Kick highlighting on already-open envspec buffers ───────────────────
  -- nvim-treesitter's FileType autocmd only runs for buffers opened after the
  -- plugin loads. If the user opened an .env* file first (triggering LazyFile),
  -- we re-fire treesitter highlighting once everything is settled.
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].filetype == "envspec" and vim.api.nvim_buf_is_loaded(buf) then
              pcall(vim.treesitter.start, buf, "envspec")
            end
          end
        end,
      })
    end,
  },

  -- ─── mini.hipatterns — decorator name highlighting ───────────────────────
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
