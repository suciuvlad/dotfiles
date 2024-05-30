-- Define the installation path for packer.nvim
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

-- Check if packer.nvim is already installed
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  -- If not, clone the packer.nvim repository from GitHub
  vim.fn.system({'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path})
  -- Add packer.nvim to the runtime path
  vim.cmd('packadd packer.nvim')
end

-- Require the packer module
local packer = require 'packer'

-- Initialize packer with specific configurations
packer.init {
  display = {
    open_fn = function()
      -- Use a floating window with rounded borders for displaying packer messages
      return require('packer.util').float { border = 'rounded' }
    end,
  },
  auto_clean = true,  -- Automatically clean unused plugins
  compile_on_sync = true,  -- Automatically compile packer whenever plugins are synced
}

-- Set up a custom handler for plugin configurations
packer.set_handler('config', function(_, plugin, value)
  -- If the config value is a string and the file exists, set the plugin configuration
  if type(value) == 'string' and vim.fn.filereadable(vim.fn.expand(value)) == 1 then
    plugin.config = "vim.cmd('source " .. value .. "')"
  end
end)

-- Define an autocommand group for auto-compiling packer on changes to plugins.lua
vim.cmd [[
  augroup packer_user_config
    autocmd!  -- Clear existing autocommands in the group
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile  -- Recompile packer on saving plugins.lua
  augroup end
]]

-- Return the packer instance
return packer