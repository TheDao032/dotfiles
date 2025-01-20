local conf = require('modules.lsp.config')

packadd({
  'nvim-java/nvim-java',
  config = conf.nvim_java,
  opts = {
    registries = {
      'github:nvim-java/mason-registry',
      'github:mason-org/mason-registry',
    },
  },
  dependencies = { 'williamboman/mason-lspconfig.nvim' },
})

packadd({
  'neovim/nvim-lspconfig',
  ft = vim.g.my_program_ft,
  config = function()
    local i = '■'
    vim.diagnostic.config({ signs = { text = { i, i, i, i } } })
    -- require('nvim-lsp-installer').setup({
    --   automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
    --   ui = {
    --     icons = {
    --       server_installed = '✓',
    --       server_pending = '➜',
    --       server_uninstalled = '✗',
    --     },
    --   },
    -- })
    require('modules.lsp.backend')
    require('modules.lsp.frontend')
  end,
  dependencies = { 'hrsh7th/nvim-cmp' },
})

packadd({
  'nvimdev/lspsaga.nvim',
  event = 'LspAttach',
  dev = false,
  config = function()
    require('lspsaga').setup({
      symbol_in_winbar = {
        hide_keyword = true,
        folder_level = 0,
      },
      lightbulb = {
        sign = false,
      },
      outline = {
        layout = 'float',
      },
    })
  end,
})

-- packadd({
--   'nvimdev/epo.nvim',
--   event = 'LspAttach',
--   dev = false,
--   config = function()
--     vim.opt.completeopt = 'menu,menuone,noselect,popup'
--     -- require('epo').setup()
--     require('epo').setup({
--       -- fuzzy match
--       fuzzy = false,
--       -- increase this value can aviod trigger complete when delete character.
--       debounce = 50,
--       -- when completion confrim auto show a signature help floating window.
--       signature = false,
--       -- border for lsp signature popup, :h nvim_open_win
--       signature_border = 'rounded',
--       -- lsp kind formatting, k is kind string "Field", "Struct", "Keyword" etc.
--       kind_format = function(k)
--         return k:lower():sub(1, 1)
--       end,
--     })
--   end,
-- })
