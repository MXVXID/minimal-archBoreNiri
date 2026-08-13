# MXVX Arch Setup

One-shot bootstrap for a minimal Arch Linux installation (Niri + Noctalia + SDDM).

## Installs

- CachyOS repositories
- linux-cachyos-bore + headers
- Microcode (AMD + Intel)
- GPU drivers (selectable: AMD / Intel / NVIDIA-open / All)
- Zsh + autosuggestions + syntax-highlighting
- Niri
- Noctalia (app theming: GTK3/GTK4, KColorScheme, Qt, Kitty)
- SDDM (login manager)
- Kitty
- Firefox
- adw-gtk-theme + nwg-look (GTK theming)
- JetBrains Mono Nerd Font + all Nerd Fonts (via ttf-nerd-fonts-meta)
- Noto fonts (complete Unicode + CJK + emoji)
- PipeWire + WirePlumber
- NetworkManager
- Kanata (AUR)
- qt6ct-kde (AUR, Qt theming)
- Neovim + LazyVim dependencies (tree-sitter, GCC, ripgrep, fd, fzf, LazyGit)

## Requirements

- Base Arch Linux installed (via archinstall — pick the **minimal** profile — or the manual installation guide)
- User with sudo
- Run from the terminal (TTY), not as root

## Dotfiles

<https://github.com/MXVXID/lx>

Linked:

- ~/.config/niri
- ~/.config/nvim
- ~/.config/kanata

## Fresh install

```
git clone https://github.com/MXVXID/minimal-archBoreNiri ~/Arch-Niri
cd ~/Arch-Niri
chmod +x install.sh
```

## Run

```bash
./install.sh
```

## After first login

- `qt6ct` → Appearance → Color scheme: `noctalia (KColorScheme)`
- Noctalia Settings → Templates → enable community templates → enable `pywalfox-beta4`
- Install the [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) extension in Firefox and restart it once

## Structure

```
install.sh          # main entrypoint, runs all scripts in order
packages/           # package lists (base, zsh, desktop)
scripts/            # numbered install steps
zsh/                # .zshrc
```

| Script | Purpose |
| --- | --- |
| 01-system | Update + base packages |
| 02-cachyos | CachyOS repos + BORE kernel |
| 03-aur | AUR helper (paru / yay) |
| 04-zsh | Zsh + plugins + shell setup |
| 05-desktop | Niri, Noctalia, SDDM, fonts, AUR extras |
| 06-gpu | GPU drivers (interactive selection) |
| 07-noctalia | Noctalia theming templates |
| 08-lazyvim | Neovim + LazyVim dependencies |
| 09-dotfiles | Link configs from MXVXID/lx |
| 10-bootloader | GRUB tuning (skips on systemd-boot) |
