#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

DOTFILES=$(cd -P -- "$(dirname -- "$0")" && cd .. && pwd -P)
WINDOWS_PATH="${WINDOWS_PATH:-}"
WIN_DRIVE="${WIN_DRIVE:-}"
if [ -z "$WINDOWS_PATH" ] && command -v powershell.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    # shellcheck disable=SC2016
    WIN_USERPROFILE=$(powershell.exe -NoProfile -NonInteractive -Command '$env:USERPROFILE' 2>/dev/null | tr -d '\r' || true)
    if [ -n "$WIN_USERPROFILE" ]; then
        WINDOWS_PATH=$(wslpath -u "$WIN_USERPROFILE" 2>/dev/null || true)
    fi
fi
if [ -n "$WINDOWS_PATH" ] && [ -z "$WIN_DRIVE" ]; then
    WIN_DRIVE="${WINDOWS_PATH%%/Users*}"
fi

backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d%H%M%S)"

ensure_dir() {
    mkdir -p "$1"
}

backup_path() {
    local target="$1"
    if [ -e "$target" ] || [ -L "$target" ]; then
        local rel="${target#"$HOME"/}"
        rel="${rel#/}"
        local dest="$backup_dir/$rel"
        ensure_dir "$(dirname "$dest")"
        mv "$target" "$dest"
        echo "Backed up $target -> $dest"
    fi
}

install_link() {
    local source="$1"
    local target="$2"
    ensure_dir "$(dirname "$target")"
    if [ -L "$target" ] && [ "$(readlink -- "$target")" = "$source" ]; then
        echo "Already linked $target -> $source"
        return 0
    fi
    backup_path "$target"
    ln -sfn "$source" "$target"
    echo "Linked $target -> $source"
}

install_file() {
    local source="$1"
    local target="$2"
    ensure_dir "$(dirname "$target")"
    if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$source" "$target"; then
        echo "Already up to date $target"
        return 0
    fi
    backup_path "$target"
    cp -Lf "$source" "$target"
    echo "Copied $source -> $target"
}

is_wsl() {
    if [ -r /proc/sys/kernel/osrelease ] && grep -qi microsoft /proc/sys/kernel/osrelease; then
        return 0
    fi
    if uname -r 2>/dev/null | grep -qi microsoft; then
        return 0
    fi
    return 1
}

