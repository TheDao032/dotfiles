local package = require('core.pack').package
local conf = require('modules.tools.config')

package({
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = conf.telescope,
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-telescope/telescope-fzy-native.nvim' },
    { 'nvim-telescope/telescope-dap.nvim' },
  },
})

package({
  'glepnir/hlsearch.nvim',
  event = 'BufRead',
  config = function()
    require('hlsearch').setup()
  end,
})

package({
  'mfussenegger/nvim-dap',
  config = conf.nvim_dap,
  dependencies = {
    { 'theHamsta/nvim-dap-virtual-text' },
    { 'jay-babu/mason-nvim-dap.nvim' },
  },
})

package({
  'rcarriga/nvim-dap-ui',
  dependencies = {
    'mfussenegger/nvim-dap',
    'nvim-neotest/nvim-nio',
    'folke/neodev.nvim',
  },
  config = function()
    require('dapui').setup()
  end,
})

package({
  'folke/neodev.nvim',
  config = function()
    require('neodev').setup({
      library = { plugins = { 'nvim-dap-ui' } },
    })
  end,
})

package({
  'akinsho/toggleterm.nvim',
  version = '*',
  opts = { --[[ things you want to change go here]]
  },
  config = conf.toggle_term,
})

-- package({
--   "cbochs/grapple.nvim",
--   dependencies = { "nvim-lua/plenary.nvim" },
-- })
