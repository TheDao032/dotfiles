# Migration log

## 2026-05-22 → 2026-05-24 — chezmoi restructure

Replaced the platform-tiered manual-copy layout with chezmoi + age. Cutover
complete; history scrub force-pushed to `origin/main`.

For the project-level summary, see [CLOSEOUT-SUMMARY.md](./CLOSEOUT-SUMMARY.md).

### Why

The old layout had three independent problems:

1. **3-way duplication of `~/.zshrc`** — `linux/lua-script/zshrc_file` +
   `macos/intel/zshrc_file` + `macos/silicon/dot_zshrc` + the live
   `~/.zshrc` were near-duplicates with no sync mechanism. Editing one
   created drift forever.

2. **14 secret leaks across git history** (gitleaks scan) — 1 GitLab PAT
   (active!) + 4 Azure AD client secrets in committed `zshrc` files,
   visible on public github.com/TheDao032/dotfiles. Live `~/.zshrc` also
   had 7 leaking secrets including a GitHub PAT, HCP_CLIENT_SECRET, and
   TikTok app credentials.

3. **No bootstrap mechanism** — `linux/install.sh` and `macos/intel/install.sh`
   were broken (intel script used `sudo apt-get` on macOS, linux script had
   `exec source $HOME/.zshrc`). No documented "new machine" procedure.

### What changed

| Before | After |
|---|---|
| `linux/`, `macos/intel/`, `macos/silicon/`, `window/` tiers with copies | Single `home/` source, Go templates handle per-OS/arch differences |
| 3× zshrc copies | 1× `home/dot_zshrc.tmpl` (templated) |
| Secrets in cleartext, in git history | `home/encrypted_private_dot_envrc.private` (age-encrypted) |
| Broken install scripts | chezmoi `run_once_*` / `run_onchange_*` scripts (idempotent) |
| `~/.zshrc` manually edited, drifted from repo | `chezmoi edit ~/.zshrc` → source-of-truth |
| No README | `README.md` + `docs/{CHEZMOI-CONCEPTS,ONBOARDING,ADDING-A-SECRET,MIGRATION-LOG,CLOSEOUT-SUMMARY}.md` |
| gpakosz/.tmux vendored as snapshot | gpakosz/.tmux as `.chezmoiexternal.toml` (weekly auto-refresh) |
| No Brewfile | `home/dot_Brewfile` declarative (44 formulae + 23 casks) |

### Secret rotation log

| # | Secret prefix | Old location | Where rotated | Status | Date |
|---|---|---|---|---|---|
| 1 | `glpat-z7…NURD` (GitLab PAT) | `dot_zshrc:228` (public git) + live `~/.zshrc` | GitLab → revoked; new `glpat-7ydG5-…` issued | ✅ Done; in encrypted file | 2026-05-23 |
| 2 | `ghp_h6yz…Tofm` (GitHub PAT) | live `~/.zshrc:228` (commented) + git history | GitHub → revoked; new `ghp_do9I…` issued | ✅ Done; in encrypted file | 2026-05-23 |
| 3 | `7f_8Q~ar…Udmt` (Azure SP) | `dot_zshrc:202` (commented) + git history | Corporate-owned; notified security team (TODO follow-up) | 🟡 User-side cleanup done; org rotation pending | 2026-05-23 |
| 4 | `YdJ8Q~T8…Gcbg` (Azure SP) | `dot_zshrc:209` (commented) + git history | Same as #3 | 🟡 Same | 2026-05-23 |
| 5 | `der8Q~V0…bcTZ` (Azure SP) | `dot_zshrc:216` (commented) + git history | Same as #3 | 🟡 Same | 2026-05-23 |
| 6 | `V0f8Q~8R…zdy8` (Azure SP) | `dot_zshrc:223` (commented) + git history | Same as #3 | 🟡 Same | 2026-05-23 |
| 7 | `96ec4b2f…dcdf` (HCP_CLIENT_SECRET) | live `~/.zshrc` ONLY (never committed) | Not leaked publicly; moved to encrypted file | ✅ Done | 2026-05-22 |
| 8 | `sbawqkqe…t046` (TIKTOK_APP_KEY) | live `~/.zshrc` ONLY | Same — moved to encrypted file | ✅ Done | 2026-05-22 |
| 9 | `Qni7DLnw…2d0e` (TIKTOK_APP_SECRET) | live `~/.zshrc` ONLY | Same | ✅ Done | 2026-05-22 |

