# shellcheck shell=bash disable=SC1090,SC1091
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.
# See /usr/share/doc/bash/examples/startup-files for examples.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# Add user local binaries to PATH
for bin_dir in "$HOME/bin" "$HOME/.local/bin"; do
    if [ -d "$bin_dir" ]; then
        case ":$PATH:" in
            *":$bin_dir:"*) ;;
            *) PATH="$bin_dir:$PATH" ;;
        esac
    fi
done
unset bin_dir

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
if [ -f "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi

# Source .bashrc if running bash
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi
