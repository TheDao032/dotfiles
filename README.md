# dotfiles — managed by chezmoi

My personal dotfiles for macOS (Apple Silicon + Intel) and Linux.
Managed with [chezmoi](https://www.chezmoi.io/), secrets encrypted with [age](https://age-encryption.org/).

## Bootstrap a new machine (5 minutes)

```bash
# 1. Install chezmoi (no other deps required yet)
brew install chezmoi age   # macOS
# OR on Linux:
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. Restore your age private key (from password manager) to:
#    ~/.config/chezmoi/key.txt
#    chmod 600 ~/.config/chezmoi/key.txt

# 3. Init from this repo and apply
chezmoi init --apply git@github.com:TheDao032/dotfiles.git
```

That's it. After step 3 you have:
- `~/.zshrc` rendered from `home/dot_zshrc.tmpl` (templated per OS/arch)
- `~/.gitconfig`, `~/.zprofile`, `~/.ssh/config`, etc.
- `~/.Brewfile` + `brew bundle` auto-run → all CLI tools installed
- `oh-my-zsh` auto-installed
- `vagrant-qemu` plugin auto-installed
- gpakosz/.tmux pulled fresh, your customizations applied
- All secrets decrypted from `~/.envrc.private`

## Daily workflow

```bash
chezmoi edit ~/.zshrc          # edit the source template, NOT ~/.zshrc directly
chezmoi diff                   # see what would change in $HOME
chezmoi apply                  # apply changes to $HOME
chezmoi apply --refresh-externals    # also re-pull gpakosz/.tmux from upstream

# Sync to/from remote
chezmoi git -- pull --rebase
chezmoi git -- push
```

## Add a new secret

```bash
chezmoi edit ~/.envrc.private    # decrypts → opens in $EDITOR → re-encrypts on save
# add: export NEW_TOKEN="..."
chezmoi apply                    # re-renders ~/.envrc.private
source ~/.zshrc                  # new env var in current shell
```

## Repository layout

```
~/.config/dotfiles/              ← chezmoi source dir
├── .chezmoiroot                  → "home" (everything under home/ → $HOME)
├── .chezmoiignore                → README, docs, etc. (not deployed)
├── .chezmoidata.toml             → global vars (user, paths, tool prefs)
├── .chezmoiexternal.toml         → gpakosz/.tmux external archive
├── .chezmoi.toml.tmpl            → rendered to ~/.config/chezmoi/chezmoi.toml
│
├── home/                         → rendered to $HOME
│   ├── dot_zshrc.tmpl                  → ~/.zshrc
│   ├── dot_zprofile.tmpl               → ~/.zprofile
│   ├── dot_gitconfig.tmpl              → ~/.gitconfig
│   ├── dot_gitignore                   → ~/.gitignore
│   ├── dot_Brewfile                    → ~/.Brewfile
│   ├── private_dot_ssh/
│   │   └── config.tmpl                 → ~/.ssh/config (chmod 700 parent)
│   ├── encrypted_private_dot_envrc.age → ~/.envrc.private (age-decrypted)
│   ├── dot_config/
│   │   └── tmux/
│   │       └── tmux.conf.local         → ~/.config/tmux/tmux.conf.local
│   │       (tmux.conf comes from gpakosz external)
│   └── .chezmoiscripts/                → chezmoi-managed install/update scripts
│       ├── run_onchange_before_install-brew.sh.tmpl
│       ├── run_onchange_after_install-brew-bundle.sh.tmpl
│       ├── run_once_after_install-oh-my-zsh.sh.tmpl
│       └── run_once_after_install-vagrant-qemu-plugin.sh.tmpl
│
└── docs/
    ├── ONBOARDING.md             ← 5-minute new-machine guide
    ├── ADDING-A-SECRET.md        ← how to encrypt a new secret
    └── MIGRATION-LOG.md          ← what changed from the pre-2026-05-22 layout
```

## Documentation

**👉 Start here if you've never used chezmoi**:
- [**docs/CHEZMOI-CONCEPTS.md**](docs/CHEZMOI-CONCEPTS.md) — concept-first guide; read once and you'll understand every file in this repo

Operational docs:
- [docs/ONBOARDING.md](docs/ONBOARDING.md) — bootstrap a new machine end-to-end
- [docs/ADDING-A-SECRET.md](docs/ADDING-A-SECRET.md) — encrypt / rotate a secret
- [docs/SECURITY.md](docs/SECURITY.md) — threat model, what protects what, incident response

Project history:
- [docs/CLOSEOUT-SUMMARY.md](docs/CLOSEOUT-SUMMARY.md) — 3-min exec summary of the 2026-05 restructure
- [docs/MIGRATION-LOG.md](docs/MIGRATION-LOG.md) — full restructure history + secret-rotation table

## Naming conventions (chezmoi)

| Source name | Renders to | Notes |
|---|---|---|
| `dot_X` | `~/.X` | dotfile prefix |
| `private_X` | `~/.X`, chmod 700 | for `.ssh/`, `.gnupg/` |
| `executable_X` | `~/.X`, chmod +x | scripts |
| `X.tmpl` | `~/.X` (rendered) | Go template |
| `encrypted_X` | `~/.X` (decrypted) | age/gpg encrypted |
| `run_once_*` | (executed) | runs once per machine |
| `run_onchange_*` | (executed on change) | re-runs when content changes |

See [chezmoi docs](https://www.chezmoi.io/reference/source-state-attributes/) for the full list.

## License

Personal config; not for redistribution.
