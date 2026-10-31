# shellcheck shell=bash disable=SC1090,SC1091,SC2034
# Path to your oh-my-bash installation.
export OSH="$HOME/.oh-my-bash"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-bash is loaded.
OSH_THEME="axin"

# Auto update settings
export UPDATE_OSH_DAYS=30
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="dd.mm.yyyy"

# Would you like to use another custom folder than $OSH/custom?
OSH_CUSTOM="$HOME/.custom"

# Enabled completions
completions=(docker docker-compose git makefile pip ssh)

# Enabled aliases
aliases=(general)

# Enabled plugins
plugins=(git)

# GPG configuration
if GPG_TTY=$(tty 2>/dev/null); then
    export GPG_TTY # Required for GPG signing in git
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
else
    unset GPG_TTY
fi

# Add user bin directories to PATH
for bin_dir in "$HOME/bin" "$HOME/.local/bin"; do
    if [[ -d "$bin_dir" ]] && [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        PATH="$bin_dir:$PATH"
    fi
done
unset bin_dir

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# Load environment exports early (locale, ripgrep, fzf) before oh-my-bash loads
if [[ -r "$HOME/.config/bash/.bash_exports" ]]; then
    source "$HOME/.config/bash/.bash_exports"
fi

# Source oh-my-bash
if [[ -f "$OSH/oh-my-bash.sh" ]]; then
    source "$OSH/oh-my-bash.sh"
fi

# Load user Bash configuration modules (aliases and functions override OMB defaults)
for file in "$HOME/.config/bash/.bash_aliases" "$HOME/.config/bash/.bash_functions"; do
    if [[ -r "$file" ]]; then
        source "$file"
    fi
done
unset file

# UV shell completion
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi
if command -v uvx >/dev/null 2>&1; then
    eval "$(uvx --generate-shell-completion bash)"
fi

# Optional CUDA & FFmpeg paths
if [[ -d /usr/local/cuda/bin ]] && [[ ":$PATH:" != *":/usr/local/cuda/bin:"* ]]; then
    export PATH="/usr/local/cuda/bin:$PATH"
fi
if [[ -d /usr/local/cuda/lib64 ]]; then
    export LD_LIBRARY_PATH="/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
if [[ -d /usr/local/ffmpeg-8.1/bin ]] && [[ ":$PATH:" != *":/usr/local/ffmpeg-8.1/bin:"* ]]; then
    export PATH="/usr/local/ffmpeg-8.1/bin:$PATH"
fi

# FZF keybindings and completion
if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi
if [[ -f /usr/share/bash-completion/completions/fzf ]]; then
    source /usr/share/bash-completion/completions/fzf
fi

# Mamba initialize (portable across usernames)
export MAMBA_ROOT_PREFIX="$HOME/miniforge3"
export MAMBA_EXE="$MAMBA_ROOT_PREFIX/bin/mamba"
if [[ -x "$MAMBA_EXE" ]]; then
    if __mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"; then
        eval "$__mamba_setup"
    else
        # shellcheck disable=SC2139
        alias mamba="$MAMBA_EXE"
    fi
    unset __mamba_setup
fi

# Local machine-specific overrides (not tracked in git)
if [[ -r "$HOME/.config/bash/.bashrc.local" ]]; then
    source "$HOME/.config/bash/.bashrc.local"
fi
