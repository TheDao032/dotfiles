local package = require('core.pack').package
local conf = require('modules.lsp.config')

package({
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'ray-x/lsp_signature.nvim' },
  },
  config = conf.nvim_lsp,
})

package({
  'jose-elias-alvarez/null-ls.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = conf.null_ls,
})
