# Chezmoi — Concepts & Tour

A concept-first guide to chezmoi, structured so you can read once and understand
every file in this repo. Goes from theory → our specific implementation.

If you've never seen chezmoi before, **read this top-to-bottom before
running `chezmoi apply`** for the first time.

> Official documentation: https://www.chezmoi.io/

---

## Table of contents

1. [What is chezmoi?](#1-what-is-chezmoi)
2. [The three states (the most important concept)](#2-the-three-states-the-most-important-concept)
3. [The naming convention (the magic prefixes)](#3-the-naming-convention-the-magic-prefixes)
4. [Templates (Go templates with chezmoi data)](#4-templates-go-templates-with-chezmoi-data)
5. [Secrets (the `encrypted_` prefix + age)](#5-secrets-the-encrypted_-prefix--age)
6. [Externals (gpakosz/.tmux integration)](#6-externals-gpakosztmux-integration)
7. [Scripts (run_once, run_onchange)](#7-scripts-run_once-run_onchange)
8. [Repo tour — our specific setup](#8-repo-tour--our-specific-setup)
9. [The 7 commands you'll actually use](#9-the-7-commands-youll-actually-use)
10. [How chezmoi solved our specific problems](#10-how-chezmoi-solved-our-specific-problems)
11. [Mental shortcuts to memorize](#11-mental-shortcuts-to-memorize)
12. [Further reading](#12-further-reading)
13. [How chezmoi reads, parses, and renders (the algorithm)](#13-how-chezmoi-reads-parses-and-renders-the-algorithm)
14. [How to inspect what chezmoi will do](#14-how-to-inspect-what-chezmoi-will-do)

---

## 1. What is chezmoi?

**One-sentence pitch**: chezmoi is **`make` for your home directory** — declare what you want your dotfiles to look like, run `chezmoi apply`, and it makes reality match.

The problem chezmoi solves:

```
Without chezmoi:                          With chezmoi:
─────────────────                          ─────────────
You edit ~/.zshrc directly                You edit a TEMPLATE
        ↓                                          ↓
You manually copy to ~/dotfiles/          chezmoi RENDERS the template into ~/.zshrc
        ↓                                          ↓
You commit + push                         You commit + push the TEMPLATE
        ↓                                          ↓
On a new machine: git clone               On a new machine: chezmoi init + apply
        ↓                                          ↓
You manually copy back to ~/.zshrc        chezmoi recreates ~/.zshrc from the template
        ↓                                          ↓
DRIFT (because manual copying)            NO DRIFT (chezmoi is the sync mechanism)
```

The key insight: chezmoi makes the **dotfiles repo the source of truth**, and your live `$HOME` becomes a derived artifact. You never edit `~/.zshrc` directly anymore — you edit the source, and chezmoi rebuilds `~/.zshrc`.

---

## 2. The three states (the most important concept)

chezmoi reasons about three states:

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   SOURCE STATE   │ ──> │   TARGET STATE   │ ──> │ DESTINATION STATE│
│                  │     │                  │     │                  │
│ Your repo:       │     │ Computed from    │     │ Your actual      │
│ ~/.config/       │     │ source + data    │     │ $HOME:           │
│   dotfiles/      │     │ + templates +    │     │ ~/.zshrc         │
│                  │     │ encryption       │     │ ~/.gitconfig     │
│ Has Go templates │     │                  │     │ ~/.ssh/config    │
│ Has encrypted    │     │ Pure files,      │     │ etc.             │
│ files            │     │ pure content     │     │                  │
│ Has prefixes     │     │                  │     │                  │
│ (dot_, private_) │     │                  │     │                  │
└──────────────────┘     └──────────────────┘     └──────────────────┘
       │                          │                         │
       │                          │                         │
   You edit                  chezmoi computes          chezmoi writes
   this directly             this in memory            this for real
```

| State | Where it lives | You edit it? |
|---|---|---|
| **Source state** | `~/.config/dotfiles/` (the repo) | ✅ YES — this is what you commit |
| **Target state** | Memory only (transient) | ❌ NO — it's derived |
| **Destination state** | `$HOME` (your actual files) | ❌ NO — chezmoi writes these |

**The big idea**: you never manually edit destination files. You edit source files (via `chezmoi edit`), and `chezmoi apply` propagates changes.

---

## 3. The naming convention (the magic prefixes)

This is the cleverest part of chezmoi. Filenames in the source dir encode transformations.

| Source name | Destination | Why |
|---|---|---|
| `home/dot_zshrc` | `~/.zshrc` | `dot_` → `.` (you can't have a leaf folder named `.zshrc` in git, so `dot_` is the convention) |
| `home/private_dot_ssh/config` | `~/.ssh/config` (parent dir is chmod 700) | `private_` → set mode 700 on the directory |
| `home/executable_dot_local/bin/myscript` | `~/.local/bin/myscript` (chmod +x) | `executable_` → set +x |
| `home/dot_zshrc.tmpl` | `~/.zshrc` (rendered through Go templates first) | `.tmpl` → process as template |
| `home/encrypted_private_dot_envrc.private` | `~/.envrc.private` (chmod 600, age-decrypted) | `encrypted_` → decrypt with age before writing |
| `home/symlink_dot_vimrc` | `~/.vimrc` (a symlink) | `symlink_` → create a symlink |

**Stacking is allowed**: `encrypted_private_dot_envrc.private.tmpl` would be → encrypt → set private → dot → render as template. (Read prefixes left-to-right.)

> For the **full parsing order** (all prefixes, all suffixes, the algorithm
> chezmoi runs on every filename), see [§13 — How chezmoi reads, parses,
> and renders](#13-how-chezmoi-reads-parses-and-renders-the-algorithm).
> The short version of the long answer: **chezmoi uses convention, not
> configuration** — there is no separate "mapping file" that says "this
> source → that destination." The filename IS the configuration.

In **our** setup, these files demonstrate each prefix:

| Source path | Rendered to | Prefixes in play |
|---|---|---|
| `home/dot_zshrc.tmpl` | `~/.zshrc` | `dot_` + `.tmpl` |
| `home/dot_zprofile.tmpl` | `~/.zprofile` | same |
| `home/private_dot_ssh/config.tmpl` | `~/.ssh/config` (with chmod 700 on parent) | `private_` + `dot_` + `.tmpl` |
| `home/encrypted_private_dot_envrc.private` | `~/.envrc.private` (chmod 600, decrypted) | `encrypted_` + `private_` + `dot_` |

---

## 4. Templates (Go templates with chezmoi data)

A `.tmpl` file is processed through Go's text/template engine before being written. chezmoi exposes a bunch of variables.

### Built-in data

```gotemplate
{{ .chezmoi.os }}            → "darwin" / "linux" / "windows"
{{ .chezmoi.arch }}          → "arm64" / "amd64"
{{ .chezmoi.hostname }}      → "nthedao-mac-pro-m4"
{{ .chezmoi.homeDir }}       → "/Users/thedao"
{{ .chezmoi.username }}      → "thedao"
```

### Your custom data (from `.chezmoidata.toml`)

We have this in `home/.chezmoidata.toml`:

```toml
[user]
    name  = "Nguyen The Dao"
    email = "nthedao2705@gmail.com"
    github = "TheDao032"
```

So in any template:

```gotemplate
{{ .user.name }}     →  "Nguyen The Dao"
{{ .user.email }}    →  "nthedao2705@gmail.com"
{{ .user.github }}   →  "TheDao032"
```

### Conditionals

```gotemplate
{{- if eq .chezmoi.os "darwin" }}
eval "$(/opt/homebrew/bin/brew shellenv)"
{{- else if eq .chezmoi.os "linux" }}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
{{- end }}
```

(The `-` in `{{-` strips leading whitespace; without it you get blank lines in the output.)

### In our setup

Our `home/dot_zshrc.tmpl` is templated for **arm64 vs intel**:

```gotemplate
{{- if eq .chezmoi.arch "arm64" }}
[ -x "{{ .paths.homebrew_prefix_arm }}/bin/brew" ] && eval ...
{{- else }}
[ -x "{{ .paths.homebrew_prefix_intel }}/bin/brew" ] && eval ...
{{- end }}
```

→ On your M4 Mac it renders as `/opt/homebrew/...`, on an Intel Mac it'd render as `/usr/local/...`. **One source file, two correct outputs.**

This is the answer to the "I had 3 copies of zshrc" problem.

---

## 5. Secrets (the `encrypted_` prefix + age)

Files prefixed `encrypted_` are decrypted before being written to the destination.

### How it works (zoomed in)

```
┌──────────────────────────────────────────────────────────────────┐
│ SOURCE                                                            │
│ home/encrypted_private_dot_envrc.private                          │
│ (binary blob — opaque to git, gitleaks, GitHub search)            │
│                                                                   │
│              ┌──────── age decrypt ────────┐                      │
│              │ with private key at         │                      │
│              │ ~/.config/chezmoi/key.txt   │                      │
│              └──────────┬──────────────────┘                      │
│                         ▼                                         │
│ TARGET (in memory only)                                           │
│ Cleartext content                                                 │
│                         │                                         │
│                         ▼                                         │
│ DESTINATION                                                       │
│ ~/.envrc.private (mode 600, owned by you)                         │
└──────────────────────────────────────────────────────────────────┘
```

### Why age over GPG?

- **Single binary** (`age`, ~12 KB), no daemons, no keyring drama
- **Modern crypto** (X25519, ChaCha20-Poly1305) vs GPG's RSA legacy
- **Key files are simple text** — easy to back up to a password manager
- **No "trust web"** to manage — just public/private keypair

### The keypair

```
~/.config/chezmoi/key.txt    ← private key (NEVER commit; chmod 600)
                                Public recipient: age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4
```

Anyone with this private key can decrypt your `encrypted_*` files. Back it up to your password manager.

### Editing a secret

```bash
chezmoi edit ~/.envrc.private
```

Behind the scenes:

1. chezmoi reads `home/encrypted_private_dot_envrc.private`
2. Decrypts with `~/.config/chezmoi/key.txt` → tempfile in tmpfs
3. Opens tempfile in `$EDITOR`
4. When you save+exit, chezmoi re-encrypts with the **public recipient** from `chezmoi.toml`
5. Writes back to the source file
6. Securely deletes the tempfile

You never see ciphertext in your editor; you never see plaintext on disk.

See [ADDING-A-SECRET.md](./ADDING-A-SECRET.md) for full secret workflows including rotation.

---

## 6. Externals (gpakosz/.tmux integration)

`.chezmoiexternal.toml` declares files/dirs sourced from somewhere ELSE (URL, git repo, archive). chezmoi fetches them at apply time and overlays them into your destination.

### Our config (`home/.chezmoiexternal.toml`)

```toml
[".config/tmux"]                    # target path (relative to $HOME)
    type   = "archive"              # pull a tarball
    url    = "https://github.com/gpakosz/.tmux/archive/refs/heads/master.tar.gz"
    stripComponents = 1             # drop the top-level dir from the tarball
    refreshPeriod   = "168h"        # re-pull every 7 days
    exact  = false                  # don't delete other files in target dir
    exclude = ["**/README.md", "**/LICENSE.MIT", ...]  # filter out junk
```

### Result on apply

```
~/.config/tmux/
├── .tmux.conf              ← from gpakosz (refreshed weekly)
├── tmux.conf.local         ← from our repo (your customizations)
└── tmux.conf               ← symlink → .tmux.conf (created by our script)
```

**Why this matters**: you don't manually vendor gpakosz's framework. You declare "I want gpakosz/.tmux master, here", chezmoi fetches+keeps current, your customizations stay separate.

If gpakosz publishes a new release, your next `chezmoi apply --refresh-externals` pulls it.

### Pattern syntax gotcha

`exclude` patterns match the **full archive path** (including the top-level dir before `stripComponents` is applied). So:
- ❌ `README.md` (won't match `.tmux-master/README.md`)
- ✅ `**/README.md` (matches at any depth)

Found this the hard way during initial setup; the comment in `.chezmoiexternal.toml` explains the gotcha for future-you.

---

## 7. Scripts (run_once, run_onchange)

Source files starting with `run_` are EXECUTED at apply time, not written to destination.

| Prefix | When it runs |
|---|---|
| `run_once_` | Once per machine, ever (chezmoi remembers via a hash) |
| `run_onchange_` | Re-runs whenever the script's content changes |
| `run_` (no qualifier) | Every `chezmoi apply` |

You can also gate them with `before`/`after`:

| Prefix | Order |
|---|---|
| `run_*_before_*` | Runs BEFORE chezmoi writes files |
| `run_*_after_*` | Runs AFTER chezmoi writes files |
| `run_once_<X>` | Default = after |

### Our scripts (in `home/.chezmoiscripts/`)

| File | When runs | What it does |
|---|---|---|
| `run_onchange_before_install-brew.sh.tmpl` | Before apply, when content changes | Install Homebrew if missing |
| `run_onchange_after_install-brew-bundle.sh.tmpl` | After apply, when Brewfile hash changes | `brew bundle ~/.Brewfile` |
| `run_once_after_install-oh-my-zsh.sh.tmpl` | Once per machine | Install oh-my-zsh |
| `run_once_after_install-vagrant-qemu-plugin.sh.tmpl` | Once per machine | `vagrant plugin install vagrant-qemu` |
| `run_onchange_after_link-gpakosz-tmux.sh.tmpl` | After apply, when content changes | Symlink `.tmux.conf` → `tmux.conf` (for XDG) |

The brilliance of `run_onchange`: in `install-brew-bundle.sh.tmpl` I include a hash of `dot_Brewfile` in the script's content:

```bash
# Brewfile hash (re-runs script when this changes): {{ include "dot_Brewfile" | sha256sum }}
```

When you add a new brew, the Brewfile hash changes → the script's content changes → chezmoi re-runs the bundle install. **It only runs when there's something to do.**

---

## 8. Repo tour — our specific setup

```
~/.config/dotfiles-new/                      ← chezmoi source dir (will become ~/.config/dotfiles/ at cutover)
│
├── README.md                                ← .chezmoiignored (not deployed)
├── .chezmoi.toml.tmpl                       ← config template; rendered to
│                                              ~/.config/chezmoi/chezmoi.toml at init
├── .chezmoiroot                             ← "home" (tells chezmoi source root is home/)
│
├── docs/                                    ← .chezmoiignored
│   ├── CHEZMOI-CONCEPTS.md                  ← THIS FILE
│   ├── ONBOARDING.md                        ← bootstrap a new machine
│   ├── ADDING-A-SECRET.md                   ← encrypt a new env var
│   └── MIGRATION-LOG.md                     ← restructure history
│
└── home/                                    ← THE source root (per .chezmoiroot)
    │
    ├── .chezmoidata.toml                    ← global template vars (.user, .tools, .paths)
    ├── .chezmoiexternal.toml                ← gpakosz/.tmux external
    ├── .chezmoiignore                       ← skip README.md, docs/, etc.
    │
    ├── dot_zshrc.tmpl                       → ~/.zshrc                  (templated)
    ├── dot_zprofile.tmpl                    → ~/.zprofile               (templated)
    ├── dot_gitconfig.tmpl                   → ~/.gitconfig              (templated)
    ├── dot_gitignore                        → ~/.gitignore              (static)
    ├── dot_Brewfile                         → ~/.Brewfile               (static)
    │
    ├── private_dot_ssh/                     → ~/.ssh/                   (chmod 700 on dir)
    │   └── config.tmpl                      → ~/.ssh/config             (templated)
    │
    ├── encrypted_private_dot_envrc.private  → ~/.envrc.private          (decrypted + chmod 600)
    │
    ├── dot_config/                          → ~/.config/                (intermediate dir)
    │   └── tmux/                            → ~/.config/tmux/
    │       └── tmux.conf.local              → ~/.config/tmux/tmux.conf.local
    │                                         (+ .tmux.conf comes from external)
    │
    └── .chezmoiscripts/                     ← NOT deployed; executed at apply
        ├── run_onchange_before_install-brew.sh.tmpl
        ├── run_onchange_after_install-brew-bundle.sh.tmpl
        ├── run_once_after_install-oh-my-zsh.sh.tmpl
        ├── run_once_after_install-vagrant-qemu-plugin.sh.tmpl
        └── run_onchange_after_link-gpakosz-tmux.sh.tmpl
```

---

## 9. The 7 commands you'll actually use

| Command | What it does | How often |
|---|---|---|
| `chezmoi edit ~/.zshrc` | Open the SOURCE template in your editor (NOT ~/.zshrc directly) | Whenever you want to change a config |
| `chezmoi apply` | Render all templates + write to $HOME | After every edit |
| `chezmoi diff` | Show what would change in $HOME, without writing | Before applying, to sanity check |
| `chezmoi status` | Quick summary of source-vs-destination state | Anytime you're confused |
| `chezmoi cd` | Open a subshell inside the source dir | For doing git operations on the repo |
| `chezmoi update` | `git pull` then apply (sync from remote) | When switching machines or after pushing from another machine |
| `chezmoi edit ~/.envrc.private` | Decrypt → edit → re-encrypt (workflow for secrets) | Adding/rotating a secret |

### Workflow examples

**Adding an alias**:

```bash
chezmoi edit ~/.zshrc
# add: alias gs='git status'
chezmoi apply
source ~/.zshrc
```

**Adding a new env var (non-secret)**:

```bash
chezmoi edit ~/.zshrc
# add: export FOO_API_BASE=https://api.example.com
chezmoi apply
```

**Adding a new secret**:

```bash
chezmoi edit ~/.envrc.private    # decrypts in tmpfs, opens editor
# add: export NEW_TOKEN="..."
# save + quit → chezmoi re-encrypts
chezmoi apply                    # writes ~/.envrc.private
source ~/.zshrc                  # ~/.zshrc sources .envrc.private
```

**Syncing across machines**:

```bash
# On machine A
chezmoi edit ~/.zshrc
chezmoi apply
chezmoi cd                       # cd into source dir
git add -A && git commit -m '...' && git push
exit                             # back out of source-dir shell

# On machine B
chezmoi update                   # = chezmoi cd && git pull && chezmoi apply
```

**Pulling latest gpakosz/.tmux** (without waiting for the 7-day refresh):

```bash
chezmoi apply --refresh-externals
```

---

## 10. How chezmoi solved our specific problems

Recall the [migration audit](./MIGRATION-LOG.md) found:

1. **3× duplicate zshrc** (intel/silicon/linux) → solved by **templating** (§4)
2. **Drift between repo and live** (~/.zshrc differed from repo) → solved by **source-of-truth model** (§2)
3. **Secrets in public git** → solved by **`encrypted_` prefix + age** (§5)
4. **gpakosz vendored as snapshot** → solved by **externals** (§6)
5. **Broken install scripts** → solved by **`run_once` / `run_onchange`** (§7)
6. **No bootstrap docs** → solved by **README + docs/** (separate from runtime)
7. **No multi-machine sync** → solved by **`chezmoi update`** (§9)

---

## 11. Mental shortcuts to memorize

| When I see... | I should think... |
|---|---|
| `dot_X` | Will become `~/.X` |
| `private_X` | Parent dir will be chmod 700 |
| `encrypted_X` | Will be age-decrypted before writing |
| `executable_X` | Will be chmod +x |
| `.tmpl` suffix | Will be rendered through Go templates |
| `run_once_*` | Script, runs once per machine forever |
| `run_onchange_*` | Script, re-runs when content changes |
| `.chezmoidata.toml` | Template variables |
| `.chezmoiignore` | Files NOT deployed |
| `.chezmoiexternal.toml` | Sourced from somewhere else (URL, git) |
| `.chezmoiscripts/` | Scripts dir (not deployed; executed) |

---

## 12. Further reading

### Official docs
- **Quick start**: https://www.chezmoi.io/quick-start/
- **Reference (the whole API)**: https://www.chezmoi.io/reference/
- **Source state attributes (the prefix table)**: https://www.chezmoi.io/reference/source-state-attributes/
- **Template variables**: https://www.chezmoi.io/reference/templates/variables/
- **Configuration file** (`chezmoi.toml`): https://www.chezmoi.io/reference/configuration-file/

### Concepts that go deeper
- **Templates**: https://www.chezmoi.io/user-guide/templating/
- **Encryption** (age + gpg): https://www.chezmoi.io/user-guide/encryption/
- **Externals**: https://www.chezmoi.io/user-guide/include-files-from-elsewhere/
- **Scripts**: https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/
- **Working across machines**: https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/

### Adjacent docs in THIS repo
- [ONBOARDING.md](./ONBOARDING.md) — bootstrap a new machine end-to-end
- [ADDING-A-SECRET.md](./ADDING-A-SECRET.md) — encrypt/rotate/manage secrets
- [MIGRATION-LOG.md](./MIGRATION-LOG.md) — what changed from the pre-2026-05-22 layout, why

### External references
- **age encryption** (the tool we use): https://age-encryption.org/
- **gitleaks** (we scan with this): https://github.com/gitleaks/gitleaks
- **gpakosz/.tmux** (curated tmux framework, fetched as external): https://github.com/gpakosz/.tmux

### Useful chezmoi command help
```bash
chezmoi help                       # top-level help
chezmoi <command> --help           # per-command help
chezmoi data                       # see all template variables on this machine
chezmoi doctor                     # diagnose setup problems
chezmoi managed                    # list every file chezmoi knows about
chezmoi unmanaged                  # files in $HOME that chezmoi DOESN'T know about
```

---

## 13. How chezmoi reads, parses, and renders (the algorithm)

A common question after using chezmoi for a while: **"where is the file
that says 'this template renders to that destination'?"**

There ISN'T one. chezmoi uses **convention over configuration** — the file
name itself encodes all the transformation rules. The mapping IS the
filename. This section walks through the algorithm chezmoi runs on every
source file.

### The high-level algorithm (4 steps)

```
┌──────────────────────────────────────────────────────────────────┐
│ Step 1 — DISCOVERY                                                │
│ chezmoi walks the source directory (default ~/.local/share/       │
│ chezmoi, or wherever `.chezmoiroot` redirects to). Every file/    │
│ dir is a candidate for the source state.                          │
└────────────────────────┬─────────────────────────────────────────┘
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 2 — NAME PARSING                                             │
│ For each file/dir name, chezmoi peels off prefixes/suffixes       │
│ in a fixed order. Each prefix/suffix is an "attribute". The       │
│ remainder becomes the TARGET PATH relative to $HOME.              │
└────────────────────────┬─────────────────────────────────────────┘
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 3 — CONTENT PROCESSING                                       │
│ Read the file's contents. If marked encrypted → decrypt with age. │
│ If marked template → render through Go templates with .chezmoi.*  │
│ and .chezmoidata.toml as the data context.                        │
└────────────────────────┬─────────────────────────────────────────┘
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ Step 4 — WRITE                                                    │
│ Write the processed content to the target path with the file     │
│ mode determined by the attributes (chmod 600 if private,         │
│ +x if executable, etc.). chmod the parent dir if needed.         │
└──────────────────────────────────────────────────────────────────┘
```

### The full attribute parsing rules

This is the **complete grammar** chezmoi applies to every filename.
Source-of-truth: `internal/chezmoi/sourcestate.go` in the chezmoi repo,
function `parseSourceName`.

#### For files

| Order | Prefix/Suffix | Strips it? | Effect |
|---|---|---|---|
| 1 | `encrypted_` | strip | Mark for age/gpg decryption |
| 2 | `once_` | strip | (only valid on `run_*` scripts) |
| 3 | `private_` | strip | chmod 600 |
| 4 | `readonly_` | strip | chmod 400 |
| 5 | `empty_` | strip | Allow empty file (otherwise chezmoi treats empty as "absent") |
| 6 | `executable_` | strip | chmod 700 / +x |
| 7 | `symlink_` | strip | Create as symlink (file contents = link target) |
| 8 | `modify_` | strip | Treat as a modifier script (runs against existing target) |
| 9 | `create_` | strip | Only create if target doesn't exist (don't overwrite) |
| 10 | `dot_` | strip + replace with `.` | Source `dot_zshrc` → target `.zshrc` |
| 11 | `literal_` | strip | Treats next prefix as literal (escape hatch) |
| 12 | `.tmpl` (suffix) | strip | Process through Go templates |
| 13 | `.literal` (suffix) | strip | Escape hatch for filenames containing reserved suffixes |

#### For scripts (files in `.chezmoiscripts/` or named `run_*`)

| Prefix | Meaning |
|---|---|
| `run_` | This is a script — execute, don't deploy |
| `run_once_` | Run once per machine (chezmoi tracks via content hash) |
| `run_onchange_` | Re-run whenever script content changes |
| `run_*_before_` | Run BEFORE files are applied |
| `run_*_after_` | Run AFTER files are applied (default) |

#### Reserved directory / file names

| Name | What it does |
|---|---|
| `.chezmoiroot` | Redirect: source root is whatever directory this file's content names |
| `.chezmoiignore` | Glob patterns of files NOT to deploy |
| `.chezmoidata.<format>` | Template data (TOML / YAML / JSON) |
| `.chezmoitemplates/` | Reusable template partials (callable via `{{ template "name" . }}`) |
| `.chezmoiexternal.<format>` | External sources (URLs, archives, git repos) |
| `.chezmoiscripts/` | Scripts directory (alternative to `run_*` files at root) |
| `.chezmoiremove` | Files to actively delete from target |

### Concrete examples from THIS repo

Trace each of our files through the algorithm:

#### Example 1 — templated dotfile

```
SOURCE: home/dot_zshrc.tmpl

Step 2 (parse):
    "dot_zshrc.tmpl"
    ↓ strip dot_  → ".zshrc.tmpl"
    ↓ strip .tmpl → ".zshrc"           + TEMPLATE=true
    target: $HOME/.zshrc                 mode=644 (default)

Step 3 (content): read source → render Go template with data context
        (.chezmoi.os="darwin", .chezmoi.arch="arm64",
         .user.name="Nguyen The Dao", .tools.editor="nvim", ...)

Step 4 (write): write rendered output to ~/.zshrc mode 644
```

#### Example 2 — encrypted + private secrets file

```
SOURCE: home/encrypted_private_dot_envrc.private

Step 2 (parse):
    "encrypted_private_dot_envrc.private"
    ↓ strip encrypted_ → "private_dot_envrc.private"  + ENCRYPTED=true
    ↓ strip private_   → "dot_envrc.private"           + MODE=600
    ↓ strip dot_       → ".envrc.private"
    (.private is NOT a recognized suffix → kept verbatim)
    target: $HOME/.envrc.private                       mode=600

Step 3 (content): read source → pipe through `age -d -i ~/.config/chezmoi/key.txt`

Step 4 (write): write decrypted content to ~/.envrc.private mode 600
```

#### Example 3 — directory with attributes

```
SOURCE: home/private_dot_ssh/config.tmpl

Step 2a (parse parent dir "private_dot_ssh"):
    ↓ strip private_ → "dot_ssh"     + DIR_MODE=700
    ↓ strip dot_     → ".ssh"
    directory target: ~/.ssh                           mode=700

Step 2b (parse file "config.tmpl"):
    ↓ strip .tmpl    → "config"      + TEMPLATE=true
    file target: ~/.ssh/config                         mode=644

Step 3+4: render template content, write to ~/.ssh/config,
          chmod parent dir to 700
```

#### Example 4 — script (not deployed; executed)

```
SOURCE: home/.chezmoiscripts/run_onchange_before_install-brew.sh.tmpl

Step 2 (parse — but this is a SCRIPT, so different rules):
    "run_onchange_before_install-brew.sh.tmpl"
    ↓ strip run_         → "onchange_before_install-brew.sh.tmpl"
    ↓ strip onchange_    → re-run when content hash changes
    ↓ strip before_      → run BEFORE applying files
    ↓ strip .tmpl        → "install-brew.sh"           + TEMPLATE=true
    NOT deployed to a target path.
    Stored in chezmoi state as a script.

Step 3 (content): read source → render template → result is bash script content

Step 4 (execute):
    1. Write rendered script to a temp file with +x
    2. Execute it (`bash /tmp/random-X.sh`)
    3. Capture exit code (non-zero = abort apply)
    4. Record content hash in ~/.config/chezmoi/chezmoistate.boltdb
       so chezmoi knows whether to re-run next time
```

### The "rules file" you might be looking for

There IS no separate rules file in your repo or chezmoi's config. The
rules live in **chezmoi's Go source code**:

| What | Where in chezmoi source |
|---|---|
| Prefix/suffix list + parsing order | [`internal/chezmoi/sourcestate.go`](https://github.com/twpayne/chezmoi/blob/master/internal/chezmoi/sourcestate.go) — search for `parseSourceName` |
| Attribute meanings (file) | [`internal/chezmoi/sourcefiletype.go`](https://github.com/twpayne/chezmoi/blob/master/internal/chezmoi/sourcefiletype.go) |
| Script lifecycle (run_once, etc.) | [`internal/chezmoi/scriptattr.go`](https://github.com/twpayne/chezmoi/blob/master/internal/chezmoi/scriptattr.go) |
| Template rendering pipeline | [`internal/chezmoi/templateexecutor.go`](https://github.com/twpayne/chezmoi/blob/master/internal/chezmoi/templateexecutor.go) |
| External-source handling | [`internal/chezmoi/sourcestate.go`](https://github.com/twpayne/chezmoi/blob/master/internal/chezmoi/sourcestate.go) — `External` struct (look for `type External struct`) |

**Official docs** for the same content:
- Source state attributes (the prefix table): https://www.chezmoi.io/reference/source-state-attributes/
- Special files / directories: https://www.chezmoi.io/reference/special-files-and-directories/

> **The conventions ARE the API.** That's it. There's no hidden mapping file.

---

## 14. How to inspect what chezmoi will do

If you ever want to trace the parsing yourself (debugging, sanity-checking,
or just exploring), these commands let you see exactly what chezmoi computed:

### 14.1 List every source file + its resolved target

```bash
chezmoi managed
```

Outputs one target path per line (relative to $HOME). This is the
post-parse view — everything chezmoi WILL deploy.

For our repo it prints things like:
```
.Brewfile
.chezmoiscripts/install-brew-bundle.sh
.config/tmux/.tmux.conf
.config/tmux/tmux.conf.local
.envrc.private
.gitconfig
.gitignore
.ssh/config
.zprofile
.zshrc
```

Notice `.envrc.private` (not `encrypted_private_dot_envrc.private`) —
that's the resolved target after all prefixes are stripped.

### 14.2 Resolve a single source file's target

```bash
chezmoi target-path home/encrypted_private_dot_envrc.private
# → /Users/thedao/.envrc.private
```

Useful for spot-checking when you add a new file and want to confirm
chezmoi parsed the name as expected.

### 14.3 Reverse — find the source for a destination file

```bash
chezmoi source-path ~/.zshrc
# → /Users/thedao/.config/dotfiles/home/dot_zshrc.tmpl
```

Useful when you `cat ~/.zshrc` and want to know where it came from.

### 14.4 See ALL the template data available

```bash
chezmoi data
```

Dumps the full data context — every variable your templates can read.
Includes `.chezmoi.*` built-ins (os, arch, hostname, etc.) plus everything
from your `.chezmoidata.toml`.

Useful for: writing new templates, debugging "why isn't `{{ .X }}` working?"

### 14.5 Render a template WITHOUT writing it

```bash
chezmoi execute-template < home/dot_zshrc.tmpl | less
```

Shows you exactly what the rendered output would look like, without
touching the destination.

Or render an arbitrary string from stdin:
```bash
echo '{{ .chezmoi.arch }} {{ .user.name }}' | chezmoi execute-template
# → arm64 Nguyen The Dao
```

### 14.6 See what content chezmoi has for a target (post-everything)

```bash
chezmoi cat ~/.zshrc       # full rendered content (templates + decryption + etc.)
chezmoi cat ~/.envrc.private | head -10
```

This is the most powerful "what would actually land on disk?" command.
Use it before `chezmoi apply` to preview the bytes that would be written.

### 14.7 Diff against current $HOME state

```bash
chezmoi diff               # what would change in $HOME?
chezmoi status             # one-line per pending change
chezmoi apply --dry-run --verbose | head -50    # walk through every action
```

### 14.8 Trace + log every action chezmoi takes

```bash
chezmoi apply --verbose 2>&1 | less
```

Shows every file read, every template render, every script execution,
in order. Good when something mysteriously isn't happening.

### 14.9 Visualize the source ↔ target mapping all at once

```bash
chezmoi managed | while read t; do
    src=$(chezmoi source-path "$HOME/$t" 2>/dev/null || echo '(?)')
    printf '%-50s ← %s\n' "$HOME/$t" "$src"
done
```

Prints a `target ← source` table so you see the entire mapping concretely.

### Common "wait, why didn't that work?" gotchas

| Symptom | Likely cause |
|---|---|
| File didn't render as template | Forgot `.tmpl` suffix |
| File didn't end up at `~/.X` | Forgot `dot_` prefix |
| Permissions are 644 instead of 600 | Forgot `private_` prefix |
| `chezmoi managed` doesn't list my file | Matched a pattern in `.chezmoiignore` |
| `home/foo.tmpl` rendered as `foo.tmpl` not `foo` | `.tmpl` IS stripped. Check `chezmoi target-path home/foo.tmpl` |
| Script ran every apply | Used bare `run_` not `run_once_` or `run_onchange_` |
| Encrypted file says "encryption not configured" | `chezmoi.toml` doesn't have `encryption = "age"` set |
| Empty file vanished from target | Forgot `empty_` prefix (chezmoi treats empty as "absent" by default) |

---

**Last revised**: 2026-05-24 (added §13 + §14 covering the parsing
algorithm + inspection commands. Original concept doc written 2026-05-23
before Phase 3 cutover.)
