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
    'terraformls',
    'terraform_lsp',
    -- 'yamlls',
    'helm_ls',
    'lemminx',
  }

  local mason_language_servers = {
    'bashls',
    'docker_compose_language_service',
    'dockerls',
    'eslint',
    'marksman',
    'pyright',
    'solargraph',
    'sqlls',
    'rust_analyzer',
    'terraformls',
    'tfsec',
    'helm_ls',
    'lua_ls',
    -- 'gopls',
    'yamlls',
    -- 'groovyls',
    'lemminx',
  }

  -- Language servers to eagerly install
  require('mason-lspconfig').setup({
    ensure_installed = mason_language_servers,
  })

  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  local lspconfig = require('lspconfig')
  local configs = require('lspconfig.configs')
  local util = require('lspconfig.util')

  vim.keymap.set('n', '<space>of', vim.diagnostic.open_float, new_opts(noremap, silent, 'DIAGNOSTIC: Open Float'))
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, new_opts(noremap, silent, 'DIAGNOSTIC: Goto Previous Diagnostic'))
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, new_opts(noremap, silent, 'DIAGNOSTIC: Goto Next Diagnostic'))
  vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, new_opts(noremap, silent, 'DIAGNOSTIC: Set Loc List'))
  local on_attach = function()
    -- Key bindings to be set after LSP attaches to buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('UserLspConfig', {}),
      callback = function(ev)
        vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
        vim.bo[ev.buf].formatexpr = 'v:lua.vim.lsp.formatexpr'

        -- Deprecated
        -- vim.api.nvim_buf_set_option(ev.buf, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
        -- vim.api.nvim_buf_set_option(ev.buf, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')

        -- local opts = { noremap = true, buffer = ev.buf }
        vim.keymap.set(
          'n',
          'gD',
          vim.lsp.buf.declaration,
          -- { noremap = true, buffer = ev.buf, desc = 'LSP BUF: Go To Declaration' }
          { buffer = ev.buf, desc = 'LSP BUF: Go To Declaration' }
        )
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'LSP BUF: Go To Definition' })
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf, desc = 'LSP BUF: Hover' })
        vim.keymap.set(
          'n',
          'gI',
          vim.lsp.buf.implementation,
          { buffer = ev.buf, desc = 'LSP BUF: Go To Implementation' }
        )
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { buffer = ev.buf, desc = 'LSP BUF: Signature Help' })
        vim.keymap.set(
          'n',
          '<space>wa',
          vim.lsp.buf.add_workspace_folder,
          { buffer = ev.buf, desc = 'LSP BUF: Add Workspace Folder' }
        )
        vim.keymap.set(
          'n',
          '<space>wr',
          vim.lsp.buf.remove_workspace_folder,
          { buffer = ev.buf, desc = 'LSP BUF: Remove Workspace Folder' }
        )
        vim.keymap.set('n', '<space>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, { buffer = ev.buf, desc = 'LSP BUF: List Workspace Folder' })
        vim.keymap.set(
          'n',
          '<space>D',
          vim.lsp.buf.type_definition,
          { buffer = ev.buf, desc = 'LSP BUF: Type Definition' }
        )
        vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, { buffer = ev.buf, desc = 'LSP BUF: Rename' })
        vim.keymap.set(
          { 'n', 'v' },
          '<space>ca',
          vim.lsp.buf.code_action,
          { buffer = ev.buf, desc = 'LSP BUF: Code Action' }
        )
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = ev.buf, desc = 'LSP BUF: References' })
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

  -- lspconfig.gopls.setup({
  --   cmd = { 'gopls' },
  --   filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  --   capabilities = capabilities,
  --   on_attach = on_attach,
  --   init_options = {
  --     usePlaceholders = true,
  --     completeUnimported = true,
  --   },
  --   settings = {
  --     gopls = {
  --       analyses = {
  --         nilness = true,
  --         unusedparams = true,
  --         unusedwrite = true,
  --         useany = true,
  --       },
  --       experimentalPostfixCompletions = true,
  --       gofumpt = true,
  --       semanticTokens = true,
  --       staticcheck = true,
  --       usePlaceholders = true,
  --       hints = {
  --         assignVariableTypes = true,
  --         compositeLiteralFields = true,
  --         compositeLiteralTypes = true,
  --         constantValues = true,
  --         functionTypeParameters = true,
  --         parameterNames = true,
  --         rangeVariableTypes = true,
  --       },
  --     },
  --   },
  -- })

  lspconfig.lua_ls.setup({
    on_attach = on_attach,
    on_init = function(client)
      local path = client.workspace_folders[1].name
      if not vim.loop.fs_stat(path .. '/.luarc.json') and not vim.loop.fs_stat(path .. '/.luarc.jsonc') then
        client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using
              -- (most likely LuaJIT in the case of Neovim)
              version = 'LuaJIT',
            },
            -- Make the server aware of Neovim runtime files
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                -- "${3rd}/luv/library"
                -- "${3rd}/busted/library",
              },
              -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
              -- library = vim.api.nvim_get_runtime_file("", true)
            },
          },
        })

        client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
      end
      return true
    end,
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

  lspconfig.yamlls.setup({
    on_attach = on_attach,
    settings = {
      yaml = {
        schemas = {
          ['https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json'] =
          '/*.k8s.yaml',
          kubernetes = 'globPattern',
        },
      },
    },
  })
end

return config
