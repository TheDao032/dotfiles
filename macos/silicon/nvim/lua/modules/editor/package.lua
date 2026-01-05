local conf = require('modules.editor.config')

packadd({
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = conf.telescope,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzy-native.nvim',
    'nvim-telescope/telescope-dap.nvim',
  },
})

packadd({
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = conf.nvim_treesitter,
})

--@see https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/507
-- packadd({
--   'nvim-treesitter/nvim-treesitter-textobjects',
--   ft = { 'c', 'rust', 'go', 'lua' },
--   dependencies = {
--     'nvim-treesitter/nvim-treesitter',
--   },
--   config = conf.nvim_treesitter_textobjects,
-- })

packadd({
  'numToStr/Comment.nvim',
  config = function()
    require('Comment').setup()

    local ft = require('Comment.ft')
    ft({ 'tftpl', 'tmpl', 'hcl', 'tf' }, '#%s')
  end,
})

packadd({
  'folke/which-key.nvim',
  event = 'VeryLazy',
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
})
