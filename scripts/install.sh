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
  # Try GitLab first, fallback to GitHub
  VERSION=$(curl -sSf "https://dev.purplemet.com/api/v4/projects/purplemet%2Fcli/releases" 2>/dev/null \
    | grep -o '"tag_name":"[^"]*"' | head -1 | cut -d'"' -f4) || true

  if [ -z "$VERSION" ]; then
    VERSION=$(curl -sSf "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
      | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4) || true
  fi

  if [ -z "$VERSION" ]; then
    echo "Error: could not determine latest version. Set VERSION env var manually." >&2
    exit 1
  fi
fi

EXT=""
[ "$OS" = "windows" ] && EXT=".exe"
FILENAME="${BINARY}-${OS}-${ARCH}${EXT}"

# Try GitLab release, fallback to GitHub
DOWNLOAD_URL="https://dev.purplemet.com/purplemet/cli/-/releases/${VERSION}/downloads/${FILENAME}"
echo "[*] Downloading ${BINARY} ${VERSION} (${OS}/${ARCH})..."
if ! curl -sSLf "$DOWNLOAD_URL" -o "/tmp/${FILENAME}" 2>/dev/null; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILENAME}"
  curl -sSLf "$DOWNLOAD_URL" -o "/tmp/${FILENAME}" || {
    echo "Error: download failed from both GitLab and GitHub" >&2
    exit 1
  }
fi

# Verify checksum if available
CHECKSUMS_URL="${DOWNLOAD_URL%/*}/checksums.txt"
if curl -sSLf "$CHECKSUMS_URL" -o "/tmp/checksums.txt" 2>/dev/null; then
  EXPECTED=$(grep "$FILENAME" /tmp/checksums.txt | awk '{print $1}')
  if [ -n "$EXPECTED" ]; then
    ACTUAL=$(shasum -a 256 "/tmp/${FILENAME}" | awk '{print $1}')
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

# Install
chmod +x "/tmp/${FILENAME}"
if [ -w "$INSTALL_DIR" ]; then
  mv "/tmp/${FILENAME}" "${INSTALL_DIR}/${BINARY}${EXT}"
else
  echo "[*] Installing to ${INSTALL_DIR} (requires sudo)..."
  sudo mv "/tmp/${FILENAME}" "${INSTALL_DIR}/${BINARY}${EXT}"
fi

echo "[*] Installed ${BINARY} ${VERSION}:"
"${INSTALL_DIR}/${BINARY}${EXT}" version
