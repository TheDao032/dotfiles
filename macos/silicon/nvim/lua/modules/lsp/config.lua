local config = {}

-- local autocmd = vim.api.nvim_create_autocmd

-- function config.nvim_java()
--   require('java').setup({
--     --  list of file that exists in root of the project
--     root_markers = {
--       'settings.gradle',
--       'settings.gradle.kts',
--       'pom.xml',
--       'build.gradle',
--       'mvnw',
--       'gradlew',
--       'build.gradle',
--       'build.gradle.kts',
--       '.git',
--     },
--
--     notifications = {
--       -- enable 'Configuring DAP' & 'DAP configured' messages on start up
--       dap = true,
--     },
--
--     -- We do multiple verifications to make sure things are in place to run this
--     -- plugin
--     verification = {
--       -- nvim-java checks for the order of execution of following
--       -- * require('java').setup()
--       -- * require('lspconfig').jdtls.setup()
--       -- IF they are not executed in the correct order, you will see a error
--       -- notification.
--       -- Set following to false to disable the notification if you know what you
--       -- are doing
--       invalid_order = true,
--
--       -- nvim-java checks if the require('java').setup() is called multiple
--       -- times.
--       -- IF there are multiple setup calls are executed, an error will be shown
--       -- Set following property value to false to disable the notification if
--       -- you know what you are doing
--       duplicate_setup_calls = true,
--
--       -- nvim-java checks if nvim-java/mason-registry is added correctly to
--       -- mason.nvim plugin.
--       -- IF it's not registered correctly, an error will be thrown and nvim-java
--       -- will stop setup
--       invalid_mason_registry = false,
--     },
--   })
-- end

function config.nvim_lspsaga()
  vim.diagnostic.config({
    virtual_text = false,
  })

  require('lspsaga').setup({
    symbol_in_winbar = { hide_keyword = false, folder_level = 1 },
    lightbulb = { sign = true },
    outline = { layout = 'float' },
    diagnostic = {
      show_code_action = true,
    },
  })
end

-- function config.nvim_mason()
--   require('mason').setup()
--   require('mason-lspconfig').setup({
--     automatic_installation = true,
--   })
-- end

return config
