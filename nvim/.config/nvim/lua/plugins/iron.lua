return {
  "Vigemus/iron.nvim",
  lazy = false,
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    local common = require("iron.fts.common")

    iron.setup({
      config = {
        scratch_repl = true,
        repl_definition = {
          python = {
            -- If the buffer lives inside a uv-managed project (pyproject.toml
            -- or uv.lock found walking up from the file), launch ipython
            -- through `uv run` so the REPL sees the project's venv/deps
            -- instead of whatever `ipython` happens to be first on $PATH.
            -- Falls back to plain global ipython outside uv projects.
            --
            -- iron.nvim never exposes termopen's `cwd` option, so the REPL
            -- job otherwise inherits nvim's own cwd rather than the
            -- notebook's directory. Real Jupyter always starts the kernel
            -- with cwd = the directory containing the .ipynb file, which is
            -- what relative paths in notebooks (e.g. `../.env`) are written
            -- to assume. We replicate that here by `cd`-ing into the
            -- buffer's directory in a wrapping shell before exec'ing
            -- ipython.
            command = function(meta)
              -- iron.nvim calls this `command` function from two different
              -- code paths with two different (inconsistently named) meta
              -- shapes: lowlevel.lua uses `current_bufnr` when actually
              -- launching the REPL job, while common.lua's
              -- bracketed_paste_python re-invokes it with `current_buffer`
              -- just to inspect the resolved command for formatting
              -- decisions. Accept either, falling back to the current
              -- buffer so neither call path errors.
              local bufnr = meta.current_bufnr or meta.current_buffer or vim.api.nvim_get_current_buf()
              local bufname = vim.api.nvim_buf_get_name(bufnr)
              local dir = vim.fs.dirname(bufname) or vim.fn.getcwd()
              local found = vim.fs.find({ "uv.lock", "pyproject.toml" }, { path = dir, upward = true })[1]

              local inner
              if found then
                inner = "exec uv run --with ipython ipython --no-autoindent"
              else
                inner = "exec ipython --no-autoindent"
              end

              return { "sh", "-c", string.format("cd %s && %s", vim.fn.shellescape(dir), inner) }
            end,
            format = common.bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
          },
        },
        repl_filetype = function(_, ft)
          return ft
        end,
        -- Window the REPL opens in. Split direction/size left uncommented
        -- below to experiment with later (float, horizontal, different size).
        -- repl_open_cmd = view.split.vertical.rightbelow("40%"),
        repl_open_cmd = view.split.vertical.rightbelow("50%"),
        -- repl_open_cmd = view.bottom(15),
        -- repl_open_cmd = view.center(0.6),
      },
      keymaps = {
        toggle_repl = "<leader>rr",
        restart_repl = "<leader>rR",
        send_motion = "<leader>rc",
        visual_send = "<leader>rv",
        send_file = "<leader>rf",
        send_line = "<leader>rl",
        send_paragraph = "<leader>rp",
        send_until_cursor = "<leader>ru",
        send_mark = "<leader>rm",
        send_code_block = "<leader>rb",
        send_code_block_and_move = "<leader>rn",
        mark_motion = "<leader>ra",
        mark_visual = "<leader>ra",
        remove_mark = "<leader>rd",
        cr = "<leader>r<cr>",
        interrupt = "<leader>r<space>",
        exit = "<leader>rq",
        clear = "<leader>rC",
      },
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true,
    })

    vim.keymap.set("n", "<leader>rF", "<cmd>IronFocus<cr>", { desc = "Focus REPL" })
    vim.keymap.set("n", "<leader>rh", "<cmd>IronHide<cr>", { desc = "Hide REPL" })
  end,
}
