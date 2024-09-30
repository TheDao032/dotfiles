local conf = require('modules.ui.config')

-- packadd({
--   'nvimdev/nightsky.vim',
--   config = function()
--     vim.cmd.colorscheme('nightsky')
--   end,
-- })

packadd({
  'ellisonleao/gruvbox.nvim',
  config = function()
    vim.cmd.colorscheme('gruvbox')
  end,
})

packadd({
  'nvimdev/dashboard-nvim',
  event = 'UIEnter',
  config = conf.dashboard,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

-- packadd({
--   'nvimdev/modeline.nvim',
--   event = 'BufEnter */*',
--   config = conf.modeline,
-- })

packadd({
  'lewis6991/gitsigns.nvim',
  event = 'BufEnter */*',
  config = conf.gitsigns,
})

packadd({
  'nvimdev/indentmini.nvim',
  event = 'BufEnter */*',
  config = function()
    require('indentmini').setup()
  end,
})

packadd({
  'nvim-tree/nvim-tree.lua',
  cmd = 'NvimTreeToggle',
  config = conf.nvim_tree,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})
