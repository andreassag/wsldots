# shellcheck shell=bash disable=SC1090,SC1091
if [[ -f "$HOME/.profile" ]]; then
    source "$HOME/.profile"
elif [[ -f "$HOME/.bashrc" ]]; then
    source "$HOME/.bashrc"
fi
