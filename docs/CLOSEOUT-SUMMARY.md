# Closeout summary — chezmoi restructure (2026-05-22 → 2026-05-24)

Project-level summary of the dotfiles restructure. For step-by-step concepts
read [CHEZMOI-CONCEPTS.md](./CHEZMOI-CONCEPTS.md); for the full diff and
secret-rotation table read [MIGRATION-LOG.md](./MIGRATION-LOG.md). This file
is the **3-minute exec summary**.

---

## What we did

Migrated the dotfiles repo from a **platform-tiered manual-copy layout**
(`linux/`, `macos/intel/`, `macos/silicon/`, `window/`) to a **declarative
chezmoi-managed layout** with templated configs and age-encrypted secrets.

Force-pushed the new clean history to `origin/main`, replacing 34 commits
of leaky history with 5 commits of templated configuration.

---

## Outcomes (measurable)

| Metric | Before | After |
|---|---|---|
| Distinct copies of `~/.zshrc` | 4 (intel + silicon + linux + live) | 1 templated (renders to all) |
| Secret leaks in git history | 14 (5 unique values) | 0 |
| Secret leaks in live `~/.zshrc` | 7 | 0 (all moved to encrypted file) |
| Bootstrap docs | 0 lines | 4 docs, ~1,200 lines |
| Working install scripts | 0 (3 broken) | 5 (idempotent chezmoi-managed) |
| Drift mechanism | Manual copy | `chezmoi apply` (no drift possible) |
| Secrets at rest | Cleartext on disk + in git | age-encrypted (X25519 + ChaCha20-Poly1305) |
| Brewfile / declarative install | None | 44 formulae + 23 casks in `home/dot_Brewfile` |
| Repo size on origin | ~unknown (many duplicated trees) | 216 KB |

---

## Phase timeline

| Phase | Description | Status |
|---|---|---|
| 0 | Pre-work — install chezmoi/age/gitleaks; scan repo for all secrets | ✅ |
| 1 | Design new chezmoi source layout at `~/.config/dotfiles-new/` (side-by-side) | ✅ |
| 2 | Render to `/tmp/chezmoi-staging/`; diff against live config | ✅ |
| 3 | Cutover — swap directories; install real chezmoi config; apply for real | ✅ |
| 4 | Scrub git history via fresh-repo + force-push to origin | ✅ |
| 5 | Final docs + closeout (this doc) | ✅ |

Total wall-clock: ~3 days (mostly waiting on user decisions; actual
hands-on edit time ~6 hours).

---

## What's on disk now

```
~/.config/dotfiles/                  ← chezmoi source (this repo)
~/.config/dotfiles-legacy/           ← pre-restructure repo (kept for ref, local only)
~/.config/chezmoi/
├── chezmoi.toml                     ← config (points sourceDir at ~/.config/dotfiles)
├── key.txt                          ← age private key (chmod 600; back up to password mgr)
└── chezmoi.toml.pre-cutover         ← backup, if any pre-existing config
~/dotfiles-backup-2026-05-23-173858/ ← live config snapshot from before cutover (144 KB)
```

And in `$HOME` (all chezmoi-managed now):

| File | Source | Content |
|---|---|---|
| `~/.zshrc` | `home/dot_zshrc.tmpl` | Templated, sources secrets from `.envrc.private` |
| `~/.zprofile` | `home/dot_zprofile.tmpl` | Brew shellenv |
| `~/.gitconfig` | `home/dot_gitconfig.tmpl` | URL rewrites + delta config (conditional) |
| `~/.gitignore` | `home/dot_gitignore` | Global git ignore |
| `~/.ssh/config` | `home/private_dot_ssh/config.tmpl` | SSH config (chmod 700 parent) |
| `~/.envrc.private` | `home/encrypted_private_dot_envrc.private` | age-decrypted at apply; mode 600; sourced by `~/.zshrc` |
| `~/.Brewfile` | `home/dot_Brewfile` | Declarative brew bundle spec (macOS) |
| `~/.config/apt-packages` | `home/dot_config/apt-packages` | Declarative pkg list for apt/dnf/pacman (Linux) |
| `~/.config/nvim/**` | `home/dot_config/nvim/**` | Lua config, snippets, colorschemes, etc. |
| `~/.config/git/hooks/pre-commit` | `home/dot_config/git/hooks/executable_pre-commit` | Runs `gitleaks protect --staged` on every commit |
| `~/.config/tmux/.tmux.conf` | gpakosz/.tmux external | Refreshed weekly |
| `~/.config/tmux/tmux.conf.local` | `home/dot_config/tmux/tmux.conf.local` | User customizations |
| `~/.config/tmux/tmux.conf` | symlink → `.tmux.conf` | Created by chezmoi script |

---

## Daily workflow from here

