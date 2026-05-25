#!/usr/bin/env bash
# health-check.sh — comprehensive smoke test for this chezmoi setup.
#
# Runs 4 tiers of checks:
#   Tier 1 — Quick sanity (~10s): chezmoi doctor / status / diff
#   Tier 2 — Full diagnostic (~30s): templates, gitleaks, mapping, decryption
#   Tier 3 — Functional (~10s): fresh shell, env vars, tmux, gh CLI
#   Tier 4 — Fresh-machine sim (~1min): clone + apply to /tmp, verify
#
# Usage:
#   ./scripts/health-check.sh             # all tiers
#   ./scripts/health-check.sh quick       # only Tier 1
#   ./scripts/health-check.sh --no-tier4  # skip the fresh-machine sim (faster)
#
# Exit codes:
#   0 — all tiers passed
#   1 — any check failed
#
# Run from anywhere; uses absolute paths.

set -uo pipefail

REPO="$HOME/.config/dotfiles"
TIER1=true; TIER2=true; TIER3=true; TIER4=true
QUICK=false

for arg in "$@"; do
    case "$arg" in
        quick) QUICK=true; TIER2=false; TIER3=false; TIER4=false ;;
        --no-tier4) TIER4=false ;;
        --no-tier3) TIER3=false ;;
        --no-tier2) TIER2=false ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "Unknown arg: $arg"; exit 2 ;;
    esac
done

PASS=0; FAIL=0; WARN=0
log()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; WARN=$((WARN+1)); }

header() {
    echo
    printf '\033[1;36m==================== %s ====================\033[0m\n' "$1"
}

# ──────────────────────────────────────────────────────────────────────────────
# TIER 1 — Quick sanity
# ──────────────────────────────────────────────────────────────────────────────
if $TIER1; then
    header "TIER 1 — Quick sanity"

    if command -v chezmoi >/dev/null 2>&1; then
        ok "chezmoi installed: $(chezmoi --version | awk '{print $3}')"
    else
        bad "chezmoi not on PATH"; exit 1
    fi

    if chezmoi doctor 2>&1 | grep -qE '^error'; then
        bad "chezmoi doctor reports errors"
        chezmoi doctor | grep -E '^(error|warning)'
    else
        warns=$(chezmoi doctor 2>&1 | grep -cE '^warning')
        if [ "$warns" -gt 0 ]; then
            warn "chezmoi doctor: $warns warning(s) — likely benign"
        else
            ok "chezmoi doctor: all green"
        fi
    fi

    status=$(chezmoi status 2>&1)
    if [ -z "$status" ]; then
        ok "chezmoi status: clean (no pending changes)"
    else
        warn "chezmoi status: pending changes"
        echo "$status" | sed 's/^/    /'
    fi

    diff_lines=$(chezmoi diff 2>&1 | wc -l | tr -d ' ')
    if [ "$diff_lines" = "0" ]; then
        ok "chezmoi diff: 0 lines (source = destination)"
    else
        warn "chezmoi diff: $diff_lines lines of pending changes"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# TIER 2 — Full diagnostic
# ──────────────────────────────────────────────────────────────────────────────
if $TIER2; then
    header "TIER 2 — Full diagnostic"

    # 2.1 — every template renders
    n_ok=0; n_fail=0
    while IFS= read -r tmpl; do
        if chezmoi execute-template < "$tmpl" >/dev/null 2>/tmp/health-tmpl-err; then
            n_ok=$((n_ok+1))
        else
            bad "template error in $(basename "$tmpl"): $(head -1 /tmp/health-tmpl-err)"
            n_fail=$((n_fail+1))
        fi
    done < <(find "$REPO/home" -name '*.tmpl' -type f 2>/dev/null)
    [ "$n_fail" = 0 ] && ok "All $n_ok templates render cleanly"

    # 2.2 — gitleaks
    if command -v gitleaks >/dev/null 2>&1; then
        if (cd "$REPO" && gitleaks detect --no-banner 2>&1 | grep -q 'no leaks found'); then
            ok "gitleaks: no leaks in repo (working tree + history)"
        else
            bad "gitleaks: leaks detected — run \`gitleaks detect --source $REPO\` to inspect"
        fi
    else
        warn "gitleaks not installed (brew install gitleaks)"
    fi

    # 2.3 — encrypted file decrypts
    if age -d -i "$HOME/.config/chezmoi/key.txt" \
        "$REPO/home/encrypted_private_dot_envrc.private" \
        > /dev/null 2>/tmp/health-age-err; then
        ok "Encrypted secrets file decrypts cleanly with current key"
    else
        bad "Encrypted secrets file decrypt FAILED: $(cat /tmp/health-age-err)"
    fi

    # 2.4 — key file permissions
    key_perm=$(stat -f '%Sp' "$HOME/.config/chezmoi/key.txt" 2>/dev/null)
    if [ "$key_perm" = "-rw-------" ]; then
        ok "age private key mode 600"
    else
        bad "age private key wrong perms: $key_perm (expected -rw-------)"
        log "  fix: chmod 600 ~/.config/chezmoi/key.txt"
    fi

    # 2.5 — count managed files
    n_managed=$(chezmoi managed 2>/dev/null | wc -l | tr -d ' ')
    ok "chezmoi managed $n_managed files"
fi

