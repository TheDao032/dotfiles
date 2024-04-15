local package = require('core.pack').package
local conf = require('modules.ui.config')

-- package({ 'ellisonleao/gruvbox.nvim', config = conf.gruvbox })
-- package({ 'glepnir/dashboard-nvim', config = conf.dashboard_gruvbox })

-- package({ 'nvim-lualine/lualine.nvim', config = conf.lualine })

-- package({
--   'nvim-tree/nvim-web-devicons',
--   config = conf.nvim_web_devicons,
-- })

-- package({
--   'glepnir/zephyr-nvim',
--   config = conf.zephyr,
--   dependencies = { 'nvim-treesitter/nvim-treesitter' },
-- })

package({
  'nvimdev/nightsky.vim',
  config = function()
    vim.cmd.colorscheme('nightsky')
  end,
})

package({
  'nvimdev/dashboard-nvim',
  event = 'UIEnter',
  config = conf.dashboard,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

package({
  'nvimdev/whiskyline.nvim',
  event = 'BufEnter',
  config = conf.whisky,
})

-- package({
--   'glepnir/dashboard-nvim',
--   config = conf.dashboard_zephyr,
--   dependencies = { 'nvim-tree/nvim-web-devicons' },
-- })

-- package({
--   'yamatsum/nvim-nonicons',
--   config = conf.nvim_nonicons,
--   dependencies = { 'nvim-tree/nvim-web-devicons' },
-- })

package({
  'nvim-tree/nvim-tree.lua',
  cmd = 'NvimTreeToggle',
  config = conf.nvim_tree,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

package({
  'akinsho/nvim-bufferline.lua',
  config = conf.nvim_bufferline,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

package({
  'glepnir/galaxyline.nvim',
  config = conf.galaxyline,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

local enable_indent_filetype = {
  'go',
  'lua',
  'sh',
  'rust',
  'cpp',
  'typescript',
  'typescriptreact',
  'javascript',
  'json',
  'python',
}

package({
  'lukas-reineke/indent-blankline.nvim',
  main = 'ibl',
  opts = {},
  ft = enable_indent_filetype,
  config = conf.indent_blankline,
})

package({
  'lewis6991/gitsigns.nvim',
  event = { 'BufRead', 'BufNewFile' },
  config = conf.gitsigns,
})

package({
  'ray-x/navigator.lua',
  dependencies = {
    { 'ray-x/guihua.lua',               run = 'cd lua/fzy && make' },
    { 'neovim/nvim-lspconfig' },
    { 'nvim-treesitter/nvim-treesitter' },
  },
  config = function()
    require('navigator').setup({
      lsp = {
        format_on_save = false,
        diagnostic = {
          virtual_text = false,
        },
      },
    })
  end,
})
