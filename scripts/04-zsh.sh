#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing Zsh"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/zsh.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}" git

PLUGIN_DIR="$HOME/.local/share/zsh/plugins"

mkdir -p "$PLUGIN_DIR"

clone_plugin() {
    local repo="$1"
    local destination="$2"

    if [[ -d "$destination/.git" ]]; then
        echo "==> Updating $(basename "$destination")"

        git -C "$destination" pull --ff-only
    else
        echo "==> Cloning $(basename "$destination")"

        rm -rf "$destination"

        git clone \
            --depth=1 \
            "$repo" \
            "$destination"
    fi
}

clone_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$PLUGIN_DIR/zsh-autosuggestions"

clone_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$PLUGIN_DIR/zsh-syntax-highlighting"

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

echo "==> Zsh ready"
