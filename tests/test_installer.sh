#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=$(cd -P -- "$(dirname -- "$0")/.." && pwd -P)
PASSED=0
FAILED=0

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-assertion failed}"
    if [ "$expected" != "$actual" ]; then
        echo "FAIL: $msg: expected '$expected', got '$actual'"
        FAILED=$((FAILED + 1))
        return 1
    else
        echo "PASS: $msg"
        PASSED=$((PASSED + 1))
        return 0
    fi
}

assert_true() {
    local condition="$1"
    local msg="${2:-assertion failed}"
    if eval "$condition"; then
        echo "PASS: $msg"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo "FAIL: $msg"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Test 1: Shell syntax on all scripts
echo "--- Test Suite 1: Shell Syntax Checks ---"
for f in "$REPO_DIR"/setup "$REPO_DIR"/scripts/install.sh "$REPO_DIR"/.profile "$REPO_DIR"/bash/.bash* "$REPO_DIR"/bash/.inputrc; do
    if [ -f "$f" ]; then
        assert_true "bash -n '$f'" "Syntax check (bash) for $(basename "$f")"
    fi
done
if command -v dash >/dev/null 2>&1; then
    assert_true "dash -n '$REPO_DIR/.profile'" "Syntax check (dash) for .profile"
fi

# Test 2: Git config format
echo "--- Test Suite 2: Git Configuration Integrity ---"
assert_true "git config --file '$REPO_DIR/git/.gitconfig' --list >/dev/null 2>&1" "git/.gitconfig parses cleanly"
assert_eq "" "$(git config --file "$REPO_DIR/git/.gitconfig" --get default.protocol 2>/dev/null || true)" "default.protocol is removed"
assert_eq "" "$(git config --file "$REPO_DIR/git/.gitconfig" --get credential.helper 2>/dev/null || true)" "hardcoded credential.helper is removed"
assert_eq "~/.gitconfig.local" "$(git config --file "$REPO_DIR/git/.gitconfig" --get include.path 2>/dev/null || true)" "include.path points to ~/.gitconfig.local"

# Test 3: GPG Agent config
echo "--- Test Suite 3: GPG Agent Configuration ---"
assert_true "! grep -q 'enable-ssh-support' '$REPO_DIR/gpg/gpg-agent.conf'" "gpg-agent.conf does not contain enable-ssh-support"
assert_true "! grep -q 'default-cache-ttl-ssh' '$REPO_DIR/gpg/gpg-agent.conf'" "gpg-agent.conf does not contain ssh ttl"
assert_eq "/usr/bin/pinentry-curses" "$(grep '^pinentry-program' "$REPO_DIR/gpg/gpg-agent.conf" | awk '{print $2}')" "Default pinentry is pinentry-curses"

# Test 4: Wget config
echo "--- Test Suite 4: Wget Configuration ---"
for bad_opt in "wait = 5" "prefer-family = IPv6" "server_response = on" "adjust_extension = on"; do
    assert_true "! grep -q '$bad_opt' '$REPO_DIR/wget/.wgetrc'" "wgetrc does not contain '$bad_opt'"
done

# Test 5: Gitignore
echo "--- Test Suite 5: Repository Gitignore & Hygiene ---"
assert_true "grep -q '^\.nvimlog$' '$REPO_DIR/.gitignore'" ".gitignore ignores .nvimlog"
assert_true "[ ! -f '$REPO_DIR/.nvimlog' ]" ".nvimlog does not exist in repo root"

# Test 6: Environment & Profile Order
echo "--- Test Suite 6: Profile & Bashrc Execution Order ---"
# .profile: PATH must come before .bashrc
path_line=$(grep -n 'for bin_dir in "\$HOME/bin"' "$REPO_DIR/.profile" | cut -d: -f1)
bashrc_line=$(grep -n '\. "\$HOME/\.bashrc"' "$REPO_DIR/.profile" | cut -d: -f1)
assert_true "[ -n '$path_line' ] && [ -n '$bashrc_line' ] && [ '$path_line' -lt '$bashrc_line' ]" ".profile sets PATH before sourcing .bashrc"

# bash/.bashrc: exports must be sourced before oh-my-bash
exports_line=$(grep -n 'source "\$HOME/\.config/bash/\.bash_exports"' "$REPO_DIR/bash/.bashrc" | cut -d: -f1)
omb_line=$(grep -n 'source "\$OSH/oh-my-bash\.sh"' "$REPO_DIR/bash/.bashrc" | cut -d: -f1)
aliases_line=$(grep -n '"\$HOME/\.config/bash/\.bash_aliases"' "$REPO_DIR/bash/.bashrc" | cut -d: -f1)
assert_true "[ -n '$exports_line' ] && [ -n '$omb_line' ] && [ '$exports_line' -lt '$omb_line' ]" ".bashrc sources .bash_exports before oh-my-bash"
assert_true "[ -n '$aliases_line' ] && [ -n '$omb_line' ] && [ '$omb_line' -lt '$aliases_line' ]" ".bashrc sources .bash_aliases after oh-my-bash"
assert_true "! grep -q 'SSH_KEY_PATH' '$REPO_DIR/bash/.bashrc'" ".bashrc removes dead SSH_KEY_PATH"
assert_true "! grep -q 'GPG_KEY_PATH' '$REPO_DIR/bash/.bashrc'" ".bashrc removes dead GPG_KEY_PATH"
assert_true "grep -q 'gpg-connect-agent updatestartuptty' '$REPO_DIR/bash/.bashrc'" ".bashrc runs gpg-connect-agent updatestartuptty"
assert_true "! grep -q 'DISPLAY=' '$REPO_DIR/bash/.bash_exports'" ".bash_exports removes obsolete DISPLAY export"

# Test 7: Simulated Installer Execution
echo "--- Test Suite 7: Full Installer Functional Simulation ---"
TEST_TMP=$(mktemp -d /tmp/wsldots-test-XXXXXX)
trap 'rm -rf "$TEST_TMP"' EXIT

MOCK_HOME="$TEST_TMP/home"
MOCK_WIN="$TEST_TMP/win"
mkdir -p "$MOCK_HOME" "$MOCK_WIN/.ssh" "$MOCK_WIN/.gpg"
mkdir -p "$MOCK_HOME/.oh-my-bash" "$MOCK_HOME/.local/bin"
touch "$MOCK_HOME/.local/bin/uv"
chmod +x "$MOCK_HOME/.local/bin/uv"

# Create mock Windows SSH keys
touch "$MOCK_WIN/.ssh/known_hosts" "$MOCK_WIN/.ssh/config"
echo "ssh-ed25519 AAAAC3... win_key" > "$MOCK_WIN/.ssh/id_ed25519.pub"
echo "-----BEGIN OPENSSH PRIVATE KEY-----" > "$MOCK_WIN/.ssh/id_ed25519"

# Create mock Windows GPG pinentry
mkdir -p "$MOCK_WIN/Program Files (x86)/Gpg4win/bin"
cat > "$MOCK_WIN/Program Files (x86)/Gpg4win/bin/pinentry.exe" <<'EOF'
#!/bin/sh
echo "OK Pleased to meet you"
EOF
chmod +x "$MOCK_WIN/Program Files (x86)/Gpg4win/bin/pinentry.exe"

# Create mock Windows GCM executable script
mkdir -p "$MOCK_WIN/Program Files/Git/mingw64/bin"
cat > "$MOCK_WIN/Program Files/Git/mingw64/bin/git-credential-manager.exe" <<'EOF'
#!/bin/sh
echo "username=testuser"
echo "password=testpass"
EOF
chmod +x "$MOCK_WIN/Program Files/Git/mingw64/bin/git-credential-manager.exe"

# Create mock script that overrides WINDOWS_PATH and WIN_DRIVE for installer
cat > "$TEST_TMP/run_mock_setup.sh" <<EOF
#!/usr/bin/env bash
export HOME="$MOCK_HOME"
export WINDOWS_PATH="$MOCK_WIN"
export WIN_DRIVE="$MOCK_WIN"
# Run non-interactively
"$REPO_DIR/scripts/install.sh" < /dev/null
EOF
chmod +x "$TEST_TMP/run_mock_setup.sh"

"$TEST_TMP/run_mock_setup.sh" >/dev/null 2>&1 || true

# Assert SSH keys were copied with correct permissions
assert_true "[ -f '$MOCK_HOME/.ssh/id_ed25519' ]" "SSH private key copied"
assert_eq "600" "$(stat -c '%a' "$MOCK_HOME/.ssh/id_ed25519")" "SSH private key has 600 permissions"
assert_true "[ -f '$MOCK_HOME/.ssh/id_ed25519.pub' ]" "SSH public key copied"
assert_eq "644" "$(stat -c '%a' "$MOCK_HOME/.ssh/id_ed25519.pub")" "SSH public key has 644 permissions"
assert_eq "600" "$(stat -c '%a' "$MOCK_HOME/.ssh/known_hosts")" "SSH known_hosts has 600 permissions"
assert_eq "600" "$(stat -c '%a' "$MOCK_HOME/.ssh/config")" "SSH config has 600 permissions"
assert_true "[ ! -L '$MOCK_HOME/.ssh/known_hosts' ]" "SSH known_hosts is a regular file, not a symlink"

# Assert pinentry wrapper was created
assert_true "[ -f '$MOCK_HOME/.gnupg/pinentry-wsl' ]" "Pinentry wrapper script created"
assert_eq "700" "$(stat -c '%a' "$MOCK_HOME/.gnupg/pinentry-wsl")" "Pinentry wrapper has 700 permissions"
assert_true "grep -q 'pinentry-program $MOCK_HOME/.gnupg/pinentry-wsl' '$MOCK_HOME/.gnupg/gpg-agent.conf'" "gpg-agent.conf points to pinentry wrapper"

# Verify pinentry-wsl runs Windows pinentry when present
pin_out=$("$MOCK_HOME/.gnupg/pinentry-wsl" </dev/null 2>&1 || true)
assert_true "echo '$pin_out' | grep -q 'OK Pleased to meet you'" "Pinentry wrapper executes Windows pinentry when present"

# Assert GCM credential helper was configured with escaped spaces
escaped_expected="${MOCK_WIN}/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe"
assert_eq "$escaped_expected" "$(git config --file "$MOCK_HOME/.gitconfig.local" credential.helper)" "GCM path with escaped space configured in .gitconfig.local"

# Deep verification: actually run git credential fill to ensure Git executes GCM path with spaces
cred_out=$(printf "protocol=https\nhost=github.com\n\n" | HOME="$MOCK_HOME" GIT_CONFIG_GLOBAL="$MOCK_HOME/.gitconfig" GIT_TERMINAL_PROMPT=0 git credential fill 2>/dev/null || true)
assert_true "echo '$cred_out' | grep -q 'username=testuser'" "Git credential fill successfully executes GCM path containing spaces"

# Assert idempotent re-run
"$TEST_TMP/run_mock_setup.sh" >/dev/null 2>&1 || true
assert_eq "$escaped_expected" "$(git config --file "$MOCK_HOME/.gitconfig.local" credential.helper)" "Idempotent re-run preserves credential helper"

echo "--- Test Suite 8: Fallback Behaviors (No GCM, No pinentry.exe) ---"
MOCK_HOME2="$TEST_TMP/home2"
mkdir -p "$MOCK_HOME2/.oh-my-bash" "$MOCK_HOME2/.local/bin"
touch "$MOCK_HOME2/.local/bin/uv"
chmod +x "$MOCK_HOME2/.local/bin/uv"

cat > "$TEST_TMP/run_mock_fallback.sh" <<EOF
#!/usr/bin/env bash
export HOME="$MOCK_HOME2"
export WINDOWS_PATH=""
export WIN_DRIVE=""
# Run non-interactively
"$REPO_DIR/scripts/install.sh" < /dev/null
EOF
chmod +x "$TEST_TMP/run_mock_fallback.sh"

"$TEST_TMP/run_mock_fallback.sh" >/dev/null 2>&1 || true

# Assert pinentry falls back to pinentry-curses link
assert_true "[ -L '$MOCK_HOME2/.gnupg/gpg-agent.conf' ]" "gpg-agent.conf is a symlink when pinentry.exe is absent"
assert_eq "$REPO_DIR/gpg/gpg-agent.conf" "$(readlink -f "$MOCK_HOME2/.gnupg/gpg-agent.conf")" "gpg-agent.conf symlinks to repo default"

# Assert credential helper falls back to gh auth git-credential
if command -v gh >/dev/null 2>&1; then
    assert_eq "!gh auth git-credential" "$(git config --file "$MOCK_HOME2/.gitconfig.local" credential.helper)" "Falls back to gh auth git-credential when GCM absent"
fi

# Assert missing key disables commit.gpgsign
assert_eq "false" "$(git config --file "$MOCK_HOME2/.gitconfig.local" commit.gpgsign)" "commit.gpgsign is set to false when signing key is missing"

# Assert symlinked SSH key is replaced by regular file
MOCK_HOME3="$TEST_TMP/home3"
MOCK_WIN3="$TEST_TMP/win3"
mkdir -p "$MOCK_HOME3/.ssh" "$MOCK_HOME3/.oh-my-bash" "$MOCK_HOME3/.local/bin" "$MOCK_WIN3/.ssh"
touch "$MOCK_HOME3/.local/bin/uv" && chmod +x "$MOCK_HOME3/.local/bin/uv"
echo "win-key-content" > "$MOCK_WIN3/.ssh/id_ed25519"
ln -s "$MOCK_WIN3/.ssh/id_ed25519" "$MOCK_HOME3/.ssh/id_ed25519"

cat > "$TEST_TMP/run_mock_symlink.sh" <<EOF
#!/usr/bin/env bash
export HOME="$MOCK_HOME3"
export WINDOWS_PATH="$MOCK_WIN3"
export WIN_DRIVE="$MOCK_WIN3"
"$REPO_DIR/scripts/install.sh" < /dev/null
EOF
chmod +x "$TEST_TMP/run_mock_symlink.sh"
"$TEST_TMP/run_mock_symlink.sh" >/dev/null 2>&1 || true

assert_true "[ -f '$MOCK_HOME3/.ssh/id_ed25519' ] && [ ! -L '$MOCK_HOME3/.ssh/id_ed25519' ]" "Existing SSH key symlink replaced with regular file copy"
assert_eq "600" "$(stat -c '%a' "$MOCK_HOME3/.ssh/id_ed25519")" "Replaced SSH key has 600 permissions"

# Assert missing gpg binary disables commit.gpgsign
MOCK_HOME4="$TEST_TMP/home4"
mkdir -p "$MOCK_HOME4/.oh-my-bash" "$MOCK_HOME4/.local/bin"
touch "$MOCK_HOME4/.local/bin/uv" && chmod +x "$MOCK_HOME4/.local/bin/uv"
# Run with a restricted PATH lacking gpg
cat > "$TEST_TMP/run_mock_nogpg.sh" <<EOF
#!/usr/bin/env bash
export HOME="$MOCK_HOME4"
export WINDOWS_PATH=""
export WIN_DRIVE=""
# Strip gpg from PATH by overriding PATH with a dir that has git, bash, coreutils but no gpg
RESTRICTED_BIN="$TEST_TMP/restricted_bin"
mkdir -p "\$RESTRICTED_BIN"
for cmd in bash sh git readlink dirname basename cp mv rm ln mkdir chmod stat grep sed awk touch printf cat true false cmp date; do
    cmd_path=\$(command -v "\$cmd" 2>/dev/null || true)
    [ -n "\$cmd_path" ] && ln -sf "\$cmd_path" "\$RESTRICTED_BIN/\$cmd"
done
export PATH="\$RESTRICTED_BIN"
"$REPO_DIR/scripts/install.sh" < /dev/null
EOF
chmod +x "$TEST_TMP/run_mock_nogpg.sh"
"$TEST_TMP/run_mock_nogpg.sh" >/dev/null 2>&1 || true

assert_eq "false" "$(git config --file "$MOCK_HOME4/.gitconfig.local" commit.gpgsign)" "commit.gpgsign is set to false when gpg binary is not installed"

# Assert standard fd and bat links created when fdfind/batcat exist
if command -v fdfind >/dev/null 2>&1; then
    assert_true "[ -e '$MOCK_HOME/.local/bin/fd' ]" "Installer creates ~/.local/bin/fd for fdfind"
fi
if command -v batcat >/dev/null 2>&1; then
    assert_true "[ -e '$MOCK_HOME/.local/bin/bat' ]" "Installer creates ~/.local/bin/bat for batcat"
fi

echo "==============================="
echo "Results: $PASSED passed, $FAILED failed"
echo "==============================="
[ "$FAILED" -eq 0 ]
