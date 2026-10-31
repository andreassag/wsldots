# Dotfiles for Windows Subsystems for Linux

> **IMPORTANT!**: Dotfile repository intended for personal use. Code is available for others to use, but most settings are personalized..

The dotfiles contain configuration for many different programs, and settings used in Windows Subsystem for Linux (WSL). The `setup` script installs essential programs and links configuration files so the repository works cleanly on Ubuntu WSL.

## Setup

Run the installer from the repository root:

```bash
./setup
```

The installer now:
- creates organized directories and backups for existing dotfiles
- installs essential packages from `scripts/packages.txt` (including `gh`, `git-lfs`, `pinentry-curses`, `shellcheck`, etc.)
- installs `oh-my-bash` and `uv` if missing
- links Git, Bash, GPG, SSH, wget, ripgrep, and Neovim configuration
- synchronizes SSH keys (`id_*`) and config from Windows (`$WINDOWS_PATH/.ssh`) with secure permissions (`chmod 600`/`644`)
- imports GPG keys and configures `gpg-agent` (with native Windows Gpg4win `pinentry.exe` GUI prompt when available)
- automatically detects and configures Git credential helpers (Windows `git-credential-manager.exe` or `gh auth git-credential` fallback) in `~/.gitconfig.local`
- checks GitHub CLI authentication (`gh auth status`) and offers interactive login (`gh auth login`) when needed
- installs WSL-aware config via `/etc/wsl.conf` idempotently
- configures a global Git ignore file at `~/.config/git/.gitignore`

## Added modules

- `.profile`
- `bash/.bashrc`
- `bash/.bash_profile`
- `bash/.bash_aliases`
- `bash/.bash_functions`
- `bash/.bash_exports`
- `bash/.inputrc`
- `git/.gitconfig`
- `git/.gitattributes`
- `gpg/gpg.conf`
- `gpg/gpg-agent.conf`
- `nvim/init.lua`
- `ripgrep/.ripgreprc`
- `wget/.wgetrc`
- `wsl.conf`
- `.wslconfig.example`
- `scripts/packages.txt`

## Local Machine Overrides

To customize settings on a specific machine without modifying tracked files:
- **Bash**: Create `~/.config/bash/.bashrc.local` (automatically sourced at the end of `~/.bashrc`).
- **Git**: Create `~/.gitconfig.local` (automatically included at the end of `~/.gitconfig`).

## WSL recommendations

Use the example Windows config from `.wslconfig.example` in your Windows home directory as `~/.wslconfig`.

If you need custom mount or environment behavior, edit `wsl.conf` or use Windows Terminal profiles with WSL.

## License

This project is licensed under `Unlicense`. For more details see [LICENSE](LICENSE).
