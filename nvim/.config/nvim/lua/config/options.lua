-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable the option to require a Prettier config file
-- If no prettier config file is found, the formatter will not be used
vim.g.lazyvim_prettier_needs_config = true

-- "vim.opt.exrc = true" >> ~/.config/nvim/lua/config/options.lua
-- vim.opt.exrc = true

-- Add this to disable autoformat temporarily for debugging
-- vim.g.autoformat = true -- Make sure this is true

-- If you have any ESLint autoformat settings, disable them
-- vim.g.lazyvim_eslint_auto_format = false
