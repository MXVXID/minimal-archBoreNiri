#!/usr/bin/env bash

set -euo pipefail

echo "==> Detecting bootloader"

if [[ -f /etc/default/grub ]]; then

    echo "==> GRUB detected"

    set_or_append() {
        local key="$1"
        local value="$2"

        if sudo grep -q "^${key}=" /etc/default/grub; then
            sudo sed -i \
                "s|^${key}=.*|${key}=${value}|" \
                /etc/default/grub
        else
            echo "${key}=${value}" |
                sudo tee -a /etc/default/grub >/dev/null
        fi
    }

    set_or_append "GRUB_DEFAULT" "saved"
    set_or_append "GRUB_SAVEDEFAULT" "true"
    set_or_append "GRUB_DISABLE_OS_PROBER" "true"

    sudo grub-mkconfig \
        -o /boot/grub/grub.cfg

    echo "==> GRUB updated"

else

    echo
    echo "No /etc/default/grub found."
    echo "Assuming systemd-boot or another bootloader."
    echo "Skipping GRUB configuration."
    echo

fi
