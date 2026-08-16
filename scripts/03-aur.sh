#!/usr/bin/env bash

set -euo pipefail

echo
echo "=============================================="
echo "              AUR HELPER SETUP"
echo "=============================================="
echo

# Auto-answer diff/edit/clean/upgrade prompts so AUR installs never ask.
# paru -> skip-review config; yay -> persisted answers in config.json.
configure_aur() {
    local helper="$1"

    echo "==> Configuring $helper to skip review/diff prompts"

    if [[ "$helper" == "paru" ]]; then
        mkdir -p "$HOME/.config/paru"
        tee "$HOME/.config/paru/paru.conf" >/dev/null <<'EOF'
[options]
BottomUp
SortBy=popularity
SkipReview
ClearAfter
RemoveMake
EOF
    elif [[ "$helper" == "yay" ]]; then
        "$helper" --save \
            --answerdiff N \
            --answerclean N \
            --answeredit N \
            --answerupgrade N \
            >/dev/null 2>&1 || true
    fi
}

if command -v paru >/dev/null 2>&1; then
    echo "==> paru already installed, skipping selection"
    paru --version
    configure_aur "paru"
    exit 0
elif command -v yay >/dev/null 2>&1; then
    echo "==> yay already installed, skipping selection"
    yay --version
    configure_aur "yay"
    exit 0
fi

echo "Choose AUR helper:"
echo
echo "  1) paru"
echo "  2) yay"
echo "  3) Skip"
echo

while true; do
    read -rp "Select [1-3]: " choice

    case "$choice" in
        1)
            HELPER="paru"
            break
            ;;
        2)
            HELPER="yay"
            break
            ;;
        3)
            HELPER="skip"
            break
            ;;
        *)
            echo "Invalid choice. Please select 1, 2, or 3."
            ;;
    esac
done

if [[ "$HELPER" == "skip" ]]; then
    echo
    echo "==> Skipping AUR helper"
    exit 0
fi

if command -v "$HELPER" >/dev/null 2>&1; then
    echo
    echo "==> $HELPER already installed"
    "$HELPER" --version
    exit 0
fi

echo
echo "==> Installing dependencies required to build $HELPER"

sudo pacman -S --needed \
    base-devel \
    git

BUILD_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$BUILD_DIR"
}

trap cleanup EXIT

cd "$BUILD_DIR"

if [[ "$HELPER" == "paru" ]]; then

    echo
    echo "==> Cloning paru"

    git clone \
        --depth=1 \
        https://aur.archlinux.org/paru.git

    cd paru

    echo
    echo "==> Building paru"

    makepkg -si --noconfirm

elif [[ "$HELPER" == "yay" ]]; then

    echo
    echo "==> Cloning yay"

    git clone \
        --depth=1 \
        https://aur.archlinux.org/yay.git

    cd yay

    echo
    echo "==> Building yay"

    makepkg -si --noconfirm
fi

echo
echo "==> Verifying AUR helper"

if ! command -v "$HELPER" >/dev/null 2>&1; then
    echo
    echo "ERROR: $HELPER installation failed."
    exit 1
fi

"$HELPER" --version

configure_aur "$HELPER"

echo
echo "==> AUR helper setup complete"
