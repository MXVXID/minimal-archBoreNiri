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
echo "==> Enabling greetd + accounts-daemon"

sudo systemctl enable greetd.service
sudo systemctl enable accounts-daemon.service

echo
echo "==> Verifying Niri"

command -v niri
niri --version

echo
echo "==> Installing AUR packages (kanata, Nerd Fonts, Qt theming, greeter)"

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
        qt6ct-kde \
        noctalia-greeter

    echo
    echo "==> Verifying kanata"

    kanata --version
else
    echo
    echo "WARNING: No AUR helper found (paru/yay), skipping kanata-bin, ttf-nerd-fonts-meta, qt6ct-kde and noctalia-greeter."
    echo "         Run manually: paru -S kanata-bin ttf-nerd-fonts-meta qt6ct-kde noctalia-greeter"
fi

echo
echo "==> Configuring greetd + Noctalia Greeter"

GREETER_SESSION="$(command -v noctalia-greeter-session || true)"

if [[ -n "$GREETER_SESSION" ]]; then
    sudo mkdir -p /etc/greetd /var/lib/noctalia-greeter

    sudo tee /etc/greetd/config.toml >/dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "$GREETER_SESSION -- --session niri"
user = "greeter"
EOF

    sudo tee /var/lib/noctalia-greeter/greeter.toml >/dev/null <<'EOF'
[session]
default = "niri"
EOF

    sudo chown -R greeter:greeter /var/lib/noctalia-greeter 2>/dev/null || true

    echo "==> greetd configured (default session: niri)"
else
    echo "WARNING: noctalia-greeter not found, skipping greetd config."
    echo "         Edit /etc/greetd/config.toml manually after installing it."
fi

echo
echo "==> Desktop packages ready"
