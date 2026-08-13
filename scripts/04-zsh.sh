#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing Zsh"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/zsh.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}" git

OMZ_DIR="$HOME/.oh-my-zsh"

echo
echo "==> Installing Oh My Zsh"

if [[ -d "$OMZ_DIR/.git" ]]; then
    echo "==> Updating Oh My Zsh"

    git -C "$OMZ_DIR" pull --ff-only
else
    echo "==> Cloning Oh My Zsh"

    rm -rf "$OMZ_DIR"

    git clone \
        --depth=1 \
        "https://github.com/ohmyzsh/ohmyzsh.git" \
        "$OMZ_DIR"
fi

ZSH="$(command -v zsh)"

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$ZSH" ]]; then
    echo "==> Setting Zsh as default shell"
    chsh -s "$ZSH"
fi

echo
echo "==> Theme: agnoster (Oh My Zsh) — needs a Nerd Font (installed later)"
echo "    .zshrc is linked by step 9 (dotfiles)"

echo "==> Zsh ready"
