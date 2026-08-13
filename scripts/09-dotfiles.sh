#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO="https://github.com/MXVXID/lx.git"
DOTFILES_DIR="$HOME/.local/src/lx"

echo
echo "=============================================="
echo "              DOTFILES SETUP"
echo "=============================================="

mkdir -p "$HOME/.local/src"

if [[ -d "$DOTFILES_DIR/.git" ]]; then

    echo
    echo "==> Updating MXVXID/lx"

    git -C "$DOTFILES_DIR" pull --ff-only

else

    echo
    echo "==> Cloning MXVXID/lx"

    git clone \
        "$DOTFILES_REPO" \
        "$DOTFILES_DIR"

fi

mkdir -p "$HOME/.config"

link_config() {
    local name="$1"
    local source="$DOTFILES_DIR/.config/$name"
    local target="$HOME/.config/$name"

    if [[ ! -e "$source" ]]; then
        echo
        echo "==> ~/.config/$name not found in lx"
        echo "    Skipping."
        return 0
    fi

    if [[ -e "$target" && ! -L "$target" ]]; then

        local backup
        backup="$target.backup.$(date +%Y%m%d%H%M%S)"

        echo
        echo "==> Existing $target detected"
        echo "    Backup -> $backup"

        mv "$target" "$backup"

    fi

    ln -sfn "$source" "$target"

    echo
    echo "==> Linked:"
    echo "    $target"
    echo "    -> $source"
}

link_config "niri"
link_config "nvim"
link_config "kanata"

echo
echo "=============================================="
echo "             DOTFILES READY"
echo "=============================================="
