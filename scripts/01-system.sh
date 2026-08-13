#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Updating Arch Linux"

sudo pacman -Syu --needed

echo "==> Installing base packages"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/base.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}"

echo "==> Base system ready"
