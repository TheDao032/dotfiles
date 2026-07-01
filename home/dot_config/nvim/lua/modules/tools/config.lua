local config = {}
local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

function merge_tables(...)
  local result = {}
  for _, t in ipairs({ ... }) do
    for k, v in pairs(t) do
      result[k] = v -- Overwrites existing keys
    end
  end
  return result
end

function config.template_nvim()
  require('template').setup({
    temp_dir = '~/.config/nvim/template',
    author = 'nthedao2705',
    email = 'nthedao2705@gmail.com',
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
  ft('rust'):fmt('rustfmt')
  ft('typescript', 'javascript', 'typescriptreact', 'javascriptreact'):fmt('prettier')

  -- Migrated from formatter.nvim (2026-07-01). NOTE: these now format ON SAVE
  -- (guard fmt_on_save), whereas formatter.nvim required a manual :Format.
  ft('terraform'):fmt({
    cmd = 'terraform',
    args = { 'fmt', '-' },
    stdin = true,
  })
  ft('hcl'):fmt({
    cmd = 'terraform',
    args = { 'fmt', '-' },
    stdin = true,
  })
  -- puppet-lint --fix edits the file in place (stdin=false + fname=true →
  -- `puppet-lint --fix <file>`). puppet-lint may exit non-zero when unfixable
  -- warnings remain; if guard rejects the result, keep formatter.nvim for puppet
  -- or adjust here. Verify on a real .pp file.
  ft('puppet'):fmt({
    cmd = 'puppet-lint',
    args = { '--fix' },
    stdin = false,
    fname = true,
  })

  ft('*'):lint('codespell')

  vim.g.guard_config = {
    -- format on write to buffer
    fmt_on_save = true,
    -- use lsp if no formatter was defined for this filetype
    lsp_as_default_formatter = false,
    -- whether or not to save the buffer after formatting
    save_on_fmt = true,
  }

  -- require('guard').setup()
end

function config.toggle_term()
  local startup_cwd = vim.fs.normalize(vim.uv.cwd() or vim.fn.getcwd())
  local root_markers = {
    '.git',
    'go.work',
    'go.mod',
    'package.json',
    'Cargo.toml',
    'pyproject.toml',
    'setup.py',
    'requirements.txt',
    'Makefile',
    '.luarc.json',
    '.stylua.toml',
  }

  local function current_workspace_root()
    local bufnr = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(bufnr)

    if name ~= '' then
      for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        local root = client.config and client.config.root_dir
        if root and root ~= '' then
          return vim.fs.normalize(root)
        end

        for _, workspace in ipairs(client.workspace_folders or {}) do
          local path = workspace.name or (workspace.uri and vim.uri_to_fname(workspace.uri))
          if path and path ~= '' then
            return vim.fs.normalize(path)
          end
        end
      end

      local root = vim.fs.root(name, root_markers)
      if root then
        return vim.fs.normalize(root)
      end
    end

    return startup_cwd
  end

  require('toggleterm').setup({
    size = 16,
  })
  local Terminal = require('toggleterm.terminal').Terminal

  vim.keymap.set('n', '<Leader>T', function()
    local dir = vim.fn.fnameescape(current_workspace_root())
    local prefix = vim.v.count > 0 and tostring(vim.v.count) or ''
    vim.cmd(prefix .. 'ToggleTerm dir=' .. dir)
  end, { desc = 'ToggleTerm: Workspace Root' })

  vim.keymap.set('n', '<space>G', function()
    local buf_name = vim.api.nvim_buf_get_name(0)
    local start_path = buf_name ~= '' and buf_name or vim.uv.cwd()
    local git_root = vim.fs.root(start_path, '.git') or vim.uv.cwd()
    local lazygit = Terminal:new({
      cmd = 'lazygit',
      dir = git_root,
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
    lazygit:toggle()
  end, { desc = 'ToggleTerm: LazyGit' })
end

function config.nvim_dap()
  require('nvim-dap-virtual-text').setup()
  require('mason-nvim-dap').setup({
    ensure_installed = { 'delve', 'python', 'dart' },
    automatic_installation = true,
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

  -- Cached device configs (populated by <Leader>dd)
  local dart_device_configs = {}

  local function refresh_flutter_devices()
    vim.notify('Refreshing flutter devices...', vim.log.levels.INFO)
    vim.system({ 'flutter', 'devices', '--machine' }, { text = true }, function(result)
      local configs = {}
      if result.code == 0 and result.stdout and result.stdout ~= '' then
        local ok, devices = pcall(vim.json.decode, result.stdout)
        if ok and type(devices) == 'table' then
          for _, device in ipairs(devices) do
            local device_name = device.name or device.id
            local device_id = device.id

            table.insert(configs, {
              type = 'dart',
              request = 'launch',
              name = 'Launch dart (' .. device_name .. ')',
              dartSdkPath = require('core.platform').dart_sdk,
              flutterSdkPath = require('core.platform').flutter_sdk,
              program = '${workspaceFolder}/lib/main.dart',
              cwd = '${workspaceFolder}',
              args = { '--device-id', device_id },
            })
            table.insert(configs, {
              type = 'flutter',
              request = 'launch',
              name = 'Launch flutter (' .. device_name .. ')',
              dartSdkPath = require('core.platform').dart_sdk,
              flutterSdkPath = require('core.platform').flutter_sdk,
              program = '${workspaceFolder}/lib/main.dart',
              cwd = '${workspaceFolder}',
              toolArgs = { '-d', device_id },
            })
          end
        end
      end
      dart_device_configs = configs
      vim.schedule(function()
        vim.notify(string.format('Found %d flutter device(s)', #configs / 2), vim.log.levels.INFO)
      end)
    end)
  end

  -- Static default configs (required to be a list by nvim-dap)
  dap.configurations.dart = {
    {
      type = 'dart',
      request = 'launch',
      name = 'Launch dart (default)',
      dartSdkPath = require('core.platform').dart_sdk,
      flutterSdkPath = require('core.platform').flutter_sdk,
      program = '${workspaceFolder}/lib/main.dart',
      cwd = '${workspaceFolder}',
    },
    {
      type = 'flutter',
      request = 'launch',
      name = 'Launch flutter (default)',
      dartSdkPath = require('core.platform').dart_sdk,
      flutterSdkPath = require('core.platform').flutter_sdk,
      program = '${workspaceFolder}/lib/main.dart',
      cwd = '${workspaceFolder}',
    },
  }

  -- Provider returns cached device configs (no blocking)
  dap.providers.configs['dart-devices'] = function(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype ~= 'dart' then
      return {}
    end
    return dart_device_configs
  end

  -- Refresh devices on keymap; also auto-refresh when entering a dart file
  vim.keymap.set('n', '<Leader>dd', refresh_flutter_devices, { desc = 'DAP: Refresh flutter devices' })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dart',
    callback = function()
      if #dart_device_configs == 0 then
        refresh_flutter_devices()
      end
    end,
  })

  -- Dart CLI adapter (recommended)
  dap.adapters.dart = {
    type = 'executable',
    command = 'dart', -- if you're using fvm, you'll need to provide the full path to dart (dart.exe for windows users), or you could prepend the fvm command
    args = { 'debug_adapter' },
    -- windows users will need to set 'detached' to false
    options = {
      detached = false,
    },
  }
  dap.adapters.flutter = {
    type = 'executable',
    command = 'flutter', -- if you're using fvm, you'll need to provide the full path to flutter (flutter.bat for windows users), or you could prepend the fvm command
    args = { 'debug_adapter' },
    -- windows users will need to set 'detached' to false
    options = {
      detached = false,
    },
  }
end

function config.nvim_cmp()
  local cmp = require('cmp')

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        -- vim.fn['vsnip#anonymous'](args.body) -- For `vsnip` users.
        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        -- vim.snippet.expand(args.body) -- For native neovim snippets (Neovim v0.10+)
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      -- { name = 'vsnip' }, -- For vsnip users.
      { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    }),
  })

  -- To use git you need to install the plugin petertriho/cmp-git and uncomment lines below
  -- Set configuration for specific filetype.
  --[[ cmp.setup.filetype('gitcommit', {
    sources = cmp.config.sources({
      { name = 'git' },
    }, {
      { name = 'buffer' },
    })
 })
 require("cmp_git").setup() ]]
  --

  -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = 'buffer' },
    },
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' },
    }, {
      { name = 'cmdline' },
    }),
    matching = { disallow_symbol_nonprefix_matching = false },
  })
