#!/bin/sh
# Purplemet CLI installer
# Usage: curl -sSL https://raw.githubusercontent.com/purplemet/cli/main/scripts/install.sh | sh
set -e

REPO="purplemet/cli"
BINARY="purplemet-cli"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64)  ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) echo "Error: unsupported architecture $ARCH" >&2; exit 1 ;;
esac

case "$OS" in
  linux|darwin) ;;
  mingw*|msys*|cygwin*) OS=windows ;;
  *) echo "Error: unsupported OS $OS" >&2; exit 1 ;;
esac

# Determine version
if [ -z "$VERSION" ]; then
  echo "[*] Fetching latest version..."
  VERSION=$(curl -sSf "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
    | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4) || true

  if [ -z "$VERSION" ]; then
    echo "Error: could not determine latest version. Set VERSION env var manually." >&2
    exit 1
  fi
fi

EXT=""
[ "$OS" = "windows" ] && EXT=".exe"
FILENAME="${BINARY}-${OS}-${ARCH}${EXT}"

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILENAME}"
echo "[*] Downloading ${BINARY} ${VERSION} (${OS}/${ARCH})..."
curl -sSLf "$DOWNLOAD_URL" -o "/tmp/${FILENAME}" || {
  echo "Error: download failed from ${DOWNLOAD_URL}" >&2
  exit 1
}

# Verify checksum if available
CHECKSUMS_URL="${DOWNLOAD_URL%/*}/checksums.txt"
if curl -sSLf "$CHECKSUMS_URL" -o "/tmp/checksums.txt" 2>/dev/null; then
  EXPECTED=$(grep "$FILENAME" /tmp/checksums.txt | awk '{print $1}')
  if [ -n "$EXPECTED" ]; then
    if command -v sha256sum > /dev/null 2>&1; then
      ACTUAL=$(sha256sum "/tmp/${FILENAME}" | awk '{print $1}')
    else
      ACTUAL=$(shasum -a 256 "/tmp/${FILENAME}" | awk '{print $1}')
    fi
    if [ "$EXPECTED" != "$ACTUAL" ]; then
      echo "Error: checksum mismatch" >&2
      echo "  Expected: $EXPECTED" >&2
      echo "  Got:      $ACTUAL" >&2
      rm -f "/tmp/${FILENAME}" "/tmp/checksums.txt"
      exit 1
    fi
    echo "[*] Checksum verified."
  fi
  rm -f /tmp/checksums.txt
fi

# Install — precedence: writable INSTALL_DIR > sudo > user-local fallback.
# The fallback (~/.local/bin, XDG spec) lets CI runners without sudo install
# without requiring env overrides, so the doc's one-liner works everywhere.
chmod +x "/tmp/${FILENAME}"
INSTALLED_TO=""
if [ -w "$INSTALL_DIR" ]; then
  mv "/tmp/${FILENAME}" "${INSTALL_DIR}/${BINARY}${EXT}"
  INSTALLED_TO="${INSTALL_DIR}"
elif command -v sudo > /dev/null 2>&1; then
  echo "[*] Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "/tmp/${FILENAME}" "${INSTALL_DIR}/${BINARY}${EXT}"
  INSTALLED_TO="${INSTALL_DIR}"
else
  FALLBACK_DIR="${HOME}/.local/bin"
  echo "[*] ${INSTALL_DIR} not writable and sudo unavailable; falling back to ${FALLBACK_DIR}"
  mkdir -p "${FALLBACK_DIR}"
  mv "/tmp/${FILENAME}" "${FALLBACK_DIR}/${BINARY}${EXT}"
  INSTALLED_TO="${FALLBACK_DIR}"
  case ":${PATH}:" in
    *":${FALLBACK_DIR}:"*) ;;
    *)
      echo "[!] ${FALLBACK_DIR} is not on PATH. Add it with:"
      echo "    export PATH=\"${FALLBACK_DIR}:\$PATH\""
      ;;
  esac
fi

echo "[*] Installed ${BINARY} ${VERSION}:"
"${INSTALLED_TO}/${BINARY}${EXT}" version

