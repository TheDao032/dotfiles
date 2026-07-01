-- core.platform — single source of truth for OS/distro differences.
--
-- Everything OS-specific in this config lives HERE so the rest stays portable
-- across macOS / NixOS / Ubuntu / other Linux. Detected once at startup.
--
-- Usage:
--   local platform = require('core.platform')
--   if platform.clipboard then vim.g.clipboard = platform.clipboard end
--   dartSdkPath = platform.dart_sdk

local uname = vim.uv.os_uname()

local M = {}

M.sysname    = uname.sysname                      -- 'Darwin' | 'Linux' | 'Windows_NT'
M.is_mac     = uname.sysname == 'Darwin'
M.is_linux   = uname.sysname == 'Linux'
M.is_windows = uname.sysname:find('Windows') ~= nil
M.is_wayland = (vim.env.WAYLAND_DISPLAY or '') ~= ''

-- Linux distro id from /etc/os-release ('nixos' | 'ubuntu' | 'debian' | 'arch' | ...).
-- nil on non-Linux or when unreadable.
local function detect_distro()
  if not M.is_linux then
    return nil
  end
  local f = io.open('/etc/os-release', 'r')
  if not f then
    return nil
  end
  local id
  for line in f:lines() do
    id = line:match('^ID=(.+)$')
    if id then
      break
    end
  end
  f:close()
  return id and id:gsub('"', '') or nil
end
M.distro = detect_distro()

local function has(exe)
  return vim.fn.executable(exe) == 1
end

-- Full path to `name` if on PATH, else `fallback`.
local function exe_or(name, fallback)
  local p = vim.fn.exepath(name)
  return (p ~= nil and p ~= '') and p or fallback
end
M.exe_or = exe_or

-- ---------------------------------------------------------------------------
-- Clipboard provider. Returns a `vim.g.clipboard` table, or nil to let neovim
-- auto-detect (its built-in detection already handles most Linux setups).
-- ---------------------------------------------------------------------------
local function detect_clipboard()
  if M.is_mac then
    return {
      name = 'macOS-clipboard',
      copy = { ['+'] = 'pbcopy', ['*'] = 'pbcopy' },
      paste = { ['+'] = 'pbpaste', ['*'] = 'pbpaste' },
      cache_enabled = 0,
    }
  end

  if M.is_linux then
    if M.is_wayland and has('wl-copy') then
      return {
        name = 'wl-clipboard',
        copy = { ['+'] = 'wl-copy', ['*'] = 'wl-copy' },
        paste = {
          ['+'] = { 'wl-paste', '--no-newline' },
          ['*'] = { 'wl-paste', '--no-newline' },
        },
        cache_enabled = 0,
      }
    end
    if has('xclip') then
      return {
        name = 'xclip',
        copy = {
          ['+'] = 'xclip -selection clipboard',
          ['*'] = 'xclip -selection primary',
        },
        paste = {
          ['+'] = 'xclip -selection clipboard -o',
          ['*'] = 'xclip -selection primary -o',
        },
        cache_enabled = 0,
      }
    end
    if has('xsel') then
      return {
        name = 'xsel',
        copy = {
          ['+'] = 'xsel --clipboard --input',
          ['*'] = 'xsel --primary --input',
        },
        paste = {
          ['+'] = 'xsel --clipboard --output',
          ['*'] = 'xsel --primary --output',
        },
        cache_enabled = 0,
      }
    end
  end

  -- Windows, or Linux with no clipboard tool installed → let neovim decide.
  return nil
end
M.clipboard = detect_clipboard()

-- ---------------------------------------------------------------------------
-- Flutter / Dart SDK binary paths. macOS = Homebrew; elsewhere = PATH.
-- ---------------------------------------------------------------------------
M.flutter_sdk = M.is_mac and '/opt/homebrew/bin/flutter' or exe_or('flutter', 'flutter')
M.dart_sdk = M.is_mac and '/opt/homebrew/bin/dart' or exe_or('dart', 'dart')

return M
