#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo
echo "=============================================="
echo "         DEV TOOLCHAIN (OPTIONAL)"
echo "=============================================="

echo
echo "==> Installing packages (cmake, Python, Node, Go, Rust, nvm)"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/dev.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}"

echo
echo "==> Installing opencode (latest)"

if command -v opencode >/dev/null 2>&1; then
    echo "==> Updating opencode"
    opencode upgrade
else
    curl -fsSL https://opencode.ai/install | bash
fi

echo
echo "==> Setting Rust stable toolchain"

if command -v rustup >/dev/null 2>&1; then
    rustup default stable
fi

echo
echo "==> Verifying toolchain"

for tool in cmake python3 node go gopls cargo rustc opencode; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  %-8s %s\n" "$tool" "$("$tool" --version 2>/dev/null | head -n 1)"
    else
        printf "  %-8s not found\n" "$tool"
    fi
done

echo
echo "==> NVM is ready via /usr/share/nvm/init-nvm.sh (already sourced in .zshrc)"
echo "==> Node packages run through pnpm (PNPM_HOME already set in .zshrc)"

echo
echo "=============================================="
echo "          DEV TOOLCHAIN READY"
echo "=============================================="