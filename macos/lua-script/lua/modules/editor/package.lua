local package = require('core.pack').package
local conf = require('modules.editor.config')

package({
  'nvim-treesitter/nvim-treesitter',
  event = 'BufRead',
  run = ':TSUpdate',
  config = conf.nvim_treesitter,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
})

package({
  'numToStr/Comment.nvim',
  config = function()
    require('Comment').setup()

    local ft = require('Comment.ft')
    ft.set('hcl', {'#%s', '/*%s*/'})
  end,
})

package({
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
