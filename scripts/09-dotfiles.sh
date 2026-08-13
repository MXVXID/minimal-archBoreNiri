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
link_config "kanata"

NVIM_DIR="$HOME/.config/nvim"

echo
echo "==> Installing LazyVim"

if command -v nvim >/dev/null 2>&1 && [[ -d "$DOTFILES_DIR/.config/nvim" ]]; then
    if [[ -e "$NVIM_DIR" && ! -L "$NVIM_DIR" ]]; then
        backup="$NVIM_DIR.backup.$(date +%Y%m%d%H%M%S)"

        echo "==> Existing $NVIM_DIR detected"
        echo "    Backup -> $backup"

        mv "$NVIM_DIR" "$backup"
    elif [[ -L "$NVIM_DIR" ]]; then
        echo "==> Removing old symlink"

        rm "$NVIM_DIR"
    fi

    echo "==> Cloning LazyVim starter"

    git clone \
        --depth=1 \
        "https://github.com/LazyVim/starter.git" \
        "$NVIM_DIR"

    echo
    echo "==> Removing starter .git"

    rm -rf "$NVIM_DIR/.git"

    echo
    echo "==> Overlaying dotfiles from MXVXID/lx"

    cp -a "$DOTFILES_DIR/.config/nvim/." "$NVIM_DIR/"

    rm -rf "$NVIM_DIR/.git"

    echo
    echo "==> Bootstrapping LazyVim (installs plugins, may take a while)"

    if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
        echo "==> LazyVim plugins installed"
    else
        echo "==> Warning: LazyVim bootstrap did not finish cleanly"
        echo "    Run 'nvim' once manually to complete the plugin install."
    fi
else
    echo "    Skipped (nvim or ~/.local/src/lx/.config/nvim not available)"
fi

echo
echo "=============================================="
echo "             DOTFILES READY"
echo "=============================================="
