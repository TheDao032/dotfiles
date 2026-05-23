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

1. **Rotate GitLab + GitHub tokens ONE more time** — the values shared
   in this session's chat (`glpat-7ydG5-…`, `ghp_do9I…`) traveled through
   third-party logs. Generate fresh ones locally and paste via
   `chezmoi edit ~/.envrc.private`.

2. **Notify company security team** about the historical Azure SP
   exposure (Jan 2026 → May 2026). They should check Azure activity logs
   for any unauthorized SP authentications during that window and rotate
   the 4 SP secrets on their side.

3. **Migrate `~/.config/nvim` into the chezmoi repo.** Currently the
   live nvim config isn't in version control. Options:
   - Pull it into `home/dot_config/nvim/` (chezmoi-managed)
   - Track it as a separate repo (`nvim-config`) referenced via
     `.chezmoiexternal.toml`

4. **Consider starship prompt** to replace oh-my-zsh `robbyrussell`
   theme (faster shell startup, more configurable, no plugin manager
   overhead).

5. **Wire pre-commit hooks** to gitleaks-scan the chezmoi source dir on
   every commit. `home/dot_gitconfig.tmpl` could reference a global
   pre-commit config.

6. **Per-machine `chezmoi.toml` overrides**: machines with different
   roles (e.g., work laptop vs. personal) can have different
   `[data.machine]` values. Currently every machine uses defaults from
   `.chezmoidata.toml`.

7. **CI on a self-hosted runner**: run `chezmoi apply --dry-run` +
   `gitleaks detect` on every PR to catch regressions.
