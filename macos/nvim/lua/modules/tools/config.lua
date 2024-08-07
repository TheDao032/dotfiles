local config = {}

function config.template_nvim()
  require('template').setup({
    temp_dir = '~/.config/nvim/template',
    author = 'glepnir',
    email = 'glephunter@gmail.com',
  })
  require('telescope').load_extension('find_template')
end

function config.guard()
  local ft = require('guard.filetype')
  ft('c,cpp'):fmt({
    cmd = 'clang-format',
    stdin = true,
    ignore_patterns = { 'neovim', 'vim' },
  })

  ft('lua'):fmt({
    cmd = 'stylua',
    args = { '-' },
    stdin = true,
    ignore_patterns = '%w_spec%.lua',
  })
  ft('go'):fmt('lsp'):append('golines')
  ft('rust'):fmt('ast-grep')
  ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')

  require('guard').setup()
end

function config.toggle_term()
  require('toggleterm').setup({
    size = 16,
  })
  local Terminal = require('toggleterm.terminal').Terminal
  local lazygit = Terminal:new({
    cmd = 'lazygit',
    dir = 'git_dir',
    direction = 'float',
    float_opts = {
      border = 'double',
    },
    -- function to run on opening the terminal
    on_open = function(term)
      vim.cmd('startinsert!')
      vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
    end,
    -- function to run on closing the terminal
    on_close = function(term)
      vim.cmd('startinsert!')
    end,
  })

  vim.keymap.set('n', '<space>G', function()
    lazygit:toggle()
  end, { desc = 'ToggleTerm: LazyGit' })
end

function config.nvim_dap()
  require('nvim-dap-virtual-text').setup()
  require('mason-nvim-dap').setup({
    ensure_installed = { 'delve', 'python' },
  })

  local dap, dapui = require('dap'), require('dapui')

  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end

  vim.keymap.set('n', '<F5>', function()
    require('dap').continue()
  end)
  vim.keymap.set('n', '<F10>', function()
    require('dap').step_over()
  end)
  vim.keymap.set('n', '<F11>', function()
    require('dap').step_into()
  end)
  vim.keymap.set('n', '<F12>', function()
    require('dap').step_out()
  end)
  vim.keymap.set('n', '<Leader>b', function()
    require('dap').toggle_breakpoint()
  end)
  vim.keymap.set('n', '<Leader>B', function()
    require('dap').set_breakpoint()
  end)
  vim.keymap.set('n', '<Leader>lp', function()
    require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
  end)
  vim.keymap.set('n', '<Leader>dr', function()
    require('dap').repl.open()
  end)
  vim.keymap.set('n', '<Leader>dl', function()
    require('dap').run_last()
  end)
  vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function()
    require('dap.ui.widgets').hover()
  end)
  vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function()
    require('dap.ui.widgets').preview()
  end)
  vim.keymap.set('n', '<Leader>df', function()
    local widgets = require('dap.ui.widgets')
    widgets.centered_float(widgets.frames)
  end)
  vim.keymap.set('n', '<Leader>ds', function()
    local widgets = require('dap.ui.widgets')
    widgets.centered_float(widgets.scopes)
  end)
  vim.keymap.set({ 'n', 'v' }, '<M-k>', function()
    -- require('dapui').float_element('console', { position = 'center' })
    require('dapui').eval()
  end)

  dap.adapters.delve = {
    type = 'server',
    port = '${port}',
    executable = {
      command = 'dlv',
      args = { 'dap', '-l', '127.0.0.1:${port}' },
      options = {
        env = {},
      },
    },
  }

  -- https://github.com/go-delve/delve/blob/master/Documentation/usage/dlv_dap.md
  dap.configurations.go = {
    {
      type = 'delve',
      name = 'Debug File',
      request = 'launch',
      program = '${file}',
    },
    {
      type = 'delve',
      name = 'Debug test file', -- configuration for debugging test files
      request = 'launch',
      mode = 'test',
      program = '${file}',
    },
    -- works with go.mod packages and sub packages
    {
      type = 'delve',
      name = 'Debug test (go.mod)',
      request = 'launch',
      mode = 'test',
      program = './${relativeFileDirname}',
    },
    {
      type = 'delve',
      name = 'Debug Application',
      request = 'launch',
      mode = 'debug',
      program = '${workspaceFolder}/main.go',
      args = { 'start', '--config=./config/local/config.yaml' },
    },
  }

  dap.adapters.python = {
    type = 'executable',
    command = os.getenv('HOME') .. '/.venv/bin/python3',
    args = { '-m', 'debugpy.adapter' },
  }

  dap.configurations.python = {
    {
      type = 'python',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      pythonPath = function()
        return os.getenv('HOME') .. '/.venv/bin/python3'
      end,
    },
  }
end

return config
