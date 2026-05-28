# Security model

How secrets are protected in this dotfiles setup, what threats are in/out of
scope, what YOU must do to maintain the protection, and what to do if you
suspect compromise.

> This doc exists because "store keys in a plaintext file" looks alarming on
> first read. The short answer: it's the same pattern as `~/.ssh/id_ed25519`,
> `~/.aws/credentials`, `~/.kube/config` — industry-standard for personal
> credential files in your own home directory. Read on for the nuance.

---

## Table of contents

1. [The trust boundary](#1-the-trust-boundary)
2. [What's protected and how](#2-whats-protected-and-how)
3. [What's NOT protected (out of scope)](#3-whats-not-protected-out-of-scope)
4. [Your responsibilities](#4-your-responsibilities)
5. [Incident response — suspected compromise](#5-incident-response--suspected-compromise)
6. [Why we chose the plaintext-key model](#6-why-we-chose-the-plaintext-key-model)
7. [Alternatives we considered](#7-alternatives-we-considered)
8. [Threat model — concrete examples](#8-threat-model--concrete-examples)
9. [Checklist — verify the model is in place](#9-checklist--verify-the-model-is-in-place)

---

## 1. The trust boundary

**The trust boundary is your macOS user account.**

Anyone who can run code AS YOUR USER on this machine can:

- Read your SSH keys (`~/.ssh/id_ed25519`)
- Read your AWS credentials (`~/.aws/credentials`)
- Read your GitHub PAT in macOS Keychain
- Inspect ssh-agent state, browser-saved passwords, environment variables
- Read `~/.config/chezmoi/key.txt` and decrypt your `encrypted_*` files

The age private key is **inside** that boundary — it's protected by the
same fence that protects everything else local-credential-like.

If an attacker breaches the trust boundary (gets shell as you), nothing
about the chezmoi-secrets setup makes that worse than it would already be.

If you're targeted by a higher-tier attacker (hardware-attested keys,
state-actor threat model), this whole personal-machine setup is the wrong
abstraction — use a YubiKey + hardware-attested signing instead. See
[§7 Alternatives](#7-alternatives-we-considered).

---

## 2. What's protected and how

### Layer 1 — file permissions (chmod 600)

```
~/.config/chezmoi/key.txt    -rw------- (mode 600, owned by you)
```

Only your macOS user can read this file. Other macOS users on the same
machine cannot. Background processes running as a different UID cannot.

Verify:
```bash
ls -la ~/.config/chezmoi/key.txt
# expect:  -rw-------@ 1 thedao  staff   189  ... key.txt
```

### Layer 2 — macOS user account isolation

macOS enforces per-user file ownership via the kernel. A user-level process
can't read files mode 600 owned by a different user without `sudo`.

### Layer 3 — FileVault (full-disk encryption)

If the laptop is stolen with the screen locked / powered off, the disk is
encrypted at rest. The age key (and everything else in your home dir)
remains unreadable until someone logs in with your account password.

Verify:
```bash
fdesetup status
# expect: "FileVault is On."
```

FileVault has been default-on for macOS users since Mojave (2018), so this
should already be the case. If not, enable in **System Settings → Privacy &
Security → FileVault → Turn On**.

### Layer 4 — age encryption (for the secrets, not the key itself)

The secrets file `home/encrypted_private_dot_envrc.private` IS encrypted
with age. Anyone who reads the encrypted blob without the private key sees
gibberish. This is what protects secrets in the GIT REPO (where chmod
doesn't apply — anyone with read access to github.com/TheDao032/dotfiles
sees the binary blob).

The age private key (in `~/.config/chezmoi/key.txt`) is the credential
that unlocks the secrets. Protected by Layers 1-3.

### Layer 5 — pre-commit gitleaks hook (prevents accidental re-introduction)

`home/dot_gitconfig.tmpl` sets `core.hooksPath = ~/.config/git/hooks`, and
chezmoi deploys `home/dot_config/git/hooks/executable_pre-commit` →
`~/.config/git/hooks/pre-commit` (executable). On every `git commit` in
**every repo on this machine**, the hook runs `gitleaks protect --staged`.
If gitleaks finds a known secret pattern (AWS keys, GitHub PATs, GitLab
PATs, Stripe keys, ~120 rules total) in the staged diff, the commit is
**aborted before it lands**.

This is the layer that protects against YOU — the keyboard operator —
fat-fingering a secret into a tracked file and pushing it to GitHub.
Layers 1–4 protect against attackers reading data at rest; Layer 5
protects against you typing it into git.

Verify it's active:
```bash
git config --global --get core.hooksPath
# expect: ~/.config/git/hooks
ls -la ~/.config/git/hooks/pre-commit
# expect: -rwxr-xr-x ... (executable)
```

Bypass for a single commit (use only when you're sure it's a false
positive — and prefer `# gitleaks:allow` on the line for long-term
silencing):
```bash
git commit --no-verify ...
```

Graceful-degrade behavior: if `gitleaks` isn't installed on the machine,
the hook prints a warning and allows the commit. Both `dot_Brewfile`
(macOS) and `dot_config/apt-packages` (Linux) include gitleaks, so this
fallback should only fire mid-bootstrap.

---

## 3. What's NOT protected (out of scope)

| Threat | Why out of scope |
|---|---|
| Attacker has root on your Mac | Root reads everything. Defense: don't get rooted. |
| Malware running as YOUR user | Has same privileges you do. Defense: install trusted software only. |
| Cold-boot RAM scraping while logged in | Defense: enable Hibernate, not Sleep, on long absences |
| State-actor / nation-state targeting | Defense: hardware-backed keys (YubiKey + age-plugin-yubikey) |
| Quantum computers breaking X25519 | age uses X25519 — future PQ-ready alternatives exist but not yet standard |
| Lost/forgotten private key | **YOUR fault — back it up to a password manager (see §4)** |
| Backup tool stores the key in cleartext on an unencrypted backup target | Defense: encrypt backups OR exclude `~/.config/chezmoi/key.txt` from backups |

---

## 4. Your responsibilities

These are the things YOU must do to keep this model intact:

### 4.1 Back up the private key to a password manager (CRITICAL)

If you lose the key, you lose **all encrypted secrets forever**. There's no
recovery — age has no backdoor.

**One-time action:**
```bash
# Copy the key content to clipboard (macOS) — do this on a screen no one else can see
pbcopy < ~/.config/chezmoi/key.txt

# Open Bitwarden → New Item → Secure Note
# Title: "chezmoi age private key"
# Notes (paste from clipboard)
# Description: "Private key for ~/.config/chezmoi/key.txt.
#               Restore on new machine via docs/ONBOARDING.md step 2.
#               Created 2026-05-22. Public recipient:
#               age1yykdvcl7hu2kf4klk854atdkawhutj4dq54zpg98hc03s35hdycqmrdlz4"

# Clear clipboard (paranoia)
echo -n '' | pbcopy
```

🟡 **You haven't done this yet** (as of 2026-05-24). Do it now.

### 4.2 Keep FileVault enabled

Verify quarterly:
```bash
fdesetup status
```

If you ever turn it off (e.g., for some weird repair scenario), turn it
back on as soon as possible.

### 4.3 Lock your screen when stepping away

`Cmd-Ctrl-Q` or set hot corners. Five seconds. Habitual.

### 4.4 Don't run untrusted scripts

The age key is readable by any code running as you. `curl ... | bash` is
the canonical example of WHY this matters.

If you must run third-party scripts, read them first. If you can't read
them, run them in a VM or container, not on your daily-driver.

### 4.5 Exclude the key from cloud backups (optional but recommended)

If you use Time Machine, iCloud, Backblaze, Arq, or any other cloud
backup tool that might store backups on remote / non-encrypted media:

```bash
# Time Machine (sudo required — adds to TM exclusion list)
sudo tmutil addexclusion ~/.config/chezmoi/key.txt

# Verify
tmutil isexcluded ~/.config/chezmoi/key.txt
# expect: [Excluded]
```

iCloud Drive doesn't sync `~/.config/` by default, so you're safe there
without action.

If you use Backblaze/Arq, add `~/.config/chezmoi/key.txt` to the
exclusion patterns in those apps' preferences.

### 4.6 Don't commit the key

`.gitignore` of the chezmoi source repo doesn't list `~/.config/chezmoi/`
(it's outside the repo entirely). The key lives at
`~/.config/chezmoi/key.txt` — completely separate from
`~/.config/dotfiles/` (the chezmoi source).

But: if you ever copy the key into the repo for any reason (e.g., to
share with yourself), git WILL track it. Always reference the absolute
path; never `cp` it into the chezmoi source dir.

If you accidentally commit it: rotate immediately (see §5).

### 4.7 Rotate keys/secrets after any suspected compromise

See [§5 Incident response](#5-incident-response--suspected-compromise).

---

## 5. Incident response — suspected compromise

### Scenarios that require action

| Scenario | Severity | Action |
|---|---|---|
| Lost laptop (unlocked) | CRITICAL | Rotate everything immediately (§5.1) |
| Lost laptop (locked + FileVault on) | LOW | Optional rotation; mostly fine |
| Suspected malware running as you | CRITICAL | Rotate everything; reinstall macOS if confident in malware presence |
| Key file accidentally committed to public repo | CRITICAL | Rotate immediately (§5.1) |
| Key file accidentally shared via chat / email / Slack | HIGH | Rotate immediately |
| Got phished (entered macOS password into a fake prompt) | CRITICAL | Rotate everything; change macOS password |
| Used a public/shared Mac and forgot to log out | MEDIUM | Rotate macOS password; rotate keys as precaution |

### 5.1 Full rotation procedure

In order — DO NOT skip steps:

**Step A — rotate the secrets THE KEY PROTECTS** (the things that actually matter):
```bash
# Open ~/.envrc.private and rotate each secret at its respective source.
# (Run `chezmoi edit ~/.envrc.private` to see them — decrypts in tmpfs.)
# Rotate at the SOURCE (GitLab, GitHub, HCP, etc.) and update the encrypted
# file with new values, then `chezmoi apply`.
```

**Step B — rotate the age key itself:**
```bash
# 1. Generate new key
mv ~/.config/chezmoi/key.txt ~/.config/chezmoi/key.txt.old
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
NEW_RECIPIENT=$(grep '^# public key:' ~/.config/chezmoi/key.txt | awk '{print $4}')
echo "New recipient: $NEW_RECIPIENT"

# 2. Update chezmoi.toml with the new recipient
$EDITOR ~/.config/chezmoi/chezmoi.toml
# Change: recipient = "<NEW_RECIPIENT>"

# 3. Update .chezmoi.toml.tmpl in the repo so future chezmoi inits use it
chezmoi cd
$EDITOR .chezmoi.toml.tmpl
# Same change to the [age] recipient line

# 4. Re-encrypt every encrypted_* file with the new recipient
for f in $(find . -name 'encrypted_*'); do
    age -d -i ~/.config/chezmoi/key.txt.old "$f" > /tmp/plain.tmp
    age -r "$NEW_RECIPIENT" -o "$f" /tmp/plain.tmp
    rm -P /tmp/plain.tmp
done

# 5. Commit + push
git add -A
git commit -m "chore(security): rotate age key (incident response)"
git push

# 6. Securely destroy the old key
rm -P ~/.config/chezmoi/key.txt.old

# 7. Update password manager backup with new private key
cat ~/.config/chezmoi/key.txt
# Open Bitwarden → edit "chezmoi age private key" → paste new value
```

**Step C — change your macOS password** if the suspected compromise involved
account credentials (e.g., phishing, public-machine use).

**Step D — change your SSH key for GitHub/GitLab/etc.**:
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new -C "$(date +%F)"
# Add to GitHub
gh ssh-key add ~/.ssh/id_ed25519_new.pub --title "rotation-$(date +%F)"
# Remove old key from GitHub
gh ssh-key list  # find old key ID
gh ssh-key delete <ID>
# Update local
mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.old
mv ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519.old.pub
mv ~/.ssh/id_ed25519_new ~/.ssh/id_ed25519
mv ~/.ssh/id_ed25519_new.pub ~/.ssh/id_ed25519.pub
```

### 5.2 Log review

After any suspected incident, check:

- **GitHub**: https://github.com/settings/security-log (sign-ins, key changes, token use)
- **GitLab**: https://gitlab.com/-/user_settings/audit_log
- **HCP**: https://portal.cloud.hashicorp.com/ → Activity logs
- **Azure** (if applicable): Sign-in logs in Entra ID
- **macOS**: `log show --predicate 'eventMessage CONTAINS "authentication"' --last 24h`

Look for unfamiliar IPs, times, or actions.

---

## 6. Why we chose the plaintext-key model

Decision recorded 2026-05-23 during the chezmoi restructure.

### Considered alternatives

See [§7 Alternatives](#7-alternatives-we-considered) for the full comparison.

### What ruled them out vs. plaintext + chmod 600

| Alternative | Why we didn't pick it |
|---|---|
| Passphrase-encrypted key | Defeats automation — chezmoi apply would prompt every time |
| YubiKey (hardware-backed) | Overkill for personal threat model; YubiKey not currently owned |
| 1Password/Bitwarden integration | Adds runtime dependency on secrets manager being unlocked; same trust-boundary issue (the BW session token lives in `~/.config/Bitwarden CLI/`) |
| macOS Keychain wrapper | No native chezmoi support; would require custom plumbing; macOS-only (breaks Linux portability if ever needed) |
| Cloud KMS (AWS KMS, GCP KMS) | Network dependency every apply; cost; same auth-token-on-disk problem |

### What confirmed plaintext + chmod 600 was the right call

1. **It IS the industry pattern for personal credential files** — SSH, AWS,
   kubectl, gh CLI, GitHub Desktop all use the same model.
2. **The trust boundary is your user account, period** — adding "encrypt
   the key" just creates a key-to-decrypt-the-key turtles-all-the-way-down
   problem.
3. **Automation-friendly** — `chezmoi apply` runs silently with no prompts.
4. **Portable** — works identically on macOS and Linux.
5. **Zero runtime dependencies** — age is a single static binary.
6. **The actual security comes from**: rotation discipline + FileVault +
   strong macOS password + not running untrusted code. NONE of which depend
   on how the key is stored.

### When this decision should be revisited

Re-evaluate the chosen model if any of these become true:

- You start storing **production secrets** in chezmoi (e.g., real customer
  data tokens) — upgrade to YubiKey
- You start using this on **shared machines** — upgrade to YubiKey or
  per-machine keys
- You become **specifically targeted** by adversaries with the resources
  to extract files from a logged-in macOS user — full re-architecture
  needed (out of scope for personal dotfiles)
- You add **multiple machines** with different sensitivities — consider
  per-machine keypairs

---

## 7. Alternatives we considered

Ranked least-to-most paranoid. **Bold** = current choice.

### Tier 0 — current choice

#### **Plaintext key file + chmod 600 + FileVault**
- **Storage**: `~/.config/chezmoi/key.txt` plain text, mode 600
- **Decrypt step**: chezmoi reads the file directly
- **Pros**: Simple, fast, automation-friendly, portable, zero deps
- **Cons**: Vulnerable to anyone running code as your user
- **When to use**: Personal machines, normal threat model
- **Cost**: Free (already on every macOS)

### Tier 1 — slightly more paranoid

#### Passphrase-protected key file
- **Storage**: `~/.config/chezmoi/key.age` (age-encrypted with a passphrase)
- **Decrypt step**: chezmoi prompts for passphrase
- **Pros**: Even file-read doesn't compromise (need passphrase too)
- **Cons**: Every `chezmoi apply` prompts; defeats `run_onchange_*` automation; passphrase has same trust boundary if in your head
- **When to use**: If you really hate the plaintext file and don't run apply often
- **Cost**: Free
- **Migration**:
  ```bash
  age-keygen | age -p > ~/.config/chezmoi/key.age
  # then change chezmoi.toml: identity = "~/.config/chezmoi/key.age"
  ```

### Tier 2 — secrets-manager integration

#### Bitwarden CLI integration
- **Storage**: Bitwarden vault (encrypted by Bitwarden); local cache in `~/.config/Bitwarden CLI/data.json`
- **Decrypt step**: chezmoi calls `bw get` at template-render time
- **Pros**: Centralized secrets across all your machines/devices via Bitwarden sync; integrates with 2FA
- **Cons**: Bitwarden session token still lives on disk (same trust-boundary issue, different file); network dependency; chezmoi templates become coupled to Bitwarden
- **When to use**: You already use Bitwarden heavily and want one place for everything
- **Cost**: Free (Bitwarden free tier is generous)
- **Migration**: Move secrets out of `encrypted_private_dot_envrc.private` into Bitwarden items; rewrite templates to use `{{ bitwarden ... }}` template functions

### Tier 3 — hardware-backed

#### YubiKey + age-plugin-yubikey
- **Storage**: Private key never leaves the YubiKey hardware (PIV slot)
- **Decrypt step**: chezmoi calls age, age calls plugin, plugin talks to YubiKey
- **Pros**: Physical-attestation; PIN-protected; private key extraction requires defeating hardware
- **Cons**: Must have YubiKey plugged in; lose YubiKey → lose access (need backup YubiKey); ~$50 hardware cost; setup ceremony
- **When to use**: Production signing keys, high-value targets, regulated environments
- **Cost**: $25-50 per YubiKey (recommend 2 for backup)
- **Migration**: `age-plugin-yubikey --generate`; update chezmoi.toml to point at the PIV identity; re-encrypt all `encrypted_*` files for the new recipient

### Tier 4 — full re-architecture

#### Cloud KMS / Vault
- **Storage**: Cloud-managed (AWS KMS, GCP KMS, HashiCorp Vault, etc.)
- **Decrypt step**: chezmoi calls cloud API to decrypt; cloud auth needed
- **Pros**: Centralized audit logs; org-wide rotation; key never on disk
- **Cons**: Network dependency every apply; cloud auth token has to live somewhere (full circle); cost; overkill for personal
- **When to use**: Org-wide secrets management; not personal dotfiles
- **Cost**: AWS KMS ~$1/month per key + per-request fees

---

## 8. Threat model — concrete examples

Walking through specific attack scenarios and what protects you.

### Scenario 1 — laptop stolen from a café, screen locked

- Attacker has physical disk
- FileVault (Layer 3) → disk encrypted at rest → can't read anything
- Without your macOS password → can't unlock the volume
- ✅ **Safe**

### Scenario 2 — laptop stolen from a café, screen unlocked

- Attacker has full session as you
- All credentials compromised (SSH, age, browser, etc.)
- Defense: lock your screen religiously
- 🚨 **Immediate full rotation needed** (§5)

### Scenario 3 — you `curl malicious.sh | bash` by accident

- Script runs as you, reads `~/.config/chezmoi/key.txt`
- Decrypts your `~/.envrc.private`, exfiltrates your tokens
- Defense: don't run untrusted code; if you must, do it in a VM
- 🚨 **Immediate full rotation needed**

### Scenario 4 — you accidentally `cat ~/.config/chezmoi/key.txt` in front of a colleague

- Colleague sees the key on your screen
- They could memorize it (long random string — unlikely but possible) or photograph it
- Defense: don't `cat` the key in front of others
- 🟡 **Optional rotation**, depending on who the colleague is

### Scenario 5 — Time Machine backup disk gets stolen

- Backup contains `~/.config/chezmoi/key.txt`
- If TM backup is encrypted (default for modern macOS) → safe
- If TM backup is unencrypted → key is exposed → rotate
- Defense: §4.5 (encrypt backups or exclude the key)

### Scenario 6 — you push the chezmoi source dir to a public GitHub repo by mistake

- The encrypted file is public, BUT the key is NOT in the repo
- Without the key, the encrypted blob is gibberish
- The only thing public is `age-encrypted ciphertext` which is computationally infeasible to crack
- ✅ **Safe** — but verify the key really wasn't committed:
  ```bash
  cd ~/.config/dotfiles
  git log --all --full-history -- 'home/.chezmoi*' 'key.txt' 'AGE-SECRET-KEY-*'
  ```

### Scenario 7 — quantum computer breaks X25519 in 2035

- Age's current crypto becomes vulnerable
- All historical encrypted files become decryptable to anyone with the ciphertext + a sufficiently-large QC
- Defense: rotate to a post-quantum age recipient when age supports it; assume historical secrets are eventually exposed (so rotate them on their own cycles)
- 🟡 **Future migration to post-quantum age**, not actionable today

---

## 9. Checklist — verify the model is in place

Run through this list quarterly (or after any major OS update):

```bash
# 1. Key file exists and is mode 600
ls -la ~/.config/chezmoi/key.txt
# expect: -rw-------@ ... key.txt

# 2. Key is NOT in any git repo (sanity check)
find ~/.config/dotfiles -name 'key.txt' 2>/dev/null
# expect: NO output

# 3. FileVault is on
fdesetup status
# expect: "FileVault is On."

# 4. The key is backed up in your password manager
#    (Manual verify — open Bitwarden, look for "chezmoi age private key")

# 5. Public recipient in chezmoi.toml matches the key's public half
grep '^# public key:' ~/.config/chezmoi/key.txt | awk '{print $4}'
grep 'recipient' ~/.config/chezmoi/chezmoi.toml | head -1
# expect: same value in both

# 6. The encrypted file actually decrypts (sanity)
age -d -i ~/.config/chezmoi/key.txt ~/.config/dotfiles/home/encrypted_private_dot_envrc.private | head -3
# expect: cleartext content

# 7. gitleaks doesn't find any leaked secrets in the source repo
cd ~/.config/dotfiles && gitleaks detect --no-banner 2>&1 | tail -3
# expect: "no leaks found"

# 8. ssh-agent has your GitHub key loaded (so push works)
ssh-add -l 2>&1 | grep -q 'id_ed25519' && echo "OK" || echo "MISSING — run ssh-add"

# 9. Time Machine exclusion (if you use TM)
tmutil isexcluded ~/.config/chezmoi/key.txt 2>&1
# expect: [Excluded] (if you use Time Machine; otherwise N/A)

# 10. Screen lock is fast (verify in System Settings → Lock Screen)
#     - "Require password after sleep or screen saver": Immediately or "5 seconds"
#     - "Start screen saver after": <= 5 minutes
```

If any of 1, 2, 3, 5, 6, or 7 fail, **investigate before doing anything else**.

If 4, 8, 9, or 10 fail, **fix them this week** but they're not immediate emergencies.

---

## Document history

| Date | Change |
|---|---|
| 2026-05-24 | Initial draft after user questioned the plaintext-key approach. Establishes the trust-boundary model + lists alternatives considered + provides incident-response procedures. |
