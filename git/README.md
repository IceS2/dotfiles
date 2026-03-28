# Git Configuration

Git configuration files for dotfiles repository.

## Files

- `.gitconfig` - Main Git configuration (safe to commit)
- `.gitconfig.local.template` - Template for private settings
- `setup.sh` - Setup script to create symlinks and initialize config

## Setup

Run the setup script:

```bash
./setup.sh
```

This will:
1. Create symlink: `~/.gitconfig` → `git_config/.gitconfig`
2. Copy `.gitconfig.local.template` to `~/.gitconfig.local` (if needed)
3. Display configuration instructions

## Configuration

Edit `~/.gitconfig.local` with your personal details:

```gitconfig
[user]
    name = Your Name
    email = your.email@example.com
    signingkey = YOUR_GPG_KEY_ID

[commit]
    gpgsign = true

[gpg]
    program = gpg
```

## What to Commit

✅ Commit: `.gitconfig`, `.gitconfig.local.template`, `setup.sh`, `README.md`
❌ Never commit: `~/.gitconfig.local` (private, gitignored)
