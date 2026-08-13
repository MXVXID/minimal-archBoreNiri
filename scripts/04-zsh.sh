#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing Zsh"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/zsh.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}" git

THEME_DIR="$HOME/.local/share/zsh/themes"

mkdir -p "$THEME_DIR"

echo
echo "==> Installing Powerlevel10k theme"

if [[ -d "$THEME_DIR/powerlevel10k/.git" ]]; then
    echo "==> Updating powerlevel10k"

    git -C "$THEME_DIR/powerlevel10k" pull --ff-only
else
    echo "==> Cloning powerlevel10k"

    rm -rf "$THEME_DIR/powerlevel10k"

    git clone \
        --depth=1 \
        "https://github.com/romkatv/powerlevel10k.git" \
        "$THEME_DIR/powerlevel10k"
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
echo "==> Run 'p10k configure' after login to customize the prompt"

echo "==> Zsh ready"
