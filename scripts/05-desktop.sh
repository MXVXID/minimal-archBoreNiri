#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing desktop packages"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/desktop.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}"

echo
echo "==> Enabling NetworkManager"

sudo systemctl enable NetworkManager.service

echo
echo "==> Enabling SDDM"

sudo systemctl enable sddm.service

echo
echo "==> Verifying Niri"

command -v niri
niri --version

echo
echo "==> Installing AUR packages (kanata + all Nerd Fonts)"

AUR_HELPER=""

for candidate in paru yay; do
    if command -v "$candidate" >/dev/null 2>&1; then
        AUR_HELPER="$candidate"
        break
    fi
done

if [[ -n "$AUR_HELPER" ]]; then
    "$AUR_HELPER" -S --needed \
        kanata-bin \
        ttf-nerd-fonts-meta \
        qt6ct-kde

    echo
    echo "==> Verifying kanata"

    kanata --version
else
    echo
    echo "WARNING: No AUR helper found (paru/yay), skipping kanata-bin, ttf-nerd-fonts-meta and qt6ct-kde."
    echo "         Run manually: paru -S kanata-bin ttf-nerd-fonts-meta qt6ct-kde"
fi

echo
echo "==> Desktop packages ready"
