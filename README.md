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
- yazi (terminal file manager)
- JetBrains Mono Nerd Font + all Nerd Fonts (via ttf-nerd-fonts-meta)
- Noto fonts (complete Unicode + CJK + emoji)
- PipeWire + WirePlumber
- NetworkManager
- gvfs + gvfs-mtp (filesystem mount support)
- mpv + mpv-mpris + yt-dlp (media playback)
- cliamp (retro terminal music player, AUR)
- Kanata (AUR)
- qt6ct-kde (AUR, Qt theming)
- btop + cava (Noctalia templates)
- Neovim + LazyVim (starter + prerequisites)
- Dev toolchain **(optional)**: cmake + ninja, Python + pip + uv + pipx, Node.js + npm + pnpm + bun + nvm, Go + gopls + migrate + protoc/grpc, Rust (rustup), opencode (curl installer)

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
./install.sh                      # menu: interactive wizard (checkboxes), backup, restore
./install.sh --install           # go straight to the install wizard
./install.sh --backup            # snapshot packages + configs to ~/archbackups
./install.sh --restore           # restore from the latest backup (or pass a dir)
./install.sh --auto              # run all core steps without prompts
./install.sh --steps 1-3,5       # run only specific steps
./install.sh --steps 11          # install only the dev toolchain
```

The dev toolchain (step 11) is **optional** — the wizard asks for it and the default is
*no*. Use `--steps 11` (or `--steps 1-11`) to include it.

> Confirmation prompts use `[Y/n]` (Enter = yes) for the steps that actually do work,
> and `[y/N]` (Enter = no) for optional extras — pressing Enter just keeps the flow
> moving instead of accidentally cancelling.

### Step selection

The wizard uses a **checkbox** UI (`whiptail`/`dialog`, press `SPACE` to toggle);
`newt` (whiptail) is part of step 1's base packages, and if you run the wizard
before that it offers to install it for you. If neither is available it falls
back to a manual toggle prompt.
Use `BACKUP_ROOT=/some/dir` to change where backups are stored.

### Backup & restore

`--backup` snapshots everything the installer touches before making changes:

```
~/archbackups/<timestamp>/
├── MANIFEST            # timestamp, host, package counts
├── packages/           # pacman -Qqe + pacman -Qqm (AUR) lists
├── etc/default-grub    # bootloader settings
└── home/               # .config/niri, kanata, kitty, fastfetch, nvim, .zshrc
```

`--restore` copies the configs back (the current state is moved to a
`.pre-restore-*` folder first) and can optionally reinstall the saved package
and AUR lists. A backup is also offered before starting an interactive install.

## After first login

- `qt6ct` → Appearance → Color scheme: `noctalia (KColorScheme)`
- Noctalia Settings → Templates → enable community templates → enable `pywalfox-beta4`
- Install the [Pywalfox](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/) extension in Firefox and restart it once
- Noctalia Settings → Security → Noctalia Greeter → **Sync Now** (copies wallpaper/palette/font to the login screen) — optional: enable Auto-Sync
- **Telegram**: after Noctalia Sync, re-run script 07 (applies theme to `~/.local/share/TelegramDesktop/tdata/colors.tdesktop-theme`), then restart Telegram

## Structure

```
install.sh          # main entrypoint (menu / install / backup / restore)
packages/           # package lists (base, zsh, desktop)
scripts/            # numbered install steps
wallpapers/         # bundled wallpapers (deployed to ~/Pictures/Wallpapers by step 09)
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
| 09-dotfiles | Link configs from MXVXID/lx + LazyVim + deploy wallpapers |
| 10-bootloader | GRUB tuning (skips on systemd-boot) |
| 11-dev | Dev toolchain (optional — cmake, Python, Node, Go, Rust, nvm) |
