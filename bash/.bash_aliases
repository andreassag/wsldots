# shellcheck shell=bash
# General aliases
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias e='explorer.exe'
alias clip='clip.exe'
alias reload='exec "${SHELL}" -l'

# WSL helpers
alias wslopen='openwin'

# Ubuntu binary name aliases
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    alias fd='fdfind'
fi