### git history scrub

Approach: built the new chezmoi source as a **fresh git repository** (no
shared lineage with the pre-restructure layout). The new repo's 5 commits
contain zero secret values in any form. Then `git push --force-with-lease`
overwrote `origin/main` wholesale, replacing the leaky history.

- Pre-restructure `origin/main` HEAD: `4e42190` ("build: add render markdown package")
- Post-restructure `origin/main` HEAD: `9baa01f` ("chore(security): add gitleaks allowlist")
- gitleaks scan on new repo: **0 leaks found**

The pre-restructure history is preserved LOCAL ONLY at tag
`legacy-pre-restructure` in `~/.config/dotfiles-legacy/` (the original repo
clone, kept untouched). This tag was deliberately NOT pushed to origin —
keeping the leaky history off public refs.

> ⚠️ **GitHub GC caveat**: GitHub doesn't immediately garbage-collect
> orphaned commits after a force-push. The old SHA `4e42190` (and ancestors)
> remain reachable to anyone who knows the SHA for ~90 days, after which
> Git's reachability GC reaps them. Since all 5 leaked values were rotated
> *before* the force-push, exposure is closed at the source — the orphan
> reachability is informational only.

### What was kept vs dropped

| Kept | Dropped |
|---|---|
| `home/dot_config/tmux/tmux.conf.local` (the customizations) | `macos/silicon/tmux/tmux.conf` (vendored gpakosz snapshot — now external) |
| `home/dot_zshrc.tmpl` (consolidated from 3 copies) | `linux/lua-script/zshrc_file`, `macos/intel/zshrc_file`, `macos/silicon/dot_zshrc` (the 3 copies) |
| nvim config — see follow-ups | `window/nvim-windows/` (no active Windows usage) |
| `home/.chezmoiscripts/*` (working bootstrap) | `linux/install.sh`, `linux/install_zsh.sh`, `macos/intel/install.sh` (broken) |
| `home/dot_Brewfile` (auto-generated from `brew leaves` + `brew list --cask`) | None equivalent before — Brewfile is new |

### Bugs fixed during cutover

1. **`exclude` vs `filter.exclude`** in `.chezmoiexternal.toml`: my initial
   external used `filter.exclude` (silently ignored — `filter` is for
   piping content through external commands). Correct key is top-level
   `exclude`. Patterns must use `**/` prefix because they match against
   the full archive path BEFORE `stripComponents` is applied.
2. **`path.root` semantics changed in Packer 1.15** — equivalent issue
   pattern exists in chezmoi (data files must live in source root after
   `.chezmoiroot` redirect). Fixed by moving `.chezmoidata.toml` etc.
   INSIDE `home/`.
3. **`brew bundle --no-lock` deprecated** — modern brew rejects the flag.
   Fixed by using `brew bundle install --no-upgrade`.
4. **`[ -f X ] && source X` leaks exit 1** when X doesn't exist. The
   robbyrussell theme reads `$?` to render the prompt arrow color → red
   arrow on every fresh shell. Fixed by switching to `if/then/fi` form
   and adding a trailing `true` to `~/.zshrc`.
5. **Script shebang positioning** in `.chezmoiscripts/*.tmpl` — initial
   templates had `{{- if eq .chezmoi.os "darwin" }}` BEFORE the shebang,
   so non-darwin renders started with whitespace → `exec format error`.
   Fixed by putting shebang on line 1, OS check on line 2 via runtime
   `uname -s` rather than template conditional.
6. **SSH key not registered with GitHub** — earlier successful pushes
   used HTTPS+PAT via `osxkeychain` credential helper, which was
   invalidated when we rotated the PAT. Registered the local
   `id_ed25519.pub` via `gh ssh-key add` during the force-push step.

### Open follow-ups (NOT done as part of this restructure)

