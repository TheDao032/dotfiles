local conf = require('modules.tools.config')

packadd({
  'nvimdev/flybuf.nvim',
  cmd = 'FlyBuf',
  config = function()
    require('flybuf').setup({})
  end,
})

packadd({
  'glepnir/template.nvim',
  cmd = { 'Template', 'TemProject' },
  config = conf.template_nvim,
})

packadd({
  'nvimdev/guard.nvim',
  ft = { 'c', 'cpp', 'rust', 'lua', 'go', 'typescript', 'javascript', 'javascriptreact', 'markdown', 'terraform', 'hcl', 'puppet' },
  config = conf.guard,
  dependencies = {
    { 'nvimdev/guard-collection' },
  },
})

packadd({
  'catgoose/nvim-colorizer.lua',
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
  'luarocks/hererocks',
  build = 'rockspec',
  lazy = true,
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
    { 'folke/lazydev.nvim', ft = 'lua', opts = { library = { 'nvim-dap-ui' } } },
  },
  config = function()
    require('dapui').setup()
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

-- packadd({
--   'Exafunction/codeium.nvim',
--   event = 'BufEnter */*',
--   config = function()
--     require('codeium').setup()
--   end,
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'hrsh7th/nvim-cmp',
--   },
-- })

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

-- packadd({
--   'jose-elias-alvarez/null-ls.nvim',
--   config = conf.nvim_null_ls,
--   dependencies = { 'nvim-lua/plenary.nvim' },
-- })

-- packadd({
--   '3rd/diagram.nvim',
--   dependencies = {
--     { '3rd/image.nvim', opts = {} }, -- you'd probably want to configure image.nvim manually instead of doing this
--   },
--   opts = { -- you can just pass {}, defaults below
--     events = {
--       render_buffer = { 'InsertLeave', 'BufWinEnter', 'TextChanged' },
--       clear_buffer = { 'BufLeave' },
--     },
--     renderer_options = {
--       mermaid = { theme = 'forest' },
--       plantuml = {},
--     },
--   },
--
--   config = conf.nvim_diagram,
-- })

-- packadd({
--   'stevearc/conform.nvim',
--   opts = {},
--   config = conf.nvim_conform,
-- })
