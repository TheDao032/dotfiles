local M = {}
-- local au = vim.api.nvim_create_autocmd
local lspconfig = require('lspconfig')

-- local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
-- augroup('__formatter__', { clear = true })
local augroup = vim.api.nvim_create_augroup('LspFormatting', { clear = true })

M.capabilities = require('cmp_nvim_lsp').default_capabilities()
-- M.capabilities =
--   vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('epo').register_cap())

autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_clients({ id = args.data.client_id })[1]
    client.server_capabilities.semanticTokensProvider = nil
    client.server_capabilities.documentFormattingProvider = false
  end,
})

function M._attach(client, bufnr)
  vim.opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
  -- vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  -- client.server_capabilities.semanticTokensProvider = nil
  -- client.server_capabilities.documentFormattingProvider = false
  local original = vim.notify
  local mynotify = function(msg, level, opts)
    if msg == 'No code actions available' or msg:find('overly') then
      return
    end
    original(msg, level, opts)
  end
  vim.notify = mynotify

  autocmd('BufWritePost', {
    group = augroup,
    buffer = bufnr,
    command = ':FormatWrite',
  })

  autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
    pattern = '*',
    command = 'checktime',
  })

  -- vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  --   virtual_text = false,
  --   underline = true,
  --   signs = true,
  -- })
  --
  -- autocmd({ 'CursorHoldI' }, {
  --   pattern = '*',
  --   command = 'vim.lsp.diagnostic.show_line_diagnostics()',
  -- })
  --
  -- autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  --   pattern = '*',
  --   command = 'vim.lsp.buf.signature_help()',
  -- })
end

lspconfig.pylsp.setup({
  on_attach = M._attach,
  capabilities = M.capabilities,
  cmd = { 'pylsp' },
  settings = {
    pylsp = {
      plugins = {
        -- formatter options
        black = { enabled = true },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        -- linter options
        pylint = { enabled = true, executable = 'pylint' },
        pyflakes = { enabled = false },
        pycodestyle = { enabled = false },
        -- type checker
        pylsp_mypy = { enabled = true },
        -- auto-completion options
        jedi_completion = {
          enabled = true,
          fuzzy = true,
        },
        -- import sorting
        pyls_isort = { enabled = true },
      },
    },
  },
})

lspconfig.gopls.setup({
  cmd = { 'gopls', 'serve' },
  on_attach = M._attach,
  capabilities = M.capabilities,
  settings = {
    gopls = {
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        unusedparams = true,
        nilness = true,
        unusedwrite = true,
        useany = true,
      },
      semanticTokens = true,
      staticcheck = true,
      experimentalPostfixCompletions = true,
      gofumpt = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
})

lspconfig.lua_ls.setup({
  on_attach = M._attach,
  capabilities = M.capabilities,
  settings = {
    Lua = {
      diagnostics = {
        unusedLocalExclude = { '_*' },
        globals = { 'vim' },
        disable = {
          'luadoc-miss-see-name',
          'undefined-field',
        },
      },
      runtime = {
        version = 'LuaJIT',
        -- path = vim.split(package.path, ';'),
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME .. '/lua',
          '${3rd}/busted/library',
          '${3rd}/luv/library',
        },
        checkThirdParty = 'Disable',
      },
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})

lspconfig.clangd.setup({
  cmd = { 'clangd', '--background-index' },
  on_attach = M._attach,
  capabilities = M.capabilities,
  root_dir = function(fname)
    return lspconfig.util.root_pattern(unpack({
      --reorder
      'compile_commands.json',
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_flags.txt',
      'configure.ac', -- AutoTools
    }))(fname) or lspconfig.util.find_git_ancestor(fname)
  end,
})

lspconfig.rust_analyzer.setup({
  on_attach = M._attach,
  capabilities = M.capabilities,
  settings = {
    ['rust-analyzer'] = {
      imports = {
        granularity = {
          group = 'module',
        },
        prefix = 'self',
      },
      cargo = {
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
      },
    },
  },
})

lspconfig.yamlls.setup({
  cmd = { 'yaml-language-server', '--stdio' },
  filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'tftpl', 'tmpl' },

  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
  end,
  single_file_support = true,
  settings = {
    -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
    redhat = { telemetry = { enabled = false } },
  },
})

lspconfig.puppet.setup({
  cmd = { 'puppet-languagesever', '--stdio' },
  filetypes = { 'puppet' },
  root_dir = lspconfig.util.root_pattern(unpack({
    'manifests',
    '.puppet-lint.rc',
    'hiera.yaml',
    '.git',
  })),
  single_file_support = true,
})

local servers = {
  'bashls',
  'zls',
  'dockerls',
  'terraformls',
  'terraform_lsp',
  'ansiblels',
  'ruby_lsp',
  'helm_ls',
  'jdtls',
  'puppet',
  'gradle_ls',
  -- 'yamlls',
  -- 'ast_grep',
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    on_attach = M._attach,
    capabilities = M.capabilities,
  })
end

vim.lsp.handlers['workspace/diagnostic/refresh'] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
  return true
end

return M
