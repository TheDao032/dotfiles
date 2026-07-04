-- Template files (*.tmpl, *.tftpl) get filetype `template`, which ships no
-- commentstring. These mostly wrap #-comment formats (YAML, HCL, shell, Brewfile,
-- terragrunt), so default to '# %s' — needed by gc and by Comment.nvim's pre_hook
-- (which reads vim.bo.commentstring for parserless filetypes like this one).
vim.bo.commentstring = '# %s'