```bash
# Edit any config
chezmoi edit ~/.zshrc            # opens SOURCE template in $EDITOR
chezmoi apply                    # renders + writes to $HOME
chezmoi diff                     # preview before applying

# Add/rotate a secret
chezmoi edit ~/.envrc.private    # decrypts → editor → re-encrypts on save

# Sync to/from remote
chezmoi update                   # = chezmoi cd && git pull && chezmoi apply
chezmoi cd                       # open subshell in source dir
  git add -A && git commit -m '...' && git push
exit

# Sanity check
chezmoi status                   # what's out of sync
chezmoi doctor                   # diagnose setup issues
chezmoi managed                  # list every file chezmoi owns
```

---

## Bootstrap on a new machine

```bash
# 1. Install chezmoi + age
brew install chezmoi age   # macOS
# OR
sh -c "$(curl -fsLS get.chezmoi.io)"   # Linux

# 2. Restore the age private key (from password manager) to:
mkdir -p ~/.config/chezmoi
$EDITOR ~/.config/chezmoi/key.txt    # paste backed-up private key
chmod 600 ~/.config/chezmoi/key.txt

# 3. Init from this repo and apply
chezmoi init --apply git@github.com:TheDao032/dotfiles.git
```

Full procedure in [ONBOARDING.md](./ONBOARDING.md).

---

## Known follow-ups

### Done (post-restructure, 2026-05-27 → 2026-05-28)

1. ✅ **Rotated GitLab + GitHub tokens** (user-side, 2026-05-28). Fresh values in `~/.envrc.private`.
2. ✅ **Migrated `~/.config/nvim` into the repo** — 87 files / 328 KB now in `home/dot_config/nvim/`. Commit `50f8074`.
3. ✅ **Linux package list (`apt-packages`) + install script** — declarative parity with `dot_Brewfile` for apt/dnf/pacman. Commit `0deb44e`.
4. ✅ **Wired pre-commit gitleaks hook** via `core.hooksPath = ~/.config/git/hooks`. Verified blocks real-shape GitHub PATs. Commit `b0601b8`.
5. ✅ **Deleted `~/.config/dotfiles-legacy/`** — pre-restructure repo no longer needed.

### Out of scope / N/A

6. ⏸ **Notify company security team about Azure SP exposure** — N/A (no longer at that company; subscription is gone).

### Still open (no urgency)

7. **Consider starship prompt** to replace oh-my-zsh — faster shell startup, less plugin manager overhead.
8. **Per-machine overrides** via `chezmoi.toml` for when you have a second machine with different needs.
9. **CI on a self-hosted runner** to gate every PR with `chezmoi apply --dry-run` + `gitleaks detect`. (Pre-commit hook now covers the per-commit case locally.)

---

## Files in this docs/ directory

- [README.md](../README.md) — top-level overview + bootstrap quickstart
- **[CHEZMOI-CONCEPTS.md](./CHEZMOI-CONCEPTS.md)** ← START HERE if you've never used chezmoi
- [ONBOARDING.md](./ONBOARDING.md) — 5-minute new-machine bootstrap
- [ADDING-A-SECRET.md](./ADDING-A-SECRET.md) — encrypt / rotate a secret
- [MIGRATION-LOG.md](./MIGRATION-LOG.md) — full restructure history + secret-rotation table
- **CLOSEOUT-SUMMARY.md** (this file) — exec summary

---

## Lessons learned

What was harder than expected:

1. **chezmoi's `exclude` syntax** — used `filter.exclude` (silently ignored)
   for a long time before discovering `exclude` is top-level and patterns
   need `**/` prefix to match archive paths before `stripComponents`. Cost
   ~30 min of debugging.

2. **SSH key state on macOS** — turned out my SSH key for GitHub wasn't
   what I thought; earlier successful pushes used the HTTPS+PAT path via
   `osxkeychain` credential helper. Rotating the PAT invalidated the
   credential, then the SSH push fallback failed because the local key
   was never registered. Fixed with `gh ssh-key add ~/.ssh/id_ed25519.pub`.

3. **`[ -f X ] && source X` shell idiom** — leaks exit 1 to `$?` when X
   doesn't exist, triggering robbyrussell's red prompt arrow on every
   fresh shell. Made it look like everything was broken when only a
   cosmetic exit code was wrong. Fixed with `if/then/fi`.

4. **The chain of bugs in chezmoi script templates** — initial scripts had
   `{{- if ... }}` before the shebang line, which broke `exec format`.
   Lesson: shebang on line 1, always; OS conditional via runtime
   `uname -s` rather than template-time conditional.

What was easier than expected:

1. **chezmoi's mental model** — once the "source → target → destination"
   triplet clicks, everything else (`dot_` prefix, `encrypted_` prefix,
   templates) follows naturally.

2. **age encryption** — single binary, single keypair, no GPG ceremony.
   Set up in 60 seconds.

3. **gpakosz/.tmux externals** — works exactly as documented; weekly
   refresh + local customizations cleanly separated.

4. **Force-push history scrub** — no need for `git filter-repo` because
   the new repo was a fresh git init. Pushing the new lineage wholesale
   over the old origin/main is simpler than rewriting commits in place.

---

**Project complete.** Next git push from this machine: just `chezmoi git -- push`.
