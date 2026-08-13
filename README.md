# MXVX Arch Setup

One-shot bootstrap for a minimal Arch Linux installation (Niri + Noctalia + greetd).

## Installs

- CachyOS repositories
- linux-cachyos-bore + headers
- Microcode (AMD + Intel)
- ntfs-3g + dosfstools (NTFS / FAT drives)
- GPU drivers (selectable: AMD / Intel / NVIDIA-open / All)
- Zsh + Oh My Zsh (agnoster theme) + autosuggestions + syntax-highlighting
- Fastfetch (custom config + logo)
- Niri
- Noctalia (app theming: GTK3/GTK4, KColorScheme, Qt, Kitty)
- greetd + Noctalia Greeter (login screen, synced with the desktop)
- Kitty
- Firefox
- adw-gtk-theme + nwg-look (GTK theming)
- JetBrains Mono Nerd Font + all Nerd Fonts (via ttf-nerd-fonts-meta)
- Noto fonts (complete Unicode + CJK + emoji)
- PipeWire + WirePlumber
- NetworkManager
- Kanata (AUR)
- qt6ct-kde (AUR, Qt theming)
- btop + cava (Noctalia templates)
- Neovim + LazyVim (starter + prerequisites)
- Dev toolchain **(optional)**: cmake + ninja, Python + pip, Node.js + npm + pnpm + nvm, Go + gopls, Rust (rustup), opencode (curl installer)

## Requirements

- Base Arch Linux installed (via archinstall — pick the **minimal** profile — or the manual installation guide)
- User with sudo
- Run from the terminal (TTY), not as root

## Dotfiles

<https://github.com/MXVXID/lx>

Linked by step 09:

- ~/.config/niri
- ~/.config/nvim (LazyVim, overlay from lx)
- ~/.config/kanata
- ~/.zshrc
- ~/.config/fastfetch (config + logo)
- ~/.config/kitty/kitty.conf

## Fresh install

```
git clone https://github.com/MXVXID/minimal-archBoreNiri ~/Arch-Niri
cd ~/Arch-Niri
chmod +x install.sh
```

## Run

```bash
./install.sh            # interactive wizard (choose steps, or run all)
./install.sh --auto     # run all steps without prompts
./install.sh --steps 1-3,5   # run only specific steps
./install.sh --steps 11      # install only the dev toolchain
```

The dev toolchain (step 11) is **optional** — the wizard asks for it and the default is
*no*. Use `--steps 11` (or `--steps 1-11`) to include it.

## After first login

- `qt6ct` → Appearance → Color scheme: `noctalia (KColorScheme)`
- Noctalia Settings → Templates → enable community templates → enable `pywalfox-beta4`
- Install the [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) extension in Firefox and restart it once
- Noctalia Settings → Security → Noctalia Greeter → **Sync Now** (copies wallpaper/palette/font to the login screen) — optional: enable Auto-Sync
- **Telegram**: after Noctalia Sync, re-run script 07 (applies theme to `~/.local/share/TelegramDesktop/tdata/colors.tdesktop-theme`), then restart Telegram

## Structure

```
install.sh          # main entrypoint, runs all scripts in order
packages/           # package lists (base, zsh, desktop)
scripts/            # numbered install steps
```

This repo contains **only the installer** — all configs (`.zshrc`, fastfetch, kitty, niri, nvim, kanata) live in [MXVXID/lx](https://github.com/MXVXID/lx).

| Script | Purpose |
| --- | --- |
| 01-system | Update + base packages |
| 02-cachyos | CachyOS repos + BORE kernel |
| 03-aur | AUR helper (paru / yay) |
| 04-zsh | Zsh + Oh My Zsh + shell setup |
| 05-desktop | Niri, Noctalia, greetd, fonts, btop/cava, AUR extras |
| 06-gpu | GPU drivers (interactive selection) |
| 07-noctalia | Noctalia theming templates |
| 08-lazyvim | Neovim + LazyVim prerequisites |
| 09-dotfiles | Link configs from MXVXID/lx + LazyVim |
| 10-bootloader | GRUB tuning (skips on systemd-boot) |
| 11-dev | Dev toolchain (optional — cmake, Python, Node, Go, Rust, nvm) |
