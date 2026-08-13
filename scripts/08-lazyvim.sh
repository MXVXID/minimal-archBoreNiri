#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo
echo "=============================================="
echo "        NEOVIM + LAZYVIM DEPENDENCIES"
echo "=============================================="

echo
echo "==> Installing packages"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/lazyvim.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}"

echo
echo "==> Verifying Neovim"

nvim --version | head -n 1

echo
echo "==> Verifying Git"

git --version

echo
echo "==> Verifying Tree-sitter"

tree-sitter --version

echo
echo "==> Verifying compiler"

gcc --version | head -n 1

echo
echo "==> Verifying ripgrep"

rg --version | head -n 1

echo
echo "==> Verifying fd"

fd --version

echo
echo "==> Verifying fzf"

fzf --version

echo
echo "==> Verifying LazyGit"

lazygit --version

echo
echo "=============================================="
echo "      LAZYVIM DEPENDENCIES READY"
echo "=============================================="