find_gcm() {
    if command -v git-credential-manager.exe >/dev/null 2>&1; then
        command -v git-credential-manager.exe
        return 0
    fi

    local candidates=()
    local drives=()
    [ -n "$WIN_DRIVE" ] && drives+=("$WIN_DRIVE")
    drives+=(/mnt/c /c)

    for drive in "${drives[@]}"; do
        candidates+=(
            "$drive/Program Files/Git/mingw64/bin/git-credential-manager.exe"
            "$drive/Program Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
            "$drive/Program Files (x86)/Git/mingw64/bin/git-credential-manager.exe"
            "$drive/Program Files (x86)/Git/mingw64/libexec/git-core/git-credential-manager.exe"
        )
    done

    if [ -n "$WINDOWS_PATH" ]; then
        candidates+=(
            "$WINDOWS_PATH/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe"
            "$WINDOWS_PATH/AppData/Local/Programs/Git/mingw64/libexec/git-core/git-credential-manager.exe"
        )
    fi

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

find_pinentry_win() {
    if command -v pinentry.exe >/dev/null 2>&1; then
        command -v pinentry.exe
        return 0
    fi

    local candidates=()
    local drives=()
    [ -n "$WIN_DRIVE" ] && drives+=("$WIN_DRIVE")
    drives+=(/mnt/c /c)

    for drive in "${drives[@]}"; do
        candidates+=(
            "$drive/Program Files (x86)/Gpg4win/bin/pinentry.exe"
            "$drive/Program Files (x86)/Gpg4win/bin/pinentry-basic.exe"
            "$drive/Program Files (x86)/Gpg4win/bin/pinentry-qt.exe"
            "$drive/Program Files/Gpg4win/bin/pinentry.exe"
            "$drive/Program Files/Gpg4win/bin/pinentry-basic.exe"
            "$drive/Program Files/Gpg4win/bin/pinentry-qt.exe"
            "$drive/Program Files (x86)/GnuPG/bin/pinentry.exe"
            "$drive/Program Files (x86)/GnuPG/bin/pinentry-basic.exe"
            "$drive/Program Files/GnuPG/bin/pinentry.exe"
            "$drive/Program Files/GnuPG/bin/pinentry-basic.exe"
            "$drive/Gpg4win/bin/pinentry.exe"
        )
    done

    if [ -n "$WINDOWS_PATH" ]; then
        candidates+=(
            "$WINDOWS_PATH/AppData/Local/Programs/Gpg4win/bin/pinentry.exe"
            "$WINDOWS_PATH/AppData/Local/Programs/GnuPG/bin/pinentry.exe"
        )
    fi

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

echo "Dotfiles path: $DOTFILES"
if [ -n "$WINDOWS_PATH" ]; then
    echo "Windows home path: $WINDOWS_PATH"
else
    echo "PowerShell not detected; Windows path integration disabled"
fi

if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    sudo_check=$(sudo -n true 2>&1 || true)
    if echo "$sudo_check" | grep -q "no new privileges"; then
        echo "Skipping APT package installation (sudo restricted by container environment)"
    else
        echo "Installing APT packages from scripts/packages.txt"
        sudo apt-get update
        xargs -r sudo apt-get install -y < <(grep -E -v '^\s*(#|$)' "$DOTFILES/scripts/packages.txt")
        if command -v locale >/dev/null 2>&1 && ! grep -Eqi '^en_US\.utf-?8$' <<< "$(locale -a 2>/dev/null || true)"; then
            sudo locale-gen en_US.UTF-8
        fi
    fi
fi

if [ ! -d "$HOME/.oh-my-bash" ]; then
    echo "Installing Oh My Bash..."
    if command -v git >/dev/null 2>&1; then
        git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "$HOME/.oh-my-bash"
    elif command -v curl >/dev/null 2>&1; then
        mkdir -p "$HOME/.oh-my-bash"
        curl -fsSL https://github.com/ohmybash/oh-my-bash/archive/refs/heads/master.tar.gz | tar -xz -C "$HOME/.oh-my-bash" --strip-components=1
    fi
fi

if ! command -v uv >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/uv" ]; then
    if command -v curl >/dev/null 2>&1; then
        echo "Installing uv..."
        mkdir -p "$HOME/.local/bin"
        curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$HOME/.local/bin" UV_NO_MODIFY_PATH=1 sh
    fi
else
    echo "uv is already installed."
fi

if is_wsl && command -v sudo >/dev/null 2>&1; then
    sudo_check=$(sudo -n true 2>&1 || true)
    if echo "$sudo_check" | grep -q "no new privileges"; then
        echo "Skipping /etc/wsl.conf update (sudo restricted by container environment)"
    elif [ ! -f /etc/wsl.conf ] || ! cmp -s "$DOTFILES/wsl.conf" /etc/wsl.conf; then
        echo "Installing WSL configuration to /etc/wsl.conf"
        sudo cp -f "$DOTFILES/wsl.conf" /etc/wsl.conf
        echo "NOTE: /etc/wsl.conf has been updated. Please restart WSL from Windows ('wsl.exe --shutdown') for changes to take effect."
    else
        echo "/etc/wsl.conf is already up to date."
    fi
fi

ensure_dir "$HOME/.config/git"
ensure_dir "$HOME/.config/bash"
ensure_dir "$HOME/.config/ripgrep"
ensure_dir "$HOME/.config/nvim"
ensure_dir "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
ensure_dir "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

install_link "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"

for file in .gitignore .gitattributes .gitmessage; do
    install_link "$DOTFILES/git/$file" "$HOME/.config/git/$file"
done

# Provide standard fd and bat binary names in ~/.local/bin if only fdfind/batcat are present
ensure_dir "$HOME/.local/bin"
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/fd" ]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && [ ! -e "$HOME/.local/bin/bat" ]; then
    ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# SSH Configuration & Key synchronization
if [ -n "$WINDOWS_PATH" ] && [ -d "$WINDOWS_PATH/.ssh" ]; then
    if [ -f "$WINDOWS_PATH/.ssh/known_hosts" ]; then
        install_file "$WINDOWS_PATH/.ssh/known_hosts" "$HOME/.ssh/known_hosts"
        chmod 600 "$HOME/.ssh/known_hosts"
    fi

    if [ -f "$WINDOWS_PATH/.ssh/config" ]; then
        install_file "$WINDOWS_PATH/.ssh/config" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
    fi

    shopt -s nullglob
    for key in "$WINDOWS_PATH/.ssh"/id_*; do
        [ -f "$key" ] || continue
        keyfile=$(basename "$key")
        if [ ! -e "$HOME/.ssh/$keyfile" ] || [ -L "$HOME/.ssh/$keyfile" ]; then
            install_file "$key" "$HOME/.ssh/$keyfile"
        fi
        if [[ "$keyfile" == *.pub ]]; then
            chmod 644 "$HOME/.ssh/$keyfile"
        else
            chmod 600 "$HOME/.ssh/$keyfile"
        fi
    done
    shopt -u nullglob
fi

# GPG Configuration
install_link "$DOTFILES/gpg/gpg.conf" "$HOME/.gnupg/gpg.conf"

pinentry_win="$(find_pinentry_win || true)"
if [ -n "$pinentry_win" ]; then
    echo "Configuring GPG pinentry with Windows pinentry: $pinentry_win"
    ensure_dir "$HOME/.gnupg"
    cat > "$HOME/.gnupg/pinentry-wsl" <<EOF
#!/bin/sh
if [ -x "$pinentry_win" ]; then
    exec "$pinentry_win" "\$@"
elif command -v pinentry-curses >/dev/null 2>&1; then
    exec pinentry-curses "\$@"
elif [ -x /usr/bin/pinentry-curses ]; then
    exec /usr/bin/pinentry-curses "\$@"
fi
exit 1
EOF
    chmod 700 "$HOME/.gnupg/pinentry-wsl"

    agent_conf="$HOME/.gnupg/gpg-agent.conf"
    if [ -L "$agent_conf" ]; then
        rm -f "$agent_conf"
    elif [ -f "$agent_conf" ] && ! grep -q 'pinentry-wsl' "$agent_conf"; then
        backup_path "$agent_conf"
    fi
    cat > "$agent_conf" <<EOF
## 1-day timeout
default-cache-ttl 86400
max-cache-ttl 86400

## Pinentry (Windows GUI wrapper)
pinentry-program $HOME/.gnupg/pinentry-wsl
EOF
    chmod 600 "$agent_conf"
else
    install_link "$DOTFILES/gpg/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
fi

local_gitconfig="$HOME/.gitconfig.local"
ensure_dir "$(dirname "$local_gitconfig")"
if [ ! -f "$local_gitconfig" ]; then
    touch "$local_gitconfig"
fi

if command -v gpg >/dev/null 2>&1; then
    gpg_dirs=()
    [ -n "$WINDOWS_PATH" ] && gpg_dirs+=("$WINDOWS_PATH/.gpg")
    gpg_dirs+=("$HOME/.gpg")

    shopt -s nullglob
    for dir in "${gpg_dirs[@]}"; do
        if [ -d "$dir" ]; then
            for keyfile in "$dir"/*.gpg "$dir"/*.asc "$dir"/*.key; do
                if [ -f "$keyfile" ]; then
                    echo "Importing GPG key from $keyfile..."
                    gpg --import "$keyfile" || true
                fi
            done
        fi
    done
    shopt -u nullglob

    if command -v gpgconf >/dev/null 2>&1; then
        gpgconf --kill gpg-agent >/dev/null 2>&1 || true
    fi

    signing_key=$(git config --file "$DOTFILES/git/.gitconfig" user.signingkey 2>/dev/null || true)
    [ -z "$signing_key" ] && signing_key="377CC066EF008466"

    if gpg --list-secret-keys "$signing_key" >/dev/null 2>&1; then
        echo "GPG signing key $signing_key is present."
        git config --file "$local_gitconfig" --unset-all commit.gpgsign 2>/dev/null || true
    else
        echo "WARNING: GPG signing key $signing_key not found in gpg keyring."
        echo "Disabling commit.gpgsign in ~/.gitconfig.local until key is imported."
        git config --file "$local_gitconfig" --replace-all commit.gpgsign false
    fi
else
    echo "WARNING: gpg command not found."
    echo "Disabling commit.gpgsign in ~/.gitconfig.local until gpg is installed."
    git config --file "$local_gitconfig" --replace-all commit.gpgsign false
fi

# Git Credential Helper & GitHub CLI Setup
gcm_bin="$(find_gcm || true)"
if [ -n "$gcm_bin" ]; then
    echo "Configuring Git credential helper: $gcm_bin"
    # Escape spaces for Git's shell invocation of credential.helper
    escaped_gcm="${gcm_bin// /\\ }"
    git config --file "$local_gitconfig" --replace-all credential.helper "$escaped_gcm"
elif command -v gh >/dev/null 2>&1; then
    echo "Windows git-credential-manager not found. Configuring GitHub CLI credential helper."
    git config --file "$local_gitconfig" --replace-all credential.helper "!gh auth git-credential"
fi

if command -v git-lfs >/dev/null 2>&1; then
    echo "Configuring Git LFS..."
    git lfs install --skip-repo
fi

if command -v gh >/dev/null 2>&1; then
    echo "Checking GitHub CLI authentication status..."
    gh_status=$(gh auth status 2>&1 || true)
    if [ -z "$gh_status" ] || ! gh auth status >/dev/null 2>&1 || echo "$gh_status" | grep -Eqi "failed to log in|the token .* is invalid|not logged into|no .*accounts"; then
        echo "GitHub CLI is not authenticated or token is invalid."
        if [ -t 0 ] && [ -t 1 ]; then
            read -r -p "Would you like to run 'gh auth login' now? [y/N] " reply
            if [[ "$reply" =~ ^[Yy]$ ]]; then
                gh auth login
            fi
        else
            echo "To authenticate GitHub CLI, run: gh auth login"
        fi
    else
        echo "GitHub CLI authentication is valid."
    fi
fi

install_link "$DOTFILES/wget/.wgetrc" "$HOME/.wgetrc"
install_link "$DOTFILES/ripgrep/.ripgreprc" "$HOME/.config/ripgrep/.ripgreprc"
install_link "$DOTFILES/nvim/init.lua" "$HOME/.config/nvim/init.lua"

install_link "$DOTFILES/bash/.bashrc" "$HOME/.bashrc"
install_link "$DOTFILES/bash/.bash_profile" "$HOME/.bash_profile"
install_link "$DOTFILES/.profile" "$HOME/.profile"
install_link "$DOTFILES/bash/.inputrc" "$HOME/.inputrc"

for file in .bash_aliases .bash_functions .bash_exports; do
    install_link "$DOTFILES/bash/$file" "$HOME/.config/bash/$file"
done

echo "Dotfiles install complete."
echo "If you changed shell configuration, start a new session or run: source ~/.bashrc"
