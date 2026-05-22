# Adding (or rotating) a secret

All secrets live in `home/encrypted_private_dot_envrc.age`. When applied, this
decrypts to `~/.envrc.private`, which `~/.zshrc` sources on every interactive
shell.

## Quick workflow

```bash
chezmoi edit ~/.envrc.private
# chezmoi decrypts → opens in $EDITOR → re-encrypts on save
# Add/change a line like:
#   export MY_TOKEN="..."

chezmoi apply                    # re-renders ~/.envrc.private
source ~/.zshrc                  # new var live in current shell

chezmoi git -- add home/encrypted_private_dot_envrc.age
chezmoi git -- commit -m "chore(secrets): rotate MY_TOKEN"
chezmoi git -- push
```

## How `chezmoi edit` works for encrypted files

1. chezmoi reads the source file `home/encrypted_private_dot_envrc.age`
2. Uses your age private key (`~/.config/chezmoi/key.txt`) to decrypt to a temp file
3. Opens the temp file in `$EDITOR`
4. When you save + exit, chezmoi re-encrypts the file using the **public recipient**
   from `~/.config/chezmoi/chezmoi.toml` (`age.recipient`)
5. Writes back to `home/encrypted_private_dot_envrc.age`
6. Securely deletes the temp file

The plaintext **never touches disk in cleartext form** (chezmoi uses a tmpfs / shred-on-close pattern).

## Rotating a leaked secret

If a secret leaked (e.g., committed to git history):

1. **Revoke at the source** (the actual issuing system — GitHub PAT settings, GitLab token UI, Azure portal, etc.)
2. **Generate a new value** at the same source
3. **Update the encrypted file**:
   ```bash
   chezmoi edit ~/.envrc.private
   # replace the old value with the new one
   ```
4. **Apply + commit**:
   ```bash
   chezmoi apply
   chezmoi git -- add home/encrypted_private_dot_envrc.age
   chezmoi git -- commit -m "chore(secrets): rotate <name> (was leaked in <where>)"
   chezmoi git -- push
   ```
5. **Scrub history** (if the old value was committed):
   ```bash
   cd ~/.local/share/chezmoi
   pip install git-filter-repo
   git filter-repo --replace-text <(echo 'OLD_VALUE==>REDACTED')
   git push --force-with-lease origin main
   ```
   ⚠️ Force-push is acceptable for personal dotfiles. Coordinate if any other
   machine has pulled — they'll need to `git fetch origin && git reset --hard origin/main`.

## Rotating the age key

If your age private key is compromised, all encrypted files are vulnerable.
Steps to rotate (more involved than a single secret rotation):

### 1. Generate new keypair

```bash
mv ~/.config/chezmoi/key.txt ~/.config/chezmoi/key.txt.old
age-keygen -o ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
NEW_RECIPIENT=$(grep '^# public key:' ~/.config/chezmoi/key.txt | awk '{print $4}')
echo "New recipient: $NEW_RECIPIENT"
```

### 2. Update the chezmoi config recipient

Edit `~/.config/chezmoi/chezmoi.toml`:
```toml
[age]
    recipient = "<NEW_RECIPIENT>"
```

Also update `.chezmoi.toml.tmpl` in the repo so future `chezmoi init`s use the new recipient.

### 3. Re-encrypt every `encrypted_*` file

```bash
cd ~/.local/share/chezmoi
for f in $(find . -name 'encrypted_*'); do
    # Decrypt with OLD key
    age -d -i ~/.config/chezmoi/key.txt.old "$f" > /tmp/plain.tmp
    # Re-encrypt with NEW recipient
    age -r "$NEW_RECIPIENT" -o "$f" /tmp/plain.tmp
    shred -uvz /tmp/plain.tmp 2>/dev/null || rm -P /tmp/plain.tmp
done
```

### 4. Commit + push

```bash
chezmoi git -- add .
chezmoi git -- commit -m "chore(security): rotate age key"
chezmoi git -- push
```

### 5. Securely destroy the old key

```bash
shred -uvz ~/.config/chezmoi/key.txt.old 2>/dev/null || rm -P ~/.config/chezmoi/key.txt.old
```

### 6. Save the new private key to password manager

Update your password manager entry "chezmoi age key" with the contents of `~/.config/chezmoi/key.txt`.

### 7. Sync to other machines

On each other machine that pulls this repo:
```bash
# Restore new key from password manager
$EDITOR ~/.config/chezmoi/key.txt    # paste new key
chmod 600 ~/.config/chezmoi/key.txt
chezmoi git -- pull
chezmoi apply
```

## Best practices

- **One secret per env var.** Don't combine `TOKEN=ID:SECRET`; separate them.
- **Comment every secret with its source** (`# from: https://gitlab.com/.../tokens`)
  so future-you knows where to rotate it.
- **Date-stamp rotations** in commit messages (`chore(secrets): rotate FOO (2026-05-22)`).
- **Scan before commit**: `gitleaks detect` should pass on the chezmoi source dir
  (the encrypted file is opaque to gitleaks — it can't detect known patterns inside
  an age-encrypted blob).
- **Never `cat ~/.envrc.private`** in screen-shareable contexts. Use `set -o`
  to verify env vars are loaded without printing values.
