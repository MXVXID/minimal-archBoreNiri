#!/usr/bin/env bash

set -euo pipefail

echo "==> Installing CachyOS repositories"

TMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TMP_DIR"' EXIT

cd "$TMP_DIR"

curl -fL \
    https://mirror.cachyos.org/cachyos-repo.tar.xz \
    -o cachyos-repo.tar.xz

tar -xf cachyos-repo.tar.xz

cd cachyos-repo

sudo ./cachyos-repo.sh

echo
echo "==> Refreshing package databases"

sudo pacman -Syu --needed

echo
echo "==> Installing CachyOS BORE kernel"

sudo pacman -S --needed \
    linux-cachyos-bore \
    linux-cachyos-bore-headers

echo
echo "==> Verifying CachyOS kernel package"

pacman -Q linux-cachyos-bore