# ──────────────────────────────────────────────────────────────────────────────
# TIER 3 — Functional
# ──────────────────────────────────────────────────────────────────────────────
if $TIER3; then
    header "TIER 3 — Functional"

    # 3.1 — fresh shell loads with exit 0
    if zsh -i -c 'exit 0' 2>/dev/null; then
        rc=$(zsh -i -c 'echo $?' 2>/dev/null)
        if [ "$rc" = "0" ]; then
            ok "Fresh zsh loads with exit code 0"
        else
            bad "Fresh zsh exit code: $rc (should be 0; red prompt arrow if non-zero)"
        fi
    else
        bad "Fresh zsh failed to launch"
    fi

    # 3.2 — expected env vars set in fresh shell
    for var in GITLAB_TOKEN GITHUB_TOKEN HCP_CLIENT_ID HCP_CLIENT_SECRET VAGRANT_CLOUD_ORG EDITOR ZSH; do
        val=$(zsh -i -c "echo -n \${$var}" 2>/dev/null | grep -v 'cant change' | tr -d '\n')
        if [ -n "$val" ]; then
            ok "env $var set (len=${#val})"
        else
            bad "env $var MISSING"
        fi
    done

    # 3.3 — tmux loads
    if tmux -f "$HOME/.config/tmux/tmux.conf" -L probe-hc new-session -d 'true' 2>/dev/null; then
        ok "tmux loads ~/.config/tmux/tmux.conf cleanly"
        tmux -L probe-hc kill-server 2>/dev/null || true
    else
        bad "tmux failed to load config"
    fi

    # 3.4 — gh CLI authenticated
    if gh auth status 2>&1 | grep -q '✓ Logged in to github.com'; then
        ok "gh CLI authenticated to GitHub"
    else
        warn "gh CLI not authenticated — run \`gh auth login\`"
    fi
fi

# ──────────────────────────────────────────────────────────────────────────────
# TIER 4 — Fresh-machine simulation
# ──────────────────────────────────────────────────────────────────────────────
if $TIER4; then
    header "TIER 4 — Fresh-machine simulation"

    SIM=/tmp/chezmoi-fresh-sim-hc
    rm -rf "$SIM" "$SIM-config" "$SIM-home" 2>/dev/null
    mkdir -p "$SIM-config" "$SIM-home"

    # Clone from origin (simulates `chezmoi init` on new machine)
    if git clone -q "$(cd "$REPO" && git remote get-url origin)" "$SIM" 2>/tmp/health-clone-err; then
        ok "Clone repo from origin (fresh-machine equivalent)"
    else
        bad "git clone failed: $(head -1 /tmp/health-clone-err)"
        rm -rf "$SIM" "$SIM-config" "$SIM-home"; exit 1
    fi

    # Synth chezmoi config pointing at fresh clone + tmp home
    cat > "$SIM-config/chezmoi.toml" <<EOF
sourceDir   = "$SIM"
destDir     = "$SIM-home"
encryption  = "age"

[age]
    identity  = "$HOME/.config/chezmoi/key.txt"
    recipient = "age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4"
EOF

    # Apply (files only — don't run brew/install scripts in sim)
    if chezmoi --config "$SIM-config/chezmoi.toml" apply --force --exclude=scripts --refresh-externals >/dev/null 2>/tmp/health-apply-err; then
        ok "Apply to fresh \$HOME succeeded"
    else
        bad "Apply failed: $(head -1 /tmp/health-apply-err)"
        rm -rf "$SIM" "$SIM-config" "$SIM-home"; exit 1
    fi

    # Verify the same files landed
    n_files=$(find "$SIM-home" -type f | wc -l | tr -d ' ')
    if [ "$n_files" -ge 9 ]; then
        ok "$n_files files rendered into fresh \$HOME"
    else
        bad "Only $n_files files rendered (expected ≥9)"
    fi

    # Verify .envrc.private decrypted
    if [ -f "$SIM-home/.envrc.private" ]; then
        if grep -q 'export.*=' "$SIM-home/.envrc.private"; then
            ok "Secrets file decrypted with valid contents"
        else
            bad ".envrc.private exists but looks empty/garbled"
        fi
    else
        bad ".envrc.private missing in fresh sim"
    fi

    # Verify tmux external pulled
    if [ -f "$SIM-home/.config/tmux/.tmux.conf" ]; then
        size=$(wc -c < "$SIM-home/.config/tmux/.tmux.conf" | tr -d ' ')
        if [ "$size" -gt 50000 ]; then
            ok "gpakosz/.tmux external pulled (.tmux.conf size: ${size}B)"
        else
            bad "tmux external too small: ${size}B (expected ~99K)"
        fi
    else
        bad "tmux external NOT pulled"
    fi

    rm -rf "$SIM" "$SIM-config" "$SIM-home"
    ok "Cleanup done"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────────────────────
echo
printf '\033[1;36m==================== Summary ====================\033[0m\n'
printf '  passes:   \033[32m%d\033[0m\n' "$PASS"
printf '  warnings: \033[33m%d\033[0m\n' "$WARN"
printf '  failures: \033[31m%d\033[0m\n' "$FAIL"

if [ "$FAIL" -gt 0 ]; then
    echo
    printf '  \033[31m✗\033[0m Some checks failed — investigate above.\n'
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo
    printf '  \033[33m!\033[0m All checks passed but %d warning(s) noted.\n' "$WARN"
    exit 0
else
    echo
    printf '  \033[32m✓\033[0m All checks passed cleanly.\n'
    exit 0
fi