end

function config.nvim_conform()
  require('conform').setup({
    -- Map of filetype to formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      -- Conform will run multiple formatters sequentially
      go = { 'goimports', 'gofmt' },
      -- You can also customize some of the format options for the filetype
      rust = { 'rustfmt', lsp_format = 'fallback' },
      -- You can use a function here to determine the formatters dynamically
      python = function(bufnr)
        if require('conform').get_formatter_info('ruff_format', bufnr).available then
          return { 'ruff_format' }
        else
          return { 'isort', 'black' }
        end
      end,
      -- Use the "*" filetype to run formatters on all filetypes.
      ['*'] = { 'codespell' },
      -- Use the "_" filetype to run formatters on filetypes that don't
      -- have other formatters configured.
      ['_'] = { 'trim_whitespace' },
    },
    -- Set this to change the default values when calling conform.format()
    -- This will also affect the default values for format_on_save/format_after_save
    default_format_opts = {
      lsp_format = 'fallback',
    },
    -- If this is set, Conform will run the formatter on save.
    -- It will pass the table to conform.format().
    -- This can also be a function that returns the table.
    format_on_save = {
      -- I recommend these options. See :help conform.format for details.
      lsp_format = 'fallback',
      timeout_ms = 500,
    },
    -- If this is set, Conform will run the formatter asynchronously after save.
    -- It will pass the table to conform.format().
    -- This can also be a function that returns the table.
    format_after_save = {
      lsp_format = 'fallback',
    },
    -- Set the log level. Use `:ConformInfo` to see the location of the log file.
    log_level = vim.log.levels.ERROR,
    -- Conform will notify you when a formatter errors
    notify_on_error = true,
    -- Conform will notify you when no formatters are available for the buffer
    notify_no_formatters = true,
    -- Custom formatters and overrides for built-in formatters
    formatters = {
      -- my_formatter = {
      --   -- This can be a string or a function that returns a string.
      --   -- When defining a new formatter, this is the only field that is required
      --   command = 'my_cmd',
      --   -- A list of strings, or a function that returns a list of strings
      --   -- Return a single string instead of a list to run the command in a shell
      --   args = { '--stdin-from-filename', '$FILENAME' },
      --   -- If the formatter supports range formatting, create the range arguments here
      --   range_args = function(self, ctx)
      --     return { '--line-start', ctx.range.start[1], '--line-end', ctx.range['end'][1] }
      --   end,
      --   -- Send file contents to stdin, read new contents from stdout (default true)
      --   -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
      --   -- file is assumed to be modified in-place by the format command.
      --   stdin = true,
      --   -- A function that calculates the directory to run the command in
      --   cwd = require('conform.util').root_file({ '.editorconfig', 'package.json' }),
      --   -- When cwd is not found, don't run the formatter (default false)
      --   require_cwd = true,
      --   -- When stdin=false, use this template to generate the temporary file that gets formatted
      --   tmpfile_format = '.conform.$RANDOM.$FILENAME',
      --   -- When returns false, the formatter will not be used
      --   condition = function(self, ctx)
      --     return vim.fs.basename(ctx.filename) ~= 'README.md'
      --   end,
      --   -- Exit codes that indicate success (default { 0 })
      --   exit_codes = { 0, 1 },
      --   -- Environment variables. This can also be a function that returns a table.
      --   env = {
      --     VAR = 'value',
      --   },
      --   -- Set to false to disable merging the config with the base definition
      --   inherit = true,
      --   -- When inherit = true, add these additional arguments to the beginning of the command.
      --   -- This can also be a function, like args
      --   prepend_args = { '--use-tabs' },
      --   -- When inherit = true, add these additional arguments to the end of the command.
      --   -- This can also be a function, like args
      --   append_args = { '--trailing-comma' },
      -- },
      terraform = {
        -- This can be a string or a function that returns a string.
        -- When defining a new formatter, this is the only field that is required
        command = 'terraform',
        -- A list of strings, or a function that returns a list of strings
        -- Return a single string instead of a list to run the command in a shell
        args = { 'fmt', '-' },
        -- If the formatter supports range formatting, create the range arguments here
        range_args = function(self, ctx)
          return { '--line-start', ctx.range.start[1], '--line-end', ctx.range['end'][1] }
        end,
        -- Send file contents to stdin, read new contents from stdout (default true)
        -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
        -- file is assumed to be modified in-place by the format command.
        stdin = true,
        -- A function that calculates the directory to run the command in
        cwd = require('conform.util').root_file({ '.editorconfig', 'package.json' }),
        -- When cwd is not found, don't run the formatter (default false)
        require_cwd = true,
        -- When stdin=false, use this template to generate the temporary file that gets formatted
        tmpfile_format = '.conform.$RANDOM.$FILENAME',
        -- When returns false, the formatter will not be used
        condition = function(self, ctx)
          return vim.fs.basename(ctx.filename) ~= 'README.md'
        end,
        -- Exit codes that indicate success (default { 0 })
        exit_codes = { 0, 1 },
        -- Environment variables. This can also be a function that returns a table.
        -- env = {
        --   VAR = 'value',
        -- },
        -- Set to false to disable merging the config with the base definition
        inherit = true,
        -- When inherit = true, add these additional arguments to the beginning of the command.
        -- This can also be a function, like args
        prepend_args = { '--use-tabs' },
        -- When inherit = true, add these additional arguments to the end of the command.
        -- This can also be a function, like args
        append_args = { '--trailing-comma' },
      },
      -- These can also be a function that returns the formatter
      -- other_formatter = function(bufnr)
      --   return {
      --     command = 'my_cmd',
      --   }
      -- end,
    },
  })

  -- You can set formatters_by_ft and formatters directly
  -- require('conform').formatters_by_ft.lua = { 'stylua' }
  -- require('conform').formatters.my_formatter = {
  --   command = 'my_cmd',
  -- }
