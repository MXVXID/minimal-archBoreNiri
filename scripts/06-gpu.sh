#!/usr/bin/env bash

set -euo pipefail

echo
echo "=============================================="
echo "              GPU DRIVERS"
echo "=============================================="
echo

COMMON="mesa vulkan-icd-loader"

echo "Choose GPU driver set:"
echo
echo "  1) AMD"
echo "  2) Intel"
echo "  3) NVIDIA (open kernel modules)"
echo "  4) AMD + Intel (all open)"
echo "  5) Skip"
echo

while true; do
    read -rp "Select [1-5]: " choice

    case "$choice" in
        1)
            EXTRA="vulkan-radeon libva-mesa-driver"
            break
            ;;
        2)
            EXTRA="vulkan-intel libva-mesa-driver"
            break
            ;;
        3)
            EXTRA="nvidia-open-dkms nvidia-utils"
            break
            ;;
        4)
            EXTRA="vulkan-radeon vulkan-intel libva-mesa-driver"
            break
            ;;
        5)
            echo
            echo "==> Skipping GPU drivers"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, 3, 4, or 5."
            ;;
    esac
done

echo
echo "==> Installing: $COMMON $EXTRA"

sudo pacman -S --needed $COMMON $EXTRA

echo
echo "==> GPU drivers ready"
