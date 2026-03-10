return {
  {
    "neovim/nvim-lspconfig",

    opts = function(_, opts)
      -- Extend existing servers instead of replacing
      opts.servers = opts.servers or {}
      opts.servers.copilot = {
        enabled = true,
      }

      -- Disable autoformat for eslint
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "eslint" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })

      return opts
    end,
  },
}
