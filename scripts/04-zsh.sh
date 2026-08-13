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

echo "==> Installing fastfetch config"

if [[ -e "$HOME/.config/fastfetch/config.jsonc" && ! -L "$HOME/.config/fastfetch/config.jsonc" ]]; then
    cp "$HOME/.config/fastfetch/config.jsonc" \
       "$HOME/.config/fastfetch/config.jsonc.backup.$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$HOME/.config/fastfetch"

ln -sfn \
    "$ROOT_DIR/fastfetch/config.jsonc" \
    "$HOME/.config/fastfetch/config.jsonc"

ln -sfn \
    "$ROOT_DIR/fastfetch/framework_white.png" \
    "$HOME/.config/fastfetch/framework_white.png"

echo "==> Installing .zshrc"

if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" \
       "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

ln -sfn \
    "$ROOT_DIR/zsh/.zshrc" \
    "$HOME/.zshrc"

ZSH="$(command -v zsh)"

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$ZSH" ]]; then
    echo "==> Setting Zsh as default shell"
    chsh -s "$ZSH"
fi

echo
echo "==> Theme: agnoster (Oh My Zsh) — needs a Nerd Font (installed later)"

echo "==> Zsh ready"