# Install shell completions for the user's current shell, when possible.
# Skipped on Windows, in CI (interactive feature), and when the shell is unknown —
# completions are best-effort and never block a successful binary install.
INSTALLED_BIN="${INSTALLED_TO}/${BINARY}${EXT}"
SHELL_NAME=""
case "${SHELL:-}" in
  */bash) SHELL_NAME=bash ;;
  */zsh)  SHELL_NAME=zsh ;;
  */fish) SHELL_NAME=fish ;;
esac

if [ -n "${CI:-}" ] || [ "$OS" = "windows" ] || [ -z "$SHELL_NAME" ]; then
  exit 0
fi

# System-wide zsh fpath dir per platform — already in zsh's default $fpath, so
# completions auto-load without any ~/.zshrc edit. Empty if no good system path.
ZSH_SYS_DIR=""
case "${OS}-${ARCH}" in
  darwin-arm64) ZSH_SYS_DIR="/opt/homebrew/share/zsh/site-functions" ;;
  darwin-amd64) ZSH_SYS_DIR="/usr/local/share/zsh/site-functions" ;;
  linux-*)      ZSH_SYS_DIR="/usr/share/zsh/site-functions" ;;
esac

case "$SHELL_NAME" in
  fish)
    # fish autoloads from this XDG-spec dir — works immediately, no rc edit needed.
    COMP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish/completions"
    mkdir -p "$COMP_DIR"
    if "$INSTALLED_BIN" completion fish > "${COMP_DIR}/${BINARY}.fish" 2>/dev/null; then
      echo "[*] Fish completions installed in ${COMP_DIR}"
    fi
    ;;
  bash)
    # Standard XDG path picked up by bash-completion v2 (no rc edit needed when
    # bash-completion is sourced — which it is on most modern distros / brew).
    COMP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
    mkdir -p "$COMP_DIR"
    if "$INSTALLED_BIN" completion bash > "${COMP_DIR}/${BINARY}" 2>/dev/null; then
      echo "[*] Bash completions installed in ${COMP_DIR}"
      echo "    (requires bash-completion v2 — sourced by default on most distros)"
    fi
    ;;
  zsh)
    # Prefer the system fpath dir (zero config — auto-loaded by zsh's default fpath).
    # Try direct write, then sudo if available without prompt (the binary install
    # above just used sudo, so credentials are typically still cached).
    # Fall back to ~/.zsh/completions which requires a one-time ~/.zshrc edit.
    WROTE_SYSTEM=0
    if [ -n "$ZSH_SYS_DIR" ] && [ -d "$ZSH_SYS_DIR" ]; then
      COMP_FILE="${ZSH_SYS_DIR}/_${BINARY}"
      if [ -w "$ZSH_SYS_DIR" ]; then
        if "$INSTALLED_BIN" completion zsh > "$COMP_FILE" 2>/dev/null; then
          echo "[*] Zsh completions installed in ${ZSH_SYS_DIR} (auto-loaded)"
          WROTE_SYSTEM=1
        fi
      elif command -v sudo > /dev/null 2>&1 && sudo -n true 2>/dev/null; then
        if "$INSTALLED_BIN" completion zsh 2>/dev/null | sudo -n tee "$COMP_FILE" > /dev/null 2>&1; then
          echo "[*] Zsh completions installed in ${ZSH_SYS_DIR} (auto-loaded)"
          WROTE_SYSTEM=1
        fi
      fi
    fi

    if [ "$WROTE_SYSTEM" = 0 ]; then
      COMP_DIR="${HOME}/.zsh/completions"
      mkdir -p "$COMP_DIR"
      if "$INSTALLED_BIN" completion zsh > "${COMP_DIR}/_${BINARY}" 2>/dev/null; then
        echo "[*] Zsh completions installed in ${COMP_DIR}"
        case ":${fpath:-}:" in
          *":${COMP_DIR}:"*) ;;
          *)
            echo "    If completions don't work, add to ~/.zshrc:"
            echo "      fpath=(${COMP_DIR} \$fpath)"
            echo "      autoload -U compinit && compinit"
            ;;
        esac
      fi
    fi
    ;;
esac
