# shellcheck shell=bash
# WSL helper functions
function wslpath_win() {
    local path="${1:-.}"
    if command -v wslpath >/dev/null 2>&1; then
        wslpath -w "$path"
    else
        echo "$path"
    fi
}

function openwin() {
    local target="${1:-.}"
    if command -v explorer.exe >/dev/null 2>&1; then
        explorer.exe "$(wslpath -w "$target")"
    elif command -v cmd.exe >/dev/null 2>&1; then
        cmd.exe /c start "" "$(wslpath -w "$target")"
    else
        command xdg-open "$target" >/dev/null 2>&1 || return 1
    fi
}

function clipboard_copy() {
    if command -v clip.exe >/dev/null 2>&1; then
        cat | clip.exe
    else
        echo "clip.exe unavailable" >&2
        return 1
    fi
}

function clipboard_paste() {
    if command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command "Get-Clipboard" | tr -d '\r'
    else
        echo "powershell.exe unavailable" >&2
        return 1
    fi
}
