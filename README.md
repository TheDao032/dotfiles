# dotfiles — managed by chezmoi

My personal dotfiles for macOS (Apple Silicon + Intel) and Linux.
Managed with [chezmoi](https://www.chezmoi.io/), secrets encrypted with [age](https://age-encryption.org/).

## Setup

There are **two** scenarios — pick the one that matches you:

- **A. First-time setup** — establishing these dotfiles + age encryption from scratch, when **no age key exists yet**. Do this **once, ever**.
- **B. New machine** — the repo and age key already exist; you're onboarding another box. This is the common case (~5 minutes).

> ⚠️ **On a new machine, RESTORE the existing age key — do NOT generate a new one.**
> The repo's encrypted files are locked to the recipient `age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4`.
> A freshly generated key will **not** decrypt them. Only generate a key for scenario A (or a deliberate key rotation — see [docs/ADDING-A-SECRET.md](docs/ADDING-A-SECRET.md#rotating-the-age-key)).

### A. First-time setup — establish the age key (once, ever)

This is the step people forget: **the age keypair must exist before chezmoi can encrypt/decrypt anything.**

```bash
# 1. Install chezmoi + age
brew install chezmoi age                       # macOS
# OR on Linux:
sh -c "$(curl -fsLS get.chezmoi.io)" && sudo apt install age   # (dnf/pacman on Fedora/Arch)

# 2. Generate the age keypair  ← the "create the private key first" step
mkdir -p ~/.config/chezmoi
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
#   age-keygen prints:  Public key: age1........   ← this is your RECIPIENT

# 3. Wire the PUBLIC key into chezmoi's encryption config:
#    edit  home/.chezmoi.toml.tmpl  →  [age] recipient = "<public key from step 2>"
#    (the identity/private-key path is already ~/.config/chezmoi/key.txt)

# 4. Back up the PRIVATE key to your password manager IMMEDIATELY
#    Entry "chezmoi age key" ← paste the full contents of ~/.config/chezmoi/key.txt
#    (starts with `# created:` / `# public key:` / `AGE-SECRET-KEY-1...`)

# 5. Encrypt your secrets and apply
chezmoi add --encrypt ~/.envrc.private         # → home/encrypted_private_dot_envrc.private
chezmoi apply
```

> 🔑 **Losing the private key = losing every encrypted secret.** Step 4 is not optional.

### B. New machine — key already exists (the common case)

```bash
# 1. Install chezmoi + age
brew install chezmoi age                       # macOS
# OR on Linux:
sh -c "$(curl -fsLS get.chezmoi.io)" && sudo apt install age

# 2. RESTORE your age private key from your password manager
mkdir -p ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/key.txt              # paste the saved key contents
chmod 600 ~/.config/chezmoi/key.txt
#    verify it's the right key (must match the repo's recipient):
grep '^# public key:' ~/.config/chezmoi/key.txt
#    → age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4

# 3. Init from this repo and apply
#    `chezmoi init` CLONES the repo into ~/.local/share/chezmoi AND renders the
#    config template home/.chezmoi.toml.tmpl → ~/.config/chezmoi/chezmoi.toml.
#    You do NOT hand-write chezmoi.toml — init generates it (that's where
#    `encryption = "age"` comes from). `--apply` then applies in the same step.
chezmoi init --apply git@github.com:TheDao032/dotfiles.git

# 4. Verify the clone + config actually happened (see Troubleshooting if not):
chezmoi git -- log --oneline -1          # must show a commit, NOT "no commits yet"
test -f ~/.config/chezmoi/chezmoi.toml && echo "config generated ✓"
```

> ⚠️ **Do NOT run a bare `chezmoi init` (no URL) first.** It creates an *empty*
> `~/.local/share/chezmoi` git repo, and a later `chezmoi init <url>` will **not**
> clone into the now-existing directory — leaving you with no files and no config,
> which surfaces as `chezmoi: encryption not configured` on apply. See Troubleshooting.

That's it. After step 3 you have:
- `~/.zshrc` rendered from `home/dot_zshrc.tmpl` (templated per OS/arch)
- `~/.gitconfig`, `~/.zprofile`, `~/.ssh/config`, etc.
- **macOS**: `~/.Brewfile` + `brew bundle` auto-run → all CLI tools installed
- **Linux**: `~/.config/apt-packages` + apt/dnf/pacman auto-installs the same toolset
- `~/.config/nvim/` rendered (lua config, snippets, colorschemes — all chezmoi-managed)
- `~/.config/git/hooks/pre-commit` deployed — runs `gitleaks protect --staged` on every commit
- `oh-my-zsh` auto-installed (auto-installs `zsh`+`git` first on Linux if missing)
- `vagrant-qemu` plugin auto-installed
- gpakosz/.tmux pulled fresh, your customizations applied
- All secrets decrypted from `~/.envrc.private`

## Troubleshooting

### `chezmoi: encryption not configured` on apply

This almost always means **`chezmoi init` never actually cloned the repo**, so the
config template was never rendered and `encryption = "age"` was never set. Confirm:

```bash
chezmoi git -- log --oneline -1        # "your current branch 'main' does not have any
                                       #  commits yet"  →  the clone is empty/broken
ls ~/.local/share/chezmoi              # only a .git folder, no files  →  same problem
ls ~/.config/chezmoi/chezmoi.toml      # missing  →  init didn't render the config template
```

Fix — remove the empty source dir and re-init from the URL (the empty dir is what
blocks the clone; your age key at `~/.config/chezmoi/key.txt` is untouched):

```bash
rm -rf ~/.local/share/chezmoi
chezmoi init --apply git@github.com:TheDao032/dotfiles.git
chezmoi git -- log --oneline -1        # now shows a real commit
```

> Root cause seen on 2026-07-04: a bare `chezmoi init` (or an HTTPS init that failed
> auth) had left an empty `~/.local/share/chezmoi`; the follow-up `chezmoi init <url>`
> saw the directory already existed and skipped cloning. Always start from a clean
> state, and verify with `chezmoi git -- log` right after init.

### `brew bundle` fails during apply

`.chezmoiscripts/run_onchange_after_install-brew-bundle.sh.tmpl` runs `brew bundle`
with `set -euo pipefail`, so **any** failing Brewfile entry fails the whole `chezmoi apply`.

- **`No available formula with the name "<x>"`** — a `cask "<x>"` was removed from
  Homebrew. `brew bundle` falls back to a formula, finds none, and aborts. Comment the
  entry out in `chezmoi edit ~/.Brewfile` (this happened with `pdk`, 2026-07-04).
- **`hashicorp/tap/vagrant: formula requires at least a URL` / `Treating vagrant as a
  cask`** — cosmetic tap-scan noise on **all** Macs (Intel included). The `Treating …
  as a cask` line means Homebrew recovered; this does **not** fail the bundle. Ignore it.
- After fixing the Brewfile, re-run: `chezmoi apply --force` (forces the `run_onchange`
  script to re-fire even if the hash is unchanged).

### Intel vs Apple Silicon

Homebrew lives at `/usr/local` on Intel and `/opt/homebrew` on Apple Silicon. The
templates already branch on `.chezmoi.arch` (`arm64` vs everything else) in
`dot_zprofile.tmpl`, `dot_zshrc.tmpl`, and the brew install script — no per-machine
edits needed. If a tool's path looks wrong, check `chezmoi execute-template '{{ .chezmoi.arch }}'`
returns what you expect (`amd64` on this Intel MacBook Pro 2018).

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
│   ├── encrypted_private_dot_envrc.private → ~/.envrc.private (age-decrypted)
│   ├── dot_config/
│   │   ├── apt-packages                   → ~/.config/apt-packages (Linux pkg list — apt/dnf/pacman)
│   │   ├── tmux/
│   │   │   └── tmux.conf.local         → ~/.config/tmux/tmux.conf.local
│   │   │   (tmux.conf comes from gpakosz external)
│   │   ├── git/
│   │   │   └── hooks/
│   │   │       └── executable_pre-commit → ~/.config/git/hooks/pre-commit (gitleaks scan)
│   │   └── nvim/                       → ~/.config/nvim/
│   │       ├── init.lua                → ~/.config/nvim/init.lua
│   │       ├── lua/                    → ~/.config/nvim/lua/
│   │       ├── after/                  → ~/.config/nvim/after/
│   │       ├── colors/                 → ~/.config/nvim/colors/
│   │       ├── snippets/, static/, template/, bin/
│   │       ├── dot_stylua.toml         → ~/.config/nvim/.stylua.toml
│   │       ├── dot_styluaignore        → ~/.config/nvim/.styluaignore
│   │       ├── dot_claude/             → ~/.config/nvim/.claude/
│   │       └── dot_github/             → ~/.config/nvim/.github/
│   └── .chezmoiscripts/                → chezmoi-managed install/update scripts
│       ├── run_onchange_before_install-brew.sh.tmpl              (macOS)
│       ├── run_onchange_after_install-brew-bundle.sh.tmpl        (macOS)
│       ├── run_onchange_after_install-linux-packages.sh.tmpl     (Linux — apt/dnf/pacman)
│       ├── run_once_after_install-oh-my-zsh.sh.tmpl              (auto-installs zsh+git on Linux)
│       ├── run_once_after_install-vagrant-qemu-plugin.sh.tmpl
│       └── run_onchange_after_link-gpakosz-tmux.sh.tmpl
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
