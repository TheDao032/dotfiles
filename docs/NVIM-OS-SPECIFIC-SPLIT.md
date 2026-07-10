# Splitting Nvim Configuration for macOS and Linux

## Table of Contents

1. [Quick Overview](#quick-overview)
2. [Understanding Chezmoi's OS Detection](#understanding-chezmois-os-detection)
3. [Current Nvim Structure](#current-nvim-structure)
4. [Proposed New Structure](#proposed-new-structure)
5. [Implementation Plan](#implementation-plan)
6. [Step-by-Step Setup](#step-by-step-setup)
7. [Common Patterns & Use Cases](#common-patterns--use-cases)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [Rollback Strategy](#rollback-strategy)

---

## Quick Overview

| Approach | Pros | Cons | When to Use |
|----------|------|------|-----------|
| **Chezmoi Templates** | Native to chezmoi, clean separation, easy to manage | Requires `.tmpl` files everywhere | **Recommended for simple splits** |
| **Runtime OS Detection (Lua)** | No template complexity, single files | More Lua code, harder to debug | For complex, multi-file logic |
| **Hybrid (Templates + Lua)** | Best of both worlds | More moving parts | For large, complex configs |

**Recommendation**: Start with **Hybrid approach** — templates for file/package separation, Lua for runtime logic.

---

## Understanding Chezmoi's OS Detection

### 1. Built-in OS Variables

Chezmoi provides **automatic OS detection** in all `.tmpl` files:

```gotemplate
{{ .chezmoi.os }}      → "darwin" (macOS) or "linux"
{{ .chezmoi.arch }}    → "arm64" (Apple Silicon), "amd64", etc.
{{ .chezmoi.hostname }} → your machine name
```

### 2. How Chezmoi Renders Templates

When chezmoi processes a file:

```
Source file: home/dot_config/nvim/init.lua.tmpl
                                              ↑ .tmpl = process as Go template

chezmoi detects:
  {{ .chezmoi.os }} = "darwin"   ← on macOS
  {{ .chezmoi.os }} = "linux"    ← on Linux

Chezmoi replaces:
  {{ if eq .chezmoi.os "darwin" }} MACOS_CODE {{ end }}
  {{ if eq .chezmoi.os "linux" }}  LINUX_CODE {{ end }}

Result written to: ~/.config/nvim/init.lua
```

### 3. Template Syntax Crash Course

```gotemplate
{{ if eq .chezmoi.os "darwin" }}
  macOS-specific code here
{{ else if eq .chezmoi.os "linux" }}
  Linux-specific code here
{{ end }}

{{ if and (eq .chezmoi.os "darwin") (eq .chezmoi.arch "arm64") }}
  Apple Silicon specific
{{ end }}

{{ if or (eq .chezmoi.os "darwin") (eq .chezmoi.os "linux") }}
  Both macOS and Linux
{{ end }}
```

---

## Current Nvim Structure

```
home/dot_config/nvim/
├── init.lua                          ← Entry point
├── lua/
│   ├── core/
│   │   ├── init.lua                  ← Global settings, plugin manager bootstrap
│   │   ├── keymap.lua                ← Global keymaps
│   │   ├── options.lua               ← Global vim.o settings
│   │   ├── pack.lua                  ← Plugin manager integration
│   │   ├── cli.lua
│   │   └── helper.lua
│   ├── modules/
│   │   ├── editor/
│   │   │   ├── config.lua            ← Plugin configurations
│   │   │   └── package.lua           ← Plugin definitions
│   │   ├── lsp/
│   │   │   ├── config.lua
│   │   │   ├── package.lua
│   │   │   └── backend.lua / frontend.lua
│   │   ├── tools/
│   │   │   ├── config.lua
│   │   │   └── package.lua
│   │   └── ui/
│   │       ├── config.lua
│   │       └── package.lua
│   ├── internal/
│   │   ├── event.lua
│   │   ├── kitty.lua
│   │   └── pairs.lua
│   └── keymap/
│       ├── init.lua
│       └── remap.lua
├── after/ftplugin/                   ← Filetype-specific settings
│   ├── c.lua
│   ├── go.lua
│   ├── rust.lua
│   └── ...
├── colors/                           ← Colorschemes
├── snippets/                         ← Code snippets
└── bin/                              ← Helper scripts
```

**Problem**: All of this is in one shared structure. When you sync both machines:
- Plugins designed for macOS (e.g., macvim fork) try to load on Linux → errors
- LSP paths differ (`/opt/homebrew/bin` on macOS vs `/usr/bin` on Linux)
- Shell/environment differences not handled

---

## Proposed New Structure

```
home/dot_config/nvim/
├── init.lua                          ← Entry point (unchanged)
├── lua/
│   ├── core/
│   │   ├── init.lua                  ← (unchanged)
│   │   ├── keymap.lua                ← (unchanged)
│   │   ├── options.lua               ← (unchanged)
│   │   ├── pack.lua                  ← (unchanged)
│   │   └── os_config.lua             ← NEW: OS-specific loader
│   ├── os/                           ← NEW: OS-specific directory
│   │   ├── macos.lua                 ← NEW: macOS overrides
│   │   ├── linux.lua                 ← NEW: Linux overrides
│   │   └── common.lua                ← NEW: Shared OS helpers
│   ├── modules/
│   │   ├── editor/
│   │   │   ├── config.lua            ← (unchanged)
│   │   │   ├── package.lua           ← (unchanged)
│   │   │   └── os_packages.lua       ← NEW: OS-specific packages
│   │   ├── lsp/
│   │   │   ├── config.lua            ← (unchanged)
│   │   │   ├── package.lua           ← (unchanged)
│   │   │   ├── os_paths.lua          ← NEW: OS-specific LSP paths
│   │   │   └── backend.lua
│   │   ├── tools/
│   │   └── ui/
│   ├── internal/
│   └── keymap/
├── after/ftplugin/
├── colors/
├── snippets/
├── bin/
└── dot_stylua.toml
```

### New Files to Create

1. `lua/core/os_config.lua` — OS detection + loader
2. `lua/os/macos.lua` — macOS-specific configs
3. `lua/os/linux.lua` — Linux-specific configs
4. `lua/os/common.lua` — Shared OS utilities
5. `lua/modules/editor/os_packages.lua` — OS-specific plugins
6. `lua/modules/lsp/os_paths.lua` — OS-specific LSP/tool paths
7. `lua/modules/tools/os_config.lua` — OS-specific tool configurations

---

## Implementation Plan

### Phase 1: Preparation (5 min)
- [ ] Document what breaks on each OS (create a test matrix)
- [ ] Backup current config
- [ ] Create branch in git

### Phase 2: Core OS Module (10 min)
- [ ] Create `lua/core/os_config.lua` (OS detection + router)
- [ ] Create `lua/os/macos.lua` (empty stub)
- [ ] Create `lua/os/linux.lua` (empty stub)
- [ ] Create `lua/os/common.lua` (shared utilities)
- [ ] Update `core/init.lua` to call `os_config.load()`
- [ ] Test that nvim still starts

### Phase 3: Identify Differences (15 min)
- [ ] Start with simple overrides (shell, Python path)
- [ ] Test each override on both machines
- [ ] Add more OS-specific configs gradually

### Phase 4: Package Splitting (20 min)
- [ ] Create `lua/modules/editor/os_packages.lua`
- [ ] Move OS-specific plugins there
- [ ] Update `lua/modules/editor/package.lua` to conditionally load

### Phase 5: LSP Path Configuration (10 min)
- [ ] Create `lua/modules/lsp/os_paths.lua`
- [ ] Set `vim.g.python3_host_prog`, LSP bin paths, etc.
- [ ] Test LSP functionality

### Phase 6: Testing & Documentation (15 min)
- [ ] Test full nvim startup on both systems
- [ ] Document which configs go where
- [ ] Create troubleshooting guide

---

## Step-by-Step Setup

### Step 1: Create Core OS Detection Module

Create **`home/dot_config/nvim/lua/core/os_config.lua`**:

```lua
-- lua/core/os_config.lua
-- Central OS detection and routing module

local M = {}

local function get_os()
  return vim.loop.os_uname().sysname
end

local function load_os_specific()
  local os = get_os()
  
  -- Load common utilities first
  require('os.common')
  
  -- Load OS-specific config
  if os == "Darwin" then
    require('os.macos')
  elseif os == "Linux" then
    require('os.linux')
  end
  
  vim.notify("Loaded config for: " .. os, vim.log.levels.INFO)
end

function M.load()
  load_os_specific()
end

-- Utility function to check OS from anywhere
function M.is_macos()
  return get_os() == "Darwin"
end

function M.is_linux()
  return get_os() == "Linux"
end

return M
```

### Step 2: Create OS-Specific Config Files

Create **`home/dot_config/nvim/lua/os/common.lua`** (shared utilities):

```lua
-- lua/os/common.lua
-- Shared OS-related utilities

local M = {}

-- Detect if executable exists
function M.executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Get executable path, with fallback
function M.find_executable(names)
  if type(names) == "string" then
    names = { names }
  end
  
  for _, name in ipairs(names) do
    if M.executable(name) then
      return vim.fn.exepath(name)
    end
  end
  
  return nil
end

-- Detect shell
function M.detect_shell()
  local shell = os.getenv("SHELL")
  if shell and M.executable(shell) then
    return shell
  end
  
  if M.executable("bash") then
    return "bash"
  end
  
  return "sh"
end

-- Log function
function M.log(msg, level)
  level = level or vim.log.levels.DEBUG
  vim.notify("[OS Config] " .. msg, level)
end

return M
```

Create **`home/dot_config/nvim/lua/os/macos.lua`** (macOS-specific):

```lua
-- lua/os/macos.lua
-- macOS-specific configurations

local os_common = require('os.common')
local o = vim.o
local g = vim.g

-- Shell configuration
o.shell = os_common.detect_shell()

-- macOS specific Python path
local python_paths = {
  "/usr/local/bin/python3",           -- Homebrew Intel
  "/opt/homebrew/bin/python3",        -- Homebrew Apple Silicon
  os.getenv("PYENV_ROOT") .. "/shims/python3",
}
for _, path in ipairs(python_paths) do
  if path and vim.fn.executable(path) == 1 then
    g.python3_host_prog = path
    break
  end
end

-- macOS specific Node path
local node_paths = {
  "/opt/homebrew/bin/node",           -- Homebrew Apple Silicon
  "/usr/local/bin/node",              -- Homebrew Intel
  os.getenv("NVM_DIR") .. "/versions/node/*/bin/node",
}
for _, path in ipairs(node_paths) do
  if path and vim.fn.executable(path) == 1 then
    g.node_host_prog = path
    break
  end
end

-- macOS keymaps (Command key bindings)
vim.keymap.set('n', '<D-s>', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<D-z>', ':undo<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<D-S-z>', ':redo<CR>', { noremap = true, silent = true })

-- Homebrew bin paths for tools (for telescope, ripgrep, fd, etc)
if os_common.executable('brew') then
  local brew_prefix = vim.fn.system('brew --prefix'):gsub('\n', '')
  vim.env.PATH = brew_prefix .. "/bin:" .. vim.env.PATH
end

-- macOS iTerm2/Alacritty integration (if needed)
-- Example: terminal-specific settings
if os.getenv("TERM_PROGRAM") == "iTerm.app" then
  o.guifont = "Hack Nerd Font:h12"
elseif os.getenv("TERM_PROGRAM") == "Alacritty" then
  o.guifont = "Hack Nerd Font:h11"
end

os_common.log("macOS config loaded", vim.log.levels.DEBUG)
```

Create **`home/dot_config/nvim/lua/os/linux.lua`** (Linux-specific):

```lua
-- lua/os/linux.lua
-- Linux-specific configurations

local os_common = require('os.common')
local o = vim.o
local g = vim.g

-- Shell configuration
o.shell = os_common.detect_shell()

-- Linux specific Python path
local python_paths = {
  "/usr/bin/python3",                 -- System Python
  "/usr/local/bin/python3",           -- Local Python
  os.getenv("PYENV_ROOT") .. "/shims/python3",
  os.getenv("HOME") .. "/.venv/bin/python3",
}
for _, path in ipairs(python_paths) do
  if path and vim.fn.executable(path) == 1 then
    g.python3_host_prog = path
    break
  end
end

-- Linux specific Node path
local node_paths = {
  "/usr/bin/node",
  "/usr/local/bin/node",
  os.getenv("NVM_DIR") .. "/versions/node/*/bin/node",
}
for _, path in ipairs(node_paths) do
  if path and vim.fn.executable(path) == 1 then
    g.node_host_prog = path
    break
  end
end

-- Linux-specific keymaps can go here if needed
-- vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, silent = true })

-- Linux terminal detection (Kitty, Alacritty, GNOME Terminal, etc.)
local term = os.getenv("TERM")
if term and term:match("kitty") then
  o.guifont = "Hack Nerd Font:h11"
elseif term and term:match("alacritty") then
  o.guifont = "Hack Nerd Font:h11"
else
  -- Fallback for other terminals
  o.guifont = "Monospace:h11"
end

-- Optional: Linux-specific font rendering
if vim.fn.has("nvim-0.9") == 1 then
  -- Guicursor settings for better rendering on Linux
  o.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50"
end

os_common.log("Linux config loaded", vim.log.levels.DEBUG)
```

### Step 3: Update Core Init to Load OS Config

Edit **`home/dot_config/nvim/lua/core/init.lua`**:

Add this line **after** the existing requires (after `require('core.pack'):boot_strap()`):

```lua
-- Before this line:
-- require('core.pack'):boot_strap()

-- Add this AFTER bootstrap:
require('core.os_config').load()

-- Before this line:
-- require('core.options')
```

Full updated section:

```lua
require('core.pack'):boot_strap()
require('core.os_config').load()  -- ← ADD THIS LINE
require('core.options')
require('core.keymap')
```

### Step 4: Create OS-Specific Plugin Packages

Create **`home/dot_config/nvim/lua/modules/editor/os_packages.lua`**:

```lua
-- lua/modules/editor/os_packages.lua
-- OS-specific plugin definitions

local os_common = require('os.common')

local function get_os_packages()
  if os_common.executable('uname') then
    local os_type = vim.fn.system('uname'):gsub('\n', '')
    
    if os_type == "Darwin" then
      return {
        -- macOS-specific plugins
        {
          'macvim-fork/macvim',
          optional = true,
        },
        -- macOS-specific LSP servers that may have different paths
        -- Can add platform-specific configs here
      }
    elseif os_type == "Linux" then
      return {
        -- Linux-specific plugins
        {
          'nvim-tree/nvim-tree.lua',  -- Example: might work better on Linux
          optional = true,
        },
        -- Linux-specific tools/plugins
      }
    end
  end
  
  return {}
end

return get_os_packages()
```

Update **`home/dot_config/nvim/lua/modules/editor/package.lua`** to include OS-specific packages:

```lua
-- Add at the top of the file:
local os_packages = require('modules.editor.os_packages')

-- Then add OS packages to the main packadd calls
-- (After all the existing packadd calls, add:)

for _, pkg in ipairs(os_packages) do
  packadd(pkg)
end
```

### Step 5: Create LSP Path Configuration

Create **`home/dot_config/nvim/lua/modules/lsp/os_paths.lua`**:

```lua
-- lua/modules/lsp/os_paths.lua
-- OS-specific LSP server paths and configurations

local os_common = require('os.common')

local M = {}

local function setup_macos()
  return {
    -- Go LSP
    gopls = {
      cmd = { os_common.find_executable("gopls") or "gopls" },
    },
    -- Rust LSP
    rust_analyzer = {
      cmd = { os_common.find_executable("rust-analyzer") or "rust-analyzer" },
    },
    -- Python LSP
    pyright = {
      cmd = { os_common.find_executable("pyright-langserver") or "pyright-langserver", "--stdio" },
    },
    -- Lua LSP (macOS via Homebrew)
    lua_ls = {
      cmd = { os_common.find_executable("lua-language-server") or "lua-language-server" },
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = vim.split(package.path, ';'),
          },
          diagnostics = {
            globals = { 'vim', 'use', 'describe', 'it', 'assert', 'before_each', 'after_each' },
          },
        },
      },
    },
  }
end

local function setup_linux()
  return {
    -- Go LSP
    gopls = {
      cmd = { os_common.find_executable("gopls") or "gopls" },
    },
    -- Rust LSP
    rust_analyzer = {
      cmd = { os_common.find_executable("rust-analyzer") or "rust-analyzer" },
    },
    -- Python LSP (system python-lsp-server or pyright)
    pyright = {
      cmd = { os_common.find_executable("pyright-langserver") or "pyright-langserver", "--stdio" },
    },
    -- Lua LSP
    lua_ls = {
      cmd = { os_common.find_executable("lua-language-server") or "lua-language-server" },
      settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
            path = vim.split(package.path, ';'),
          },
          diagnostics = {
            globals = { 'vim', 'use', 'describe', 'it', 'assert', 'before_each', 'after_each' },
          },
        },
      },
    },
  }
end

function M.get_lsp_config()
  if vim.loop.os_uname().sysname == "Darwin" then
    return setup_macos()
  else
    return setup_linux()
  end
end

return M
```

Then update **`home/dot_config/nvim/lua/modules/lsp/config.lua`** or **`backend.lua`** to use this:

```lua
-- In your LSP setup (usually in backend.lua or config.lua):
local os_paths = require('modules.lsp.os_paths')
local lsp_configs = os_paths.get_lsp_config()

-- When setting up each LSP server:
local config = lsp_configs.gopls or {}  -- Falls back to empty if not in config
```

### Step 6: Update init.lua Entry Point (if needed)

If you want to add a template-based approach for maximum flexibility, convert **`home/dot_config/nvim/init.lua`** to **`home/dot_config/nvim/init.lua.tmpl`**:

```lua
vim.loader.enable()
vim.o.autoread = true

-- Load Modules
require('core')
require('internal.event')

{{ if eq .chezmoi.os "darwin" }}
-- macOS specific init code (optional)
{{ else if eq .chezmoi.os "linux" }}
-- Linux specific init code (optional)
{{ end }}
```

Then run:
```bash
cd ~/.config/dotfiles
chezmoi apply --refresh
```

---

## Common Patterns & Use Cases

### Pattern 1: Different Plugins Per OS

```lua
-- lua/modules/editor/os_packages.lua
local function get_os_packages()
  if os_common.executable('uname') then
    local os_type = vim.fn.system('uname'):gsub('\n', '')
    
    if os_type == "Darwin" then
      return {
        { 'macvim-fork/macvim' },
      }
    elseif os_type == "Linux" then
      return {
        { 'neovide/neovide' },  -- Neovide for Linux
      }
    end
  end
  return {}
end
```

### Pattern 2: Conditional Keymaps

```lua
-- lua/os/macos.lua
if os_common.is_macos() then
  -- Command key on macOS
  vim.keymap.set('n', '<D-s>', ':w<CR>')
end

-- lua/os/linux.lua
if os_common.is_linux() then
  -- Ctrl key on Linux
  vim.keymap.set('n', '<C-s>', ':w<CR>')
end
```

### Pattern 3: Different Tool Paths

```lua
-- lua/os/macos.lua
local function setup_paths()
  if os_common.executable('brew') then
    local prefix = vim.fn.system('brew --prefix'):gsub('\n', '')
    vim.env.PATH = prefix .. "/bin:" .. vim.env.PATH
  end
end

-- lua/os/linux.lua
local function setup_paths()
  if os.getenv("PYENV_ROOT") then
    local pyenv_root = os.getenv("PYENV_ROOT")
    vim.env.PATH = pyenv_root .. "/bin:" .. vim.env.PATH
  end
end
```

### Pattern 4: Font Configuration Per Terminal

```lua
-- lua/os/macos.lua
local term = os.getenv("TERM_PROGRAM")
if term == "iTerm.app" then
  vim.o.guifont = "Hack Nerd Font:h12"
elseif term == "Alacritty" then
  vim.o.guifont = "Hack Nerd Font:h11"
end

-- lua/os/linux.lua
local term = os.getenv("TERM")
if term == "alacritty" then
  vim.o.guifont = "Hack Nerd Font Mono:h11"
elseif term == "kitty" then
  vim.o.guifont = "Hack Nerd Font:h10"
end
```

### Pattern 5: Conditional Dependencies

```lua
-- lua/modules/tools/os_config.lua
local function setup_debugger()
  local os = vim.loop.os_uname().sysname
  
  if os == "Darwin" then
    -- macOS: use lldb
    return {
      dap_config = {
        type = 'lldb',
        request = 'launch',
      }
    }
  else
    -- Linux: use gdb
    return {
      dap_config = {
        type = 'gdb',
        request = 'launch',
      }
    }
  end
end
```

---

## Testing & Verification

### Test Checklist

```bash
# On macOS
1. nvim --version                          # Should start without errors
2. :lua print(require('os.common').is_macos())  # Should print true
3. :echo g:python3_host_prog              # Should show macOS Python path
4. :LspInfo                               # Check LSP servers loaded
5. :Telescope find_files                  # Check plugins work
6. Test macOS-specific keymaps (Cmd+S, etc)

# On Linux
1. nvim --version
2. :lua print(require('os.common').is_linux())  # Should print true
3. :echo g:python3_host_prog              # Should show Linux Python path
4. :LspInfo
5. :Telescope find_files
6. Test Linux-specific settings
```

### Debug Commands

```lua
-- Check which OS detected
:lua print(vim.loop.os_uname().sysname)

-- Check loaded modules
:lua print(require('core.os_config').is_macos() and "macOS" or "Linux")

-- Inspect PATH
:echo $PATH

-- Check Python host
:echo g:python3_host_prog

-- View all set options
:set all
```

### Troubleshooting Commands

```bash
# Check if files exist
ls -la ~/.config/nvim/lua/os/

# Check syntax of Lua files
luac -p ~/.config/nvim/lua/os/macos.lua
luac -p ~/.config/nvim/lua/os/linux.lua

# Render templates with chezmoi
chezmoi execute-template 'echo {{ .chezmoi.os }}'

# See what chezmoi would apply
chezmoi diff
```

---

## Troubleshooting

### Issue 1: Nvim won't start after changes

**Symptom**: `Error: require('os.common'): module not found`

**Solution**:
```bash
# 1. Check file paths are correct
find ~/.config/nvim -name "os_config.lua"

# 2. Check Lua syntax
lua -c ~/.config/nvim/lua/core/os_config.lua

# 3. Check require paths in init.lua
cat ~/.config/nvim/lua/core/init.lua | grep require

# 4. Restart nvim and check error message
nvim 2>&1 | head -20
```

### Issue 2: OS detection returns nil/wrong value

**Symptom**: `:lua print(vim.loop.os_uname().sysname)` shows unexpected value

**Solution**:
```lua
-- Test the actual return value
:lua = vim.loop.os_uname()

-- Check Darwin vs darwin capitalization
-- macOS returns "Darwin" (capital D)
-- Linux returns "Linux"
-- Windows returns "Windows"
```

### Issue 3: LSP paths not working on one OS

**Symptom**: LSP works on macOS but not Linux (or vice versa)

**Solution**:
```bash
# 1. Check if binary exists
which gopls
which rust-analyzer

# 2. Check if binary is in PATH
echo $PATH

# 3. Manually set path in os-specific file
# Edit lua/os/linux.lua and hardcode the path for debugging
g.python3_host_prog = "/usr/bin/python3"  -- Debug line

# 4. Check LSP setup in :LspInfo
:LspInfo
```

### Issue 4: Plugins fail to load on one OS

**Symptom**: Plugin loads on macOS but not Linux

**Solution**:
```lua
-- 1. Check if plugin has OS requirements
-- vim-plug or lazy.nvim may skip optional plugins

-- 2. Add conditional skip
packadd({
  'plugin/name',
  cond = function()
    return not vim.loop.os_uname().sysname == "Linux"  -- Skip on Linux
  end
})

-- 3. Log what's loading
vim.notify("Loading plugin X on " .. vim.loop.os_uname().sysname)
```

### Issue 5: Keymaps not working on Linux

**Symptom**: `<D-s>` works on macOS but `<C-s>` not working on Linux

**Solution**:
```bash
# 1. Check terminal capabilities
infocmp alacritty  # If using Alacritty
infocmp kitty      # If using Kitty

# 2. Test keybinding in terminal emulator settings
# Some terminals don't pass all key combinations to nvim

# 3. Use different keybindings that work universally
# <C-g> is safer than <D-s> or <C-s>
```

---

## Rollback Strategy

If something breaks, here's how to recover:

### Quick Rollback (last 5 min)

```bash
# 1. Stop nvim
# 2. Remove the new os files
rm ~/.config/nvim/lua/core/os_config.lua
rm -rf ~/.config/nvim/lua/os/

# 3. Revert core/init.lua changes
# Remove the line: require('core.os_config').load()

# 4. Restart nvim
nvim

# 5. If still broken, restore from git
cd ~/.config/dotfiles
git checkout home/dot_config/nvim/
chezmoi apply
```

### Git-Based Rollback

```bash
# Create a backup branch before major changes
cd ~/.config/dotfiles
git checkout -b nvim-os-split-backup

# Make changes on main branch
git checkout main

# If needed, recover from backup
git diff backup..main  # See what changed
git checkout backup    # Go back to backup

# Cherry-pick specific commits
git cherry-pick <commit-hash>
```

### Safe Testing Strategy

1. **Start on one machine** (e.g., Linux)
2. **Test thoroughly** before pushing to git
3. **Then test on macOS** after pulling
4. **Keep both machines in sync** before major changes

```bash
# Recommended workflow
chezmoi cd                    # Enter repo
git status                    # Check what changed
chezmoi diff                  # See what will be applied
chezmoi apply                 # Apply carefully
# Test manually
nvim -c ':LspInfo' -c 'q'     # Quick test
# If good, commit and sync
git add -A
git commit -m "Feat: OS-specific nvim config"
git push
```

---

## File Checklist

### What to Create

- [ ] `home/dot_config/nvim/lua/core/os_config.lua` — OS router
- [ ] `home/dot_config/nvim/lua/os/common.lua` — Shared utilities
- [ ] `home/dot_config/nvim/lua/os/macos.lua` — macOS config
- [ ] `home/dot_config/nvim/lua/os/linux.lua` — Linux config
- [ ] `home/dot_config/nvim/lua/modules/editor/os_packages.lua` — OS-specific plugins
- [ ] `home/dot_config/nvim/lua/modules/lsp/os_paths.lua` — LSP paths

### What to Modify

- [ ] `home/dot_config/nvim/lua/core/init.lua` — Add OS loader call
- [ ] `home/dot_config/nvim/lua/modules/editor/package.lua` — Add OS packages
- [ ] `home/dot_config/nvim/lua/modules/lsp/config.lua` — Use OS paths
- [ ] (Optional) `home/dot_config/nvim/init.lua` → `init.lua.tmpl` for template-based approach

### What NOT to Modify

- Keep all other `.lua` files unchanged
- Don't modify version control files
- Don't rename existing files

---

## Summary: The Workflow Going Forward

Once set up:

```bash
# Making macOS-only changes
1. Edit lua/os/macos.lua
2. Test on macOS
3. Push to git

# Making Linux-only changes
1. Edit lua/os/linux.lua
2. Test on Linux
3. Push to git

# Making shared changes
1. Edit lua/core/init.lua or lua/modules/
2. Test on BOTH macOS and Linux
3. Push to git

# Syncing to other machine
1. git pull (or chezmoi git pull)
2. chezmoi apply
3. Restart nvim
```

---

## References

- [Chezmoi OS Detection](https://www.chezmoi.io/reference/templates/functions/os/)
- [Chezmoi Templates](https://www.chezmoi.io/user-guide/use-templates/)
- [Vim os_uname() Docs](https://neovim.io/doc/user/builtin.html#getpid)
- [Neovim Lua API](https://neovim.io/doc/user/api.html)

