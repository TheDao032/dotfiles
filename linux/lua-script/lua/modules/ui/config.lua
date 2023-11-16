local config = {}

function config.gruvbox()
  vim.cmd.colorscheme('gruvbox')
end

function config.zephyr()
  vim.cmd.colorscheme('zephyr')
end

function config.galaxyline()
  require('modules.ui.eviline')
end

function config.lualine()
  require('lualine').setup({
    options = {
      icons_enabled = true,
      theme = 'auto',
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch' },
      lualine_c = { 'filename' },
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
  })
end

function config.dashboard_zephyr()
  local db = require('dashboard')
  local z = require('zephyr')
  db.session_directory = vim.env.HOME .. '/.cache/nvim/session'
  db.preview_command = 'cat | lolcat -F 0.3'
  db.preview_file_path = vim.env.HOME .. '/.config/nvim/static/neovim.cat'
  db.preview_file_height = 11
  db.preview_file_width = 70
  db.custom_center = {
    {
      icon = '  ',
      icon_hl = { fg = z.red },
      desc = 'Update Plugins                          ',
      shortcut = 'SPC p u',
      action = 'Lazy update',
    },
    {
      icon = '  ',
      icon_hl = { fg = z.yellow },
      desc = 'Recently opened files                   ',
      action = 'Telescope oldfiles',
      shortcut = 'SPC f h',
    },
    {
      icon = '  ',
      icon_hl = { fg = z.cyan },
      desc = 'Find  File                              ',
      action = 'Telescope find_files find_command=rg,--hidden,--files',
      shortcut = 'SPC f f',
    },
    {
      icon = '  ',
      icon_hl = { fg = z.blue },
      desc = 'File Browser                            ',
      action = 'Telescope file_browser',
      shortcut = 'SPC   e',
    },
    {
      icon = '  ',
      icon_hl = { fg = z.oragne },
      desc = 'Find  word                              ',
      action = 'Telescope live_grep',
      shortcut = 'SPC f b',
    },
    {
      icon = '  ',
      icon_hl = { fg = z.redwine },
      desc = 'Open Personal dotfiles                  ',
      action = 'Telescope dotfiles path=' .. vim.env.HOME .. '/.dotfiles',
      shortcut = 'SPC f d',
    },
  }
  db.setup({
    theme = 'hyper',
    config = {
      week_header = {
        enable = true,
      },
      shortcut = {
        { desc = ' Update', group = '@property', action = 'Lazy update', key = 'u' },
        {
          desc = ' Files',
          group = 'Label',
          action = 'Telescope find_files',
          key = 'f',
        },
        {
          desc = ' Apps',
          group = 'DiagnosticHint',
          action = 'Telescope app',
          key = 'a',
        },
        {
          desc = ' dotfiles',
          group = 'Number',
          action = 'Telescope dotfiles',
          key = 'd',
        },
      },
    },
  })
end

function config.dashboard_gruvbox()
  local db = require('dashboard')
  local g = require('gruvbox')
  require('gruvbox').setup({
    undercurl = true,
    underline = true,
    bold = true,
    italic = true,
    strikethrough = true,
    invert_selection = false,
    invert_signs = false,
    invert_tabline = false,
    invert_intend_guides = false,
    inverse = true, -- invert background for search, diffs, statuslines and errors
    contrast = '',  -- can be "hard", "soft" or empty string
    palette_overrides = {},
    overrides = {},
    dim_inactive = false,
    transparent_mode = false,
  })
  db.session_directory = vim.env.HOME .. '/.cache/nvim/session'
  db.preview_command = 'cat | lolcat -F 0.3'
  db.preview_file_path = vim.env.HOME .. '/.config/nvim/static/neovim.cat'
  db.preview_file_height = 11
  db.preview_file_width = 70
  db.custom_center = {
    {
      icon = '  ',
      icon_hl = { fg = g.red },
      desc = 'Update Plugins                          ',
      shortcut = 'SPC p u',
      action = 'Lazy update',
    },
    {
      icon = '  ',
      icon_hl = { fg = g.yellow },
      desc = 'Recently opened files                   ',
      action = 'Telescope oldfiles',
      shortcut = 'SPC f h',
    },
    {
      icon = '  ',
      icon_hl = { fg = g.cyan },
      desc = 'Find  File                              ',
      action = 'Telescope find_files find_command=rg,--hidden,--files',
      shortcut = 'SPC f f',
    },
    {
      icon = '  ',
      icon_hl = { fg = g.blue },
      desc = 'File Browser                            ',
      action = 'Telescope file_browser',
      shortcut = 'SPC   e',
    },
    {
      icon = '  ',
      icon_hl = { fg = g.oragne },
      desc = 'Find  word                              ',
      action = 'Telescope live_grep',
      shortcut = 'SPC f b',
    },
    {
      icon = '  ',
      icon_hl = { fg = g.redwine },
      desc = 'Open Personal dotfiles                  ',
      action = 'Telescope dotfiles path=' .. vim.env.HOME .. '/.dotfiles',
      shortcut = 'SPC f d',
    },
  }
  db.setup({
    theme = 'hyper',
    config = {
      week_header = {
        enable = true,
      },
      shortcut = {
        { desc = ' Update', group = '@property', action = 'Lazy update', key = 'u' },
        {
          desc = ' Files',
          group = 'Label',
          action = 'Telescope find_files',
          key = 'f',
        },
        {
          desc = ' Apps',
          group = 'DiagnosticHint',
          action = 'Telescope app',
          key = 'a',
        },
        {
          desc = ' dotfiles',
          group = 'Number',
          action = 'Telescope dotfiles',
          key = 'd',
        },
      },
    },
  })
end

function config.gitsigns()
  require('gitsigns').setup({
    signs = {
      add = { hl = 'GitGutterAdd', text = '▍' },
      change = { hl = 'GitGutterChange', text = '▍' },
      delete = { hl = 'GitGutterDelete', text = '▍' },
      topdelete = { hl = 'GitGutterDeleteChange', text = '▔' },
      changedelete = { hl = 'GitGutterChange', text = '▍' },
      untracked = { hl = 'GitGutterAdd', text = '▍' },
    },

    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          return ']c'
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return '<Ignore>'
      end, { expr = true })

      map('n', '[c', function()
        if vim.wo.diff then
          return '[c'
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return '<Ignore>'
      end, { expr = true })

      -- Actions
      map('n', '<space>hs', gs.stage_hunk, { noremap = true, desc = 'Gitsigns: Stage Hunk' })
      map('n', '<space>hr', gs.reset_hunk, { noremap = true, desc = 'Gitsigns: Reset Hunk' })
      map('v', '<space>hs', function()
        gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { noremap = true, desc = 'Gitsigns: Stage Hunk Line' })
      map('v', '<space>hr', function()
        gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { noremap = true, desc = 'Gitsigns: Reset Hunk Line' })
      map('n', '<space>hS', gs.stage_buffer, { noremap = true, desc = 'Gitsigns: Stage Buffer' })
      map('n', '<space>hu', gs.undo_stage_hunk, { noremap = true, desc = 'Gitsigns: Undo Stage Hunk' })
      map('n', '<space>hR', gs.reset_buffer, { noremap = true, desc = 'Gitsigns: Reset Buffer' })
      map('n', '<space>hp', gs.preview_hunk, { noremap = true, desc = 'Gitsigns: Preview Hunk' })
      map('n', '<space>hb', function()
        gs.blame_line({ full = true })
      end, { noremap = true, desc = 'Gitsigns: Blame Line' })
      map(
        'n',
        '<space>tb',
        gs.toggle_current_line_blame,
        { noremap = true, desc = 'Gitsigns: Toggle Current Line Blame' }
      )
      map('n', '<space>hd', gs.diffthis, { noremap = true, desc = 'Gitsigns: Diffthis' })
      map('n', '<space>hD', function()
        gs.diffthis('~')
      end, { noremap = true, desc = 'Gitsigns: Diffthis ~' })
      map('n', '<space>td', gs.toggle_deleted, { noremap = true, desc = 'Gitsigns: Toggle Deleted' })

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
    end,
    -- keymaps = {
    --   -- Default keymap options
    --   noremap = true,
    --   buffer = true,
    --
    --   ['n ]g'] = { expr = true, "&diff ? ']g' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'" },
    --   ['n [g'] = { expr = true, "&diff ? '[g' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'" },
    --
    --   ['n <Leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
    --   ['n <Leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
    --   ['n <Leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
    --   ['n <Leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
    --   ['n <Leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>',
    --
    --   -- Text objects
    --   ['o ih'] = ':<C-U>lua require"gitsigns".text_object()<CR>',
    --   ['x ih'] = ':<C-U>lua require"gitsigns".text_object()<CR>',
    -- },
  })
end

function config.indent_blankline()
  require('ibl').setup()
end

function config.nvim_tree()
  require('nvim-tree').setup({
    disable_netrw = false,
    hijack_cursor = true,
    hijack_netrw = true,
  })
end

return config