> **Status update — 2026-05-28**: 5 of the 7 follow-ups below are now done; see
> [Post-restructure additions](#post-restructure-additions-2026-05-27--2026-05-28)
> below for what shipped and where.

1. ✅ **Rotated GitLab + GitHub tokens** (2026-05-28). Fresh values pasted via
   `chezmoi edit ~/.envrc.private`. Old chat-shared values revoked.

2. ⏸ **Notify company security team about Azure SP exposure** — N/A as of
   2026-05-28: user no longer at that company; subscriptions are gone.
   Marked as not-applicable rather than not-done.

3. ✅ **Migrated `~/.config/nvim` into the chezmoi repo** (commit `50f8074`,
   2026-05-27). 87 files / 328 KB now at `home/dot_config/nvim/`. Chose
   the inline option rather than a separate `nvim-config` repo since the
   config rarely changes independently of other dotfiles.

4. ⏳ **Consider starship prompt** to replace oh-my-zsh `robbyrussell`
   theme (faster shell startup, more configurable, no plugin manager
   overhead). Still open — no urgency.

5. ✅ **Wired pre-commit gitleaks hook** (commit `b0601b8`, 2026-05-27).
   `home/dot_gitconfig.tmpl` sets `core.hooksPath = ~/.config/git/hooks`;
   `home/dot_config/git/hooks/executable_pre-commit` runs
   `gitleaks protect --staged`. Verified blocks real-shape GitHub PATs
   (`ghp_` + 36 alphanum) in a throwaway repo.

6. ⏳ **Per-machine `chezmoi.toml` overrides**: still open — no urgency
   (user runs only one machine currently).

7. ⏳ **CI on a self-hosted runner**: still open. The local pre-commit
   hook (#5 above) covers the per-commit case; CI would catch any commit
   pushed with `--no-verify` or from a machine without the hook.

### Post-restructure additions (2026-05-27 → 2026-05-28)

Follow-on work after the initial cutover, executed in three tiers:

#### Tier B — feature parity gaps

| Commit | What | Why |
|---|---|---|
| `50f8074` | Migrate `~/.config/nvim/` → `home/dot_config/nvim/` (87 files / 328 KB) | nvim config was floating outside any VCS; lost on a new machine |
| `0deb44e` | New `home/dot_config/apt-packages` + `run_onchange_after_install-linux-packages.sh.tmpl` | Linux equivalent of `dot_Brewfile`; auto-detects apt/dnf/pacman |
| `1c8b4d9` / `2764e51` | oh-my-zsh script auto-installs `zsh`+`git` via apt/dnf/pacman on Linux | Previously failed silently on stock Ubuntu; now bootstraps cleanly |

Also: deleted `~/.config/dotfiles-legacy/` (the pre-restructure repo
clone was kept for reference; no longer needed once new layout was
verified for ~5 days).

#### Tier C — pre-commit gitleaks hook

`b0601b8` — `feat(git): add managed pre-commit gitleaks hook`.

- New: `home/dot_config/git/hooks/executable_pre-commit` (chezmoi
  `executable_` prefix → rendered with `+x`).
- Modified: `home/dot_gitconfig.tmpl` — adds `hooksPath = ~/.config/git/hooks`
  under `[core]`.
- Hook runs `gitleaks protect --staged --no-banner --verbose`. If
  gitleaks isn't installed, prints a warning and allows the commit
  through (graceful degrade — `gitleaks` is in both `dot_Brewfile` and
  `apt-packages`, so it installs during normal bootstrap).
- Bypass for a single commit: `git commit --no-verify`. Long-term
  whitelist a value: append `# gitleaks:allow` to the line.

##### Test-value pitfalls (encountered while verifying)

Two false-negative misfires during testing:

1. `AKIAIOSFODNN7EXAMPLE` is in gitleaks' built-in allowlist (canonical
   AWS docs example) — the hook will not flag it. Don't use it as a
   test value.
2. The `github-pat` rule regex is `ghp_[a-zA-Z0-9]{36}` — exactly 36
   alphanum chars. Off-by-N test tokens silently pass. Generate with:
   ```bash
   FAKE="ghp_$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 36)"
   ```
   Always test in a throwaway repo like `/tmp/hook-test`, never in the
   live repo — misfires create real commits you have to reset.
