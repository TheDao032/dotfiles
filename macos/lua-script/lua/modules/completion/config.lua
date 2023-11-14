local config = {}

function config.nvim_cmp()
  local cmp = require('cmp')
  local luasnip = require('luasnip')

  cmp.setup({
    snippet = {
      -- REQUIRED - you must specify a snippet engine
      expand = function(args)
        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
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
      ['<Right>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'nvim_lua' },
      { name = 'luasnip' },
      { name = 'buffer' },
      { name = 'path' },
      -- { name = 'vsnip' }, -- For vsnip users.
      -- { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- cmp configuration
  -- local cmp = require('cmp')
  -- local luasnip = require('luasnip')
  --
  -- cmp.setup({
  --   preselect = cmp.PreselectMode.None,
  --   snippet = {
  --     expand = function(args)
  --       require('luasnip').lsp_expand(args.body)
  --     end,
  --   },
  --   mapping = cmp.mapping.preset.insert({
  --     ['<C-u>'] = cmp.mapping.scroll_docs(-4),
  --     ['<C-d>'] = cmp.mapping.scroll_docs(4),
  --     ['<C-e>'] = cmp.mapping.close(),
  --     ['<CR>'] = cmp.mapping.confirm({
  --       behavior = cmp.ConfirmBehavior.Insert,
  --       select = false,
  --     }),
  --     ['<Right>'] = cmp.mapping.confirm({
  --       behavior = cmp.ConfirmBehavior.Replace,
  --       select = true,
  --     }),
  --     ['<Tab>'] = cmp.mapping(function(fallback)
  --       if luasnip.expand_or_jumpable() then
  --         luasnip.expand_or_jump()
  --       else
  --         fallback()
  --       end
  --     end, { 'i', 's' }),
  --     ['<S-Tab>'] = cmp.mapping(function(fallback)
  --       if luasnip.jumpable(-1) then
  --         luasnip.jump(-1)
  --       else
  --         fallback()
  --       end
  --     end, { 'i', 's' }),
  --   }),
  --   sources = {
  --     { name = 'nvim_lua' },
  --     { name = 'nvim_lsp' },
  --     { name = 'luasnip' },
  --     { name = 'buffer' },
  --     { name = 'path' },
  --   },
  -- })
end

function config.lua_snip()
  local ls = require('luasnip')
  local types = require('luasnip.util.types')
  ls.config.set_config({
    history = true,
    enable_autosnippets = true,
    updateevents = 'TextChanged,TextChangedI',
    ext_opts = {
      [types.choiceNode] = {
        active = {
          virt_text = { { '<- choiceNode', 'Comment' } },
        },
      },
    },
  })
  require('luasnip.loaders.from_lua').lazy_load({ paths = vim.fn.stdpath('config') .. '/snippets' })
  require('luasnip.loaders.from_vscode').lazy_load()
  require('luasnip.loaders.from_vscode').lazy_load({
    paths = { './snippets/' },
  })
end

function config.nvim_spellsitter()
  require('spellsitter').setup()
end

return config
