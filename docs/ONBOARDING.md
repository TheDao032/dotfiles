# Onboarding — bootstrap a new machine

Estimated time: **5 minutes** (excluding `brew bundle` install time, ~10-30 min depending on what's already installed).

## Prerequisites

- macOS 13+ on Apple Silicon (M1/M2/M3/M4) OR Intel Mac OR Linux (Ubuntu 22.04+ / Fedora 38+)
- A copy of the **age private key** from your password manager (entry: "chezmoi age key" or similar)

## Steps

### 1. Install chezmoi + age

**macOS** (assumes Homebrew is installed; if not, the chezmoi script installs it):
```bash
brew install chezmoi age
```

**Linux**:
```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
# then install age via your package manager:
sudo apt install age   # Debian/Ubuntu
sudo dnf install age   # Fedora
```

### 2. Restore the age private key

From your password manager, copy the age private key content (starts with `# created:` and `AGE-SECRET-KEY-1...`) to:

```bash
mkdir -p ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/key.txt    # paste contents
chmod 600 ~/.config/chezmoi/key.txt
```

The file should look like:
```
# created: 2026-05-22T07:41:00+07:00
# public key: age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4
AGE-SECRET-KEY-1...
```

**Verify**:
```bash
grep '^# public key:' ~/.config/chezmoi/key.txt
# should print:
# # public key: age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4
```

If you don't have the private key and need to regenerate, see [docs/ADDING-A-SECRET.md](./ADDING-A-SECRET.md#rotating-the-age-key).

### 3. Init + apply

```bash
chezmoi init --apply git@github.com:TheDao032/dotfiles.git
```

This does, in order:
1. Clones the repo to `~/.local/share/chezmoi/` (chezmoi's default source dir)
2. Renders `.chezmoi.toml.tmpl` → `~/.config/chezmoi/chezmoi.toml`
3. **macOS only** — Runs `run_onchange_before_install-brew.sh.tmpl` → installs Homebrew if missing
4. Renders + writes all files under `home/` to `$HOME`:
   - `~/.zshrc`, `~/.zprofile`, `~/.gitconfig`, `~/.ssh/config`, etc.
   - `~/.config/nvim/*` (lua config, snippets, colorschemes)
   - `~/.config/git/hooks/pre-commit` (gitleaks pre-commit hook, executable)
   - `~/.config/apt-packages` (Linux package list — no-op on macOS)
   - Decrypts `encrypted_private_dot_envrc.private` → `~/.envrc.private`
5. Installs CLI tools (auto-detects the OS):
   - **macOS** — `run_onchange_after_install-brew-bundle.sh.tmpl` → `brew bundle ~/.Brewfile`
   - **Linux** — `run_onchange_after_install-linux-packages.sh.tmpl` → reconciles `~/.config/apt-packages` via `apt-get`/`dnf`/`pacman` (uses `sudo`; will prompt for password)
6. Runs `run_once_after_install-oh-my-zsh.sh.tmpl` → installs oh-my-zsh (on Linux this will also `apt/dnf/pacman install zsh git` if either is missing)
7. Runs `run_once_after_install-vagrant-qemu-plugin.sh.tmpl` → installs vagrant-qemu

### 4. Open a new shell

```bash
exec zsh -l
```

You should see your usual prompt, with all aliases + env vars in place.

### 5. Verify

```bash
# Templates rendered correctly?
chezmoi diff                           # should be empty

# Secrets decrypted?
[ -f ~/.envrc.private ] && echo "ok" || echo "MISSING"

# gpakosz/.tmux pulled?
ls ~/.config/tmux/tmux.conf            # should exist
head -3 ~/.config/tmux/tmux.conf       # should say "gpakosz/.tmux"

# Packages installed?
# macOS:
brew bundle check --file=~/.Brewfile   # should say "satisfied"
# Linux:
which rg fzf bat jq gh delta gitleaks  # should all print paths

# nvim config rendered?
ls ~/.config/nvim/init.lua             # should exist

# Pre-commit hook deployed + git uses it?
ls -la ~/.config/git/hooks/pre-commit  # should be executable
git config --global --get core.hooksPath
# expect: ~/.config/git/hooks

# Try a real-shape fake leak in /tmp to confirm hook blocks it:
( cd /tmp && rm -rf hook-check && mkdir hook-check && cd hook-check && \
  git init -q && git commit -q --allow-empty -m init && \
  printf 'token: ghp_%s\n' "$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 36)" > s.txt && \
  git add s.txt && git commit -m 'should-block' 2>&1 | tail -3 && \
  git log --oneline )
# expected: gitleaks finds 1 leak, commit aborted, log shows only the init commit.

# Vagrant plugin?
vagrant plugin list | grep qemu        # should show vagrant-qemu
```

If any of these fail, see [troubleshooting](#troubleshooting) below.

## Troubleshooting

### "Encrypted file but no recipient configured"
Your age private key isn't in `~/.config/chezmoi/key.txt`. Go back to step 2.

### "could not read recipient"
The age recipient in `~/.config/chezmoi/chezmoi.toml` doesn't match the key. Either restore the matching key OR update the recipient (and re-encrypt all `encrypted_*` files).

### `chezmoi apply` hangs at "Pulling external"
GitHub rate limit. Either wait, or pin a specific tag of gpakosz/.tmux in `.chezmoiexternal.toml` (use `tag=v3.6` instead of `branch=master`).

### Brew bundle install fails partway
Just re-run `brew bundle --file=~/.Brewfile`. It's idempotent.

### Want to skip a per-machine package
Add it to `~/.chezmoiignore.local` (TODO: not yet implemented; for now edit `.Brewfile` or wrap in a `{{- if eq .machine.role "..." }}` template).
