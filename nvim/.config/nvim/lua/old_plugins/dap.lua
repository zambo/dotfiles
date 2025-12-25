return {
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      
      local function get_js_debug_path()
        return vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
      end

      -- Node adapter for backend/API debugging
      if not dap.adapters["pwa-node"] then
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = 8123,
          executable = {
            command = "node",
            args = { get_js_debug_path(), "8123" },
          },
        }
      end

      -- Chrome adapter for frontend debugging
      if not dap.adapters["pwa-chrome"] then
        dap.adapters["pwa-chrome"] = {
          type = "server", 
          host = "localhost",
          port = 8124,
          executable = {
            command = "node",
            args = { get_js_debug_path(), "8124" },
          },
        }
      end

      -- TypeScript/JavaScript configurations
      for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
        dap.configurations[language] = {
          -- Debug current file with tsx
          {
            type = "pwa-node",
            request = "launch",
            name = "Run Current File (tsx)",
            program = "${file}",
            cwd = "${workspaceFolder}",
            runtimeExecutable = "tsx",
            sourceMaps = true,
            protocol = "inspector",
            console = "integratedTerminal",
          },
          -- Debug Next.js (dev server)
          {
            type = "pwa-node",
            request = "launch",
            name = "Next.js Dev",
            cwd = "${workspaceFolder}",
            runtimeExecutable = "npm",
            runtimeArgs = { "run", "dev" },
            sourceMaps = true,
            console = "integratedTerminal",
            serverReadyAction = {
              pattern = "ready on",
              uriFormat = "http://localhost:3000",
              action = "openExternally",
            },
          },
          -- Attach to running Node process
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Node Process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
          -- Debug in Chrome (asks for URL)
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Chrome (ask for URL)",
            url = function()
              local co = coroutine.running()
              return coroutine.create(function()
                vim.ui.input({ 
                  prompt = "Enter URL: ", 
                  default = "http://localhost:3000" 
                }, function(url)
                  if url == nil or url == "" then
                    return
                  else
                    coroutine.resume(co, url)
                  end
                end)
              end)
            end,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
            sourceMapPathOverrides = {
              ["webpack://_N_E/*"] = "${workspaceFolder}/*",  -- Next.js
              ["webpack:///*"] = "${workspaceFolder}/*",      -- Generic webpack
              ["webpack://?:*/*"] = "${workspaceFolder}/*",   -- Vite/other
            },
          },
        }
      end
    end,
  },
}
