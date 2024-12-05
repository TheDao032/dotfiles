local lspconfig = require('lspconfig')
local _attach = require('modules.lsp.backend')._attach
local capabilities = require('modules.lsp.backend').capabilities

lspconfig.jsonls.setup({
  capabilities = capabilities,
  on_attach = _attach,
})

-- npm i -g typescript
-- npm i -g typescript-langauge-server
lspconfig.ts_ls.setup({
  on_attach = _attach,
  capabilities = capabilities,
})

-- npm i -g vscode-langservers-extracted
lspconfig.eslint.setup({
  capabilities = capabilities,
  filetypes = { 'javascriptreact', 'typescriptreact' },
  on_attach = _attach,
  -- on_attach = function(client, bufnr)
  --   _attach(client)
  --   vim.api.nvim_create_autocmd('BufWritePre', {
  --     buffer = bufnr,
  --     command = 'EslintFixAll',
  --   })
  -- end,
})
