local conf = require('modules.tools.config')

packadd({
  'nvimdev/flybuf.nvim',
  cmd = 'FlyBuf',
  config = function()
    require('flybuf').setup({})
  end,
})

packadd({
  'nvimdev/template.nvim',
  dev = true,
  cmd = 'Template',
  config = conf.template_nvim,
})

packadd({
  'nvimdev/guard.nvim',
  ft = { 'c', 'cpp', 'rust', 'lua', 'go', 'typescript', 'javascript', 'javascriptreact' },
  config = conf.guard,
  dependencies = {
    { 'nvimdev/guard-collection' },
  },
})

packadd({
  'norcalli/nvim-colorizer.lua',
  ft = { 'css', 'html', 'sass', 'less', 'typescriptreact', 'conf', 'vim' },
  config = function()
    vim.opt.termguicolors = true
    require('colorizer').setup()
  end,
})

packadd({
  'nvimdev/hlsearch.nvim',
  event = 'BufRead',
  config = true,
})

packadd({
  'nvimdev/dbsession.nvim',
  cmd = { 'SessionSave', 'SessionLoad', 'SessionDelete' },
  opts = true,
})

packadd({
  'mfussenegger/nvim-dap',
  config = conf.nvim_dap,
  dependencies = {
    { 'williamboman/mason.nvim' },
    { 'theHamsta/nvim-dap-virtual-text' },
    { 'jay-babu/mason-nvim-dap.nvim' },
  },
})

packadd({
  'rcarriga/nvim-dap-ui',
  dependencies = {
    { 'mfussenegger/nvim-dap' },
    { 'nvim-neotest/nvim-nio' },
    { 'folke/neodev.nvim' },
  },
  config = function()
    require('dapui').setup()
  end,
})

packadd({
  'folke/neodev.nvim',
  config = function()
    require('neodev').setup({
      library = { plugins = { 'nvim-dap-ui' } },
    })
  end,
})

packadd({
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = { --[[ things you want to change go here]]
  },
  config = conf.toggle_term,
})

-- packadd({
--   'zbirenbaum/copilot.lua',
--   cmd = 'Copilot',
--   event = 'InsertEnter',
--   config = function()
--     require('copilot').setup()
--   end,
-- })

packadd({
  'Exafunction/codeium.nvim',
  event = 'BufEnter */*',
  config = function()
    require('codeium').setup()
  end,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'hrsh7th/nvim-cmp',
  },
})

packadd({
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
  },
  config = conf.nvim_cmp,
})

packadd({
  'L3MON4D3/LuaSnip',
  -- follow latest release.
  version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  -- install jsregexp (optional!).
  build = 'make install_jsregexp',
})
