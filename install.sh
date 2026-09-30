#!/usr/bin/env bash
# Re-run after moving the clone to update the absolute launcher symlink.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
WITH_BUN_INSTALL=0

for arg in "$@"; do
  case "$arg" in
    --with-bun-install|-B) WITH_BUN_INSTALL=1 ;;
    -h|--help)
      echo "Usage: install.sh [target_bin_dir] [--with-bun-install|-B]"
      exit 0 ;;
    -*) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

if [[ "$WITH_BUN_INSTALL" -eq 1 ]]; then
  command -v bun >/dev/null 2>&1 || { echo "Install Bun first: https://bun.sh" >&2; exit 1; }
  (cd "$REPO_DIR" && bun install --frozen-lockfile)
fi

mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/video-description"
ln -sfn "$REPO_DIR/video-description" "$TARGET_DIR/video-description"
echo "Installed $TARGET_DIR/video-description -> $REPO_DIR/video-description"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add to ~/.zshrc or ~/.bashrc: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
esac
echo "Set OPENROUTER_API_KEY in $REPO_DIR/.env before running video-description."
