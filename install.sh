#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Do not run this installer as root."
    echo "Run it as your normal user."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is required."
    exit 1
fi

echo
echo "=============================================="
echo "             MXVX ARCH BOOTSTRAP"
echo "=============================================="
echo
echo "User : $USER"
echo "Root : $ROOT_DIR"
echo

read -rp "Continue installation? [y/N] " answer

if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

run_script() {
    local script="$1"

    echo
    echo "=============================================="
    echo " RUNNING: $script"
    echo "=============================================="

    bash "$ROOT_DIR/$script"
}

run_script "scripts/01-system.sh"
run_script "scripts/02-cachyos.sh"
run_script "scripts/03-aur.sh"
run_script "scripts/04-zsh.sh"
run_script "scripts/05-desktop.sh"
run_script "scripts/06-gpu.sh"
run_script "scripts/07-noctalia.sh"
run_script "scripts/08-lazyvim.sh"
run_script "scripts/09-dotfiles.sh"
run_script "scripts/10-bootloader.sh"

echo
echo "=============================================="
echo "             INSTALL COMPLETE"
echo "=============================================="
echo

echo "Installed kernel:"
pacman -Q linux-cachyos-bore 2>/dev/null || true

echo
echo "Installed desktop:"
command -v niri 2>/dev/null || true
command -v noctalia 2>/dev/null || true

echo
echo "Installed keyboard remapper:"
command -v kanata 2>/dev/null || true

echo
echo "Installed shell:"
command -v zsh 2>/dev/null || true

echo
echo "Installed editor:"
command -v nvim 2>/dev/null || true

echo

read -rp "Reboot now? [y/N] " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
