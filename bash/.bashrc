# Path to your oh-my-bash installation.
export OSH=$HOME/.oh-my-bash

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
OSH_CUSTOM=$HOME/.custom

# Enabled completions
completions=(docker docker-compose git makefile pip ssh)

# Enabled aliases
aliases=(general)

# Enabled plugins
plugins=(git)

# SSH configuration
export SSH_KEY_PATH="$HOME/.ssh/"

# GPG configuration
export GPG_KEY_PATH="$HOME/.gpg/"
export GPG_TTY=$(tty)  # Required for GPG signing in git

# Source oh-my-bash
if [[ -f $OSH/oh-my-bash.sh ]]; then
    source $OSH/oh-my-bash.sh
fi

# Add user bin directories to PATH
for bin_dir in "$HOME/bin" "$HOME/.local/bin"; do
    if [[ -d "$bin_dir" ]] && [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        PATH="$bin_dir:$PATH"
    fi
done

# Load user Bash configuration modules
for file in "$HOME/.config/bash/.bash_aliases" "$HOME/.config/bash/.bash_functions" "$HOME/.config/bash/.bash_exports"; do
    if [[ -r "$file" ]]; then
        source "$file"
    fi
done

# UV shell completion
if command -v uv >/dev/null 2>&1; then
    eval "$(uv generate-shell-completion bash)"
fi
if command -v uvx >/dev/null 2>&1; then
    eval "$(uvx --generate-shell-completion bash)"
fi

export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export PATH="$HOME/.local/bin:$PATH"

# FFmpeg
export PATH=/usr/local/ffmpeg-8.1/bin:$PATH

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='~/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='~/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
