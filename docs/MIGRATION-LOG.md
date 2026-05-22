# Migration log

## 2026-05-22 — chezmoi restructure

Replaced the platform-tiered manual-copy layout with chezmoi + age.

### Why

The old layout had three independent problems:

1. **3-way duplication of ~zshrc** — `linux/lua-script/zshrc_file` +
   `macos/intel/zshrc_file` + `macos/silicon/dot_zshrc` + the live
   `~/.zshrc` were near-duplicates with no sync mechanism. Editing one
   created drift forever.

2. **14 secret leaks across git history** (gitleaks scan) — 1 GitLab PAT
   (active!) + 4 Azure AD client secrets in committed `zshrc` files,
   visible on public github.com/TheDao032/dotfiles. Live `~/.zshrc` also
   had 7 leaking secrets including a GitHub PAT.

3. **No bootstrap mechanism** — `linux/install.sh` and `macos/intel/install.sh`
   were broken (intel script used `sudo apt-get` on macOS, linux script had
   `exec source $HOME/.zshrc`). No documented "new machine" procedure.

### What changed

| Before | After |
|---|---|
| `linux/`, `macos/intel/`, `macos/silicon/`, `window/` tiers with copies | Single `home/` source, Go templates handle per-OS/arch differences |
| 3× zshrc copies | 1× `home/dot_zshrc.tmpl` (templated) |
| Secrets in cleartext, in git history | `home/encrypted_private_dot_envrc.age` (age-encrypted) |
| Broken install scripts | chezmoi `run_once_*` / `run_onchange_*` scripts (idempotent) |
| `~/.zshrc` manually edited, drifted from repo | `chezmoi edit ~/.zshrc` → source-of-truth |
| No README | `README.md` + `docs/{ONBOARDING,ADDING-A-SECRET,MIGRATION-LOG}.md` |

### Secret rotation log

| Secret | Old location | Rotated | New location | Date |
|---|---|---|---|---|
| `GITLAB_TOKEN` (glpat-z7…NURD) | `dot_zshrc:228` (public git) | TODO | encrypted age | 2026-05-22 |
| Azure ARM secret 1 (7f_8Q~ar…) | commented; in history | n/a (subscription dead?) | encrypted age | 2026-05-22 |
| Azure ARM secret 2 (YdJ8Q~T8…) | commented; in history | n/a | encrypted age | 2026-05-22 |
| Azure ARM secret 3 (der8Q~V0…) | commented; in history | n/a | encrypted age | 2026-05-22 |
| Azure ARM secret 4 (V0f8Q~8R…) | commented; in history | n/a | encrypted age | 2026-05-22 |
| `GITHUB_TOKEN` (ghp_h6yz…) | live `~/.zshrc` (commented) | TODO | encrypted age | 2026-05-22 |
| `HCP_CLIENT_*` | live `~/.zshrc` | n/a (never committed) | encrypted age | 2026-05-22 |
| `TIKTOK_APP_*` | live `~/.zshrc` | n/a (never committed) | encrypted age | 2026-05-22 |

### git history scrub

The pre-restructure repo had the 5 unique leaked secrets in commit history
(through commit `4e42190` "build: add render markdown package"). On the
restructure commit, history was rewritten via `git filter-repo` to redact
all 5 values, then force-pushed to `origin/main`.

The pre-restructure history is preserved at tag `legacy-pre-restructure`
locally for reference (NOT pushed — anyone who needs the old layout
should restore from a local backup).

### What was kept vs dropped

| Kept | Dropped |
|---|---|
| `home/dot_config/tmux/tmux.conf.local` (the customizations) | `macos/silicon/tmux/tmux.conf` (vendored gpakosz snapshot — now external) |
| `home/dot_zshrc.tmpl` (consolidated from 3 copies) | `linux/lua-script/zshrc_file`, `macos/intel/zshrc_file`, `macos/silicon/dot_zshrc` (the 3 copies) |
| nvim config — see follow-ups | `window/nvim-windows/` (no active Windows usage) |
| `home/.chezmoiscripts/*` (working bootstrap) | `linux/install.sh`, `linux/install_zsh.sh`, `macos/intel/install.sh` (broken) |

### Follow-ups (not done yet)

1. **Migrate `~/.config/nvim` into the repo.** Currently the live nvim config
   isn't in any version control. Two options:
   - Pull it into `home/dot_config/nvim/` (chezmoi-managed)
   - Track it as a separate repo (`nvim-config`) referenced via chezmoi external
2. **Consider starship prompt** to replace oh-my-zsh `robbyrussell` theme
   (faster shell startup, more configurable, no plugin manager overhead).
3. **Wire pre-commit hooks** to gitleaks-scan the chezmoi source dir on every commit.
4. **Per-machine `chezmoi.toml` overrides**: machines with different roles
   (e.g., work laptop vs. personal) can have different `[data.machine]` values.
   Currently every machine uses defaults from `.chezmoidata.toml`.
