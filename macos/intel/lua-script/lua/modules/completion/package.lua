local package = require('core.pack').package
local conf = require('modules.completion.config')

package({
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',
  dependencies = {
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-buffer' },
    { 'saadparwaiz1/cmp_luasnip' },
  },
  config = conf.nvim_cmp,
})

package({ 'L3MON4D3/LuaSnip', event = 'InsertCharPre', config = conf.lua_snip })

package({
  'jose-elias-alvarez/null-ls.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = conf.null_ls,
})

-- package({
--   'ray-x/go.nvim',
--   dependencies = { -- optional packages
--     'ray-x/guihua.lua',
--     'neovim/nvim-lspconfig',
--     'nvim-treesitter/nvim-treesitter',
--   },
--   config = function()
--     require('go').setup()
--   end,
--   event = { 'CmdlineEnter' },
--   ft = { 'go', 'gomod' },
--   build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
-- })

-- package({
--   'lewis6991/spellsitter.nvim',
--   config = conf.nvim_spellsitter,
-- })

package({
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  config = function()
    require('copilot').setup({})
  end,
})
