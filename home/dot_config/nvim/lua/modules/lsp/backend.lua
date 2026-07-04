local M = {}
-- local au = vim.api.nvim_create_autocmd
-- local lspconfig = require('lspconfig')
local lspconfig = vim.lsp.config
local util = require('lspconfig.util')

-- local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
-- augroup('__formatter__', { clear = true })

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

  -- NOTE: format-on-save is owned by guard.nvim (fmt_on_save = true) since the
  -- 2026-07-01 formatter.nvim → guard.nvim migration. The old BufWritePost →
  -- ':FormatWrite' autocmd was a formatter.nvim leftover; ':FormatWrite' no
  -- longer exists, so it threw E492 on every LSP-attached buffer save. Removed.

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

lspconfig.pylsp = {
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
}

lspconfig.gopls = {
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
}

lspconfig.lua_ls = {
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
}

-- lspconfig.clangd = {
--   cmd = { 'clangd', '--background-index' },
--   on_attach = M._attach,
--   capabilities = M.capabilities,
--   root_dir = function(fname)
--     return util.root_pattern(unpack({
--       --reorder
--       'compile_commands.json',
--       '.clangd',
--       '.clang-tidy',
--       '.clang-format',
--       'compile_flags.txt',
--       'configure.ac', -- AutoTools
--     }))(fname) or util.find_git_ancestor(fname)
--   end,
-- }

lspconfig.rust_analyzer = {
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
}

-- lspconfig.yamlls = {
--   cmd = { 'yaml-language-server', '--stdio' },
--   filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab', 'tftpl', 'tmpl' },
--
--   root_dir = function(fname)
--     if not fname or fname == '' then
--       return nil
--     end
--
--     local root = vim.fs.find({ '.git' }, {
--       path = vim.fs.dirname(fname),
--       upward = true,
--     })[1]
--
--     return root and vim.fs.dirname(root) or vim.fs.dirname(fname)
--   end,
--   single_file_support = true,
--   settings = {
--     -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
--     redhat = { telemetry = { enabled = false } },
--   },
-- }

-- lspconfig.puppet = {
--   cmd = { 'puppet-languageserver', '--stdio' },
--   filetypes = { 'puppet' },
--   root_markers = {
--     'manifests',
--     '.puppet-lint.rc',
--     'hiera.yaml',
--     '.git',
--   },
-- }

local servers = {
  'bashls',
  'zls',
  'dockerls',
  'terraformls',
  'ansiblels',
  'ruby_lsp',
  'helm_ls',
  'jdtls',
  'gradle_ls',
  'eslint',
  'yamlls',
  'clangd',
  'puppet',
  -- 'dartls', -- owned by flutter-tools.nvim; don't double-configure via lspconfig (2026-07-01)
  'ts_ls',
  -- 'dcmls',
  -- 'ast_grep',
}

for _, server in ipairs(servers) do
  lspconfig[server] = {
    on_attach = M._attach,
    capabilities = M.capabilities,
  }
end

-- terraform-ls also serves terragrunt *.hcl files (basic HCL completion).
-- Default terraformls binds only to terraform/terraform-vars, so extend it.
-- (vim.lsp.config(name, cfg) merges into the config set above.)
lspconfig('terraformls', {
  filetypes = { 'terraform', 'terraform-vars', 'hcl' },
})

vim.lsp.handlers['workspace/diagnostic/refresh'] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
  return true
end

return M
