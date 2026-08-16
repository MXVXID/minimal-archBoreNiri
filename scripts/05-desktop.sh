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

for dm in sddm gdm lightdm lxdm ly; do
    sudo systemctl disable --now "$dm.service" 2>/dev/null || true
done

sudo rm -f /etc/systemd/system/display-manager.service

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
    AUR_FLAGS=(--needed --noconfirm --removemake)

    if [[ "$AUR_HELPER" == "paru" ]]; then
        AUR_FLAGS+=(--skipreview)
    else
        AUR_FLAGS+=(--answerdiff N --answerclean N --answeredit N --answerupgrade N)
    fi

    "$AUR_HELPER" -S "${AUR_FLAGS[@]}" \
        kanata-bin \
        ttf-nerd-fonts-meta \
        qt6ct-kde \
        noctalia-greeter \
        mpv-mpris \
        cliamp

    echo
    echo "==> Verifying kanata"

    kanata --version
else
    echo
    echo "WARNING: No AUR helper found (paru/yay), skipping kanata-bin, ttf-nerd-fonts-meta, qt6ct-kde, noctalia-greeter, mpv-mpris and cliamp."
    echo "         Run manually: paru -S kanata-bin ttf-nerd-fonts-meta qt6ct-kde noctalia-greeter mpv-mpris cliamp"
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
