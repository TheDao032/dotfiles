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
    require('Comment').setup({
      -- nvim 0.12 + archived Comment.nvim: ft.calculate crashes ("[Comment.nvim] nil")
      -- when vim.treesitter.get_parser returns nil — i.e. any filetype with NO parser
      -- (e.g. `template` from *.tmpl/*.tftpl). Bypass the treesitter path ONLY for those
      -- parserless buffers (use their commentstring); parsered filetypes return nil and
      -- fall through to the normal ts-aware path (keeps jsx/tsx/markdown context-commenting).
      pre_hook = function()
        local ok, parser = pcall(vim.treesitter.get_parser, 0)
        if not ok or parser == nil then
          local cs = vim.bo.commentstring
          if cs and cs ~= '' then
            return cs
          end
        end
        return nil
      end,
    })

    -- Base commentstrings for #-comment filetypes. 'template' = *.tmpl / *.tftpl.
    local ft = require('Comment.ft')
    ft({ 'template', 'hcl', 'tf' }, '#%s')
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

packadd({
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  config = function()
    require('render-markdown').setup({
      completions = { lsp = { enabled = true } },
    })
  end,
  opts = {},
})

packadd({
  'rodjek/vim-puppet',
  ft = 'puppet', -- Optional: load only for puppet files
})

packadd({
  'nvim-flutter/flutter-tools.nvim',
  lazy = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'stevearc/dressing.nvim', -- optional for vim.ui.select
  },
  config = true,
})