end

function config.nvim_null_ls()
  -- local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

  local null_ls = require('null-ls')
  local formatting = null_ls.builtins.formatting
  local diagnostics = null_ls.builtins.diagnostics
  local completion = null_ls.builtins.completion

  local formatting_sources = {
    formatting.puppet_lint,
    formatting.stylua,
  }
  local diagnostics_sources = {
    diagnostics.puppet_lint,
    diagnostics.eslint,
  }
  local completion_sources = {

    completion.spell,
  }

  null_ls.setup({
    sources = merge_tables(formatting_sources, diagnostics_sources, completion_sources),
    root_dir = require('null-ls.utils').root_pattern('.null-ls-root', 'Makefile', '.git', '.pp'),
    on_attach = function(client, bufnr)
      if client.supports_method('textDocument/formatting') then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd('BufWritePre', {
          group = augroup,
          buffer = bufnr,
          callback = function()
            -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
            -- on later neovim version, you should use vim.lsp.buf.format({ async = false }) instead
            -- vim.lsp.buf.formatting_sync()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end
    end,
  })
end

function config.nvim_diagram()
  -- require('image').setup({
  --   rocks = {
  --     hererocks = true,
  --   },
  -- })

  require('diagram').setup({
    integrations = {
      require('diagram.integrations.markdown'),
      require('diagram.integrations.neorg'),
    },
    renderer_options = {
      mermaid = {
        theme = 'forest',
      },
      plantuml = {
        charset = 'utf-8',
      },
      d2 = {
        theme_id = 1,
      },
      gnuplot = {
        theme = 'dark',
        size = '800,600',
      },
    },
  })
end

return config
