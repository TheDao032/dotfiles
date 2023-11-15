local keymap = require('core.keymap')
local silent, noremap = keymap.silent, keymap.noremap
local new_opts = keymap.new_opts

local config = {}

function config.nvim_lsp()
  require('mason').setup()
  local language_servers = {
    'bashls',
    'docker_compose_language_service',
    'dockerls',
    'eslint',
    'marksman',
    'pyright',
    'solargraph',
    'sqlls',
    'rust_analyzer',
    'yamlls',
    'terraformls',
    'tflint',
    'terraform_lsp',
  }

  local mason_language_servers = {
    'bashls',
    -- 'gopls',
    'docker_compose_language_service',
    'dockerls',
    'eslint',
    'lua_ls',
    'marksman',
    'pyright',
    'solargraph',
    'sqlls',
    'rust_analyzer',
    'yamlls',
    'terraformls',
    'tflint',
    'tfsec',
  }

  -- Language servers to eagerly install
  require('mason-lspconfig').setup({
    ensure_installed = mason_language_servers,
  })

  local capabilities = require('cmp_nvim_lsp').default_capabilities()
  local lspconfig = require('lspconfig')

  --[[ vim.keymap.set('n', '<space>lf', function()
    vim.lsp.buf.format({ async = true })
  end, new_opts(noremap, silent, 'LSP BUF: Format Code')) ]]
  vim.keymap.set('n', '<space>of', vim.diagnostic.open_float, new_opts(noremap, silent, 'DIAGNOSTIC: Open Float'))
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, new_opts(noremap, silent, 'DIAGNOSTIC: Goto Previous Diagnostic'))
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, new_opts(noremap, silent, 'DIAGNOSTIC: Goto Next Diagnostic'))
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, new_opts(noremap, silent, 'DIAGNOSTIC: Set Loc List'))
  local on_attach = function()
    -- Key bindings to be set after LSP attaches to buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        vim.api.nvim_buf_set_option(ev.buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
        vim.api.nvim_buf_set_option(ev.buf, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')

        -- local opts = { noremap = true, buffer = ev.buf }
        vim.keymap.set(
          'n',
          'gD',
          vim.lsp.buf.declaration,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Go To Declaration' }
        )
        vim.keymap.set(
          'n',
          'gd',
          vim.lsp.buf.definition,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Go To Definition' }
        )
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Hover' })
        vim.keymap.set(
          'n',
          'gI',
          vim.lsp.buf.implementation,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Go To Implementation' }
        )
        vim.keymap.set(
          'n',
          '<C-k>',
          vim.lsp.buf.signature_help,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Signature Help' }
        )
        vim.keymap.set(
          'n',
          '<space>wa',
          vim.lsp.buf.add_workspace_folder,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Add Workspace Folder' }
        )
        vim.keymap.set(
          'n',
          '<space>wr',
          vim.lsp.buf.remove_workspace_folder,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Remove Workspace Folder' }
        )
        vim.keymap.set('n', '<space>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, { noremap = true, buffer = ev.buf, desc = 'LSP BUF: List Workspace Folder' })
        vim.keymap.set(
          'n',
          '<space>D',
          vim.lsp.buf.type_definition,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Type Definition' }
        )
        vim.keymap.set(
          'n',
          '<space>rn',
          vim.lsp.buf.rename,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Rename' }
        )
        vim.keymap.set(
          { 'n', 'v' },
          '<space>ca',
          vim.lsp.buf.code_action,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Code Action' }
        )
        vim.keymap.set(
          'n',
          'gr',
          vim.lsp.buf.references,
          { noremap = true, buffer = ev.buf, desc = 'LSP BUF: References' }
        )
      end,
    })
  end

  -- lsp_signature UI tweaks
  require('lsp_signature').setup({
    bind = true,
    handler_opts = {
      border = 'rounded',
    },
  })

  -- LSP diagnostics

  vim.opt.updatetime = 250
  vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    underline = true,
    signs = true,
  })

  vim.cmd([[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]])

  -- Configure individual language servers here
  for _, server in pairs(language_servers) do
    lspconfig[server].setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
  end

  lspconfig.gopls.setup({
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    capabilities = capabilities,
    on_attach = on_attach,
    init_options = {
      usePlaceholders = true,
      completeUnimported = true,
    },
    settings = {
      gopls = {
        analyses = {
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
        experimentalPostfixCompletions = true,
        gofumpt = true,
        semanticTokens = true,
        staticcheck = true,
        usePlaceholders = true,
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
    on_attach = on_attach,
    settings = {
      Lua = {
        diagnostics = {
          enable = true,
          globals = { 'vim' },
        },
        runtime = {
          version = 'LuaJIT',
          path = vim.split(package.path, ';'),
        },
        workspace = {
          library = {
            vim.env.VIMRUNTIME,
            vim.env.HOME .. '/.local/share/nvim/lazy/emmylua-nvim',
          },
          checkThirdParty = false,
        },
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  })

  lspconfig.clangd.setup({
    on_attach = on_attach,
    cmd = {
      'clangd',
      '--background-index',
      '--clang-tidy',
      '--header-insertion=iwyu',
    },
  })

  lspconfig.rust_analyzer.setup({
    on_attach = on_attach,
    settings = {
      ['rust-analyzer'] = {
        assist = {
          importEnforceGranularity = true,
          importPrefix = 'crate',
        },
        imports = {
          granularity = {
            group = 'module',
          },
          prefix = 'self',
        },
        cargo = {
          allFeatures = true,
          buildScripts = {
            enable = true,
          },
        },
        checkOnSave = {
          -- default: `cargo check`
          -- command = "clippy"
          command = 'cargo check',
        },
        procMacro = {
          enable = true,
        },
        inlayHints = {
          lifetimeElisionHints = {
            enable = true,
            useParameterNames = true,
          },
        },
      },
    },
  })

end

function config.null_ls()
  local null_ls = require('null-ls')

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/formatting
  local formatting = null_ls.builtins.formatting

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/diagnostics
  local diagnostics = null_ls.builtins.diagnostics

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/completion
  local completion = null_ls.builtins.completion

  -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/lua/null-ls/builtins/code_actions
  local code_actions = null_ls.builtins.code_actions

  local augroup = vim.api.nvim_create_augroup('LspFormatting', {})

  null_ls.setup({
    debug = true,
    sources = {
      formatting.terraform_fmt.with({
        filetypes = { 'terraform', 'tf', 'hcl' }
      }),
      formatting.prettier.with({ extra_args = { '--no-semi', '--single-quote', '--jsx-single-quote' } }),
      formatting.eslint,
      formatting.stylua,
      formatting.cljstyle,
      diagnostics.msspell,
      diagnostics.eslint,
      diagnostics.clj_kondo,
      completion.spell,
      code_actions.gitsigns,
    },
    on_attach = function(client, bufnr)
      if client.supports_method('textDocument/formatting') then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd('BufWritePre', {
          group = augroup,
          buffer = bufnr,
          callback = function()
            -- vim.lsp.buf.format({ bufnr = bufnr, async = true })
            vim.lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
          end,
        })
      end
    end,
  })
end

return config
