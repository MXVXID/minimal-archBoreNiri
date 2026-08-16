#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/archbackups}"

# ------------------------------------------------------------
# Colors (fallback to plain text when not a TTY)
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'
    C_BOLD=$'\e[1m'
    C_DIM=$'\e[2m'
    C_RED=$'\e[31m'
    C_GREEN=$'\e[32m'
    C_YELLOW=$'\e[33m'
    C_CYAN=$'\e[36m'
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_RED=""
    C_GREEN=""
    C_YELLOW=""
    C_CYAN=""
fi

info() { printf "${C_CYAN}[i]${C_RESET} %s\n" "$*"; }
ok()   { printf "${C_GREEN}[✓]${C_RESET} %s\n" "$*"; }
warn() { printf "${C_YELLOW}[!]${C_RESET} %s\n" "$*"; }
section() { printf "${C_BOLD}==>${C_RESET} %s\n" "$*"; }
fail() { printf "${C_RED}[✗]${C_RESET} %s\n" "$*" >&2; }
die()  { fail "$*"; exit 1; }

line() { printf "${C_DIM}────────────────────────────────────────────────────────────────${C_RESET}\n"; }

yesno() {
    local prompt="${1:-Continue?}" answer
    printf "${C_BOLD}?${C_RESET} %s [y/N] " "$prompt"
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# ------------------------------------------------------------
# Install steps
# ------------------------------------------------------------

STEP_PATHS=(
    "scripts/01-system.sh"
    "scripts/02-cachyos.sh"
    "scripts/03-aur.sh"
    "scripts/04-zsh.sh"
    "scripts/05-desktop.sh"
    "scripts/06-gpu.sh"
    "scripts/07-noctalia.sh"
    "scripts/08-lazyvim.sh"
    "scripts/09-dotfiles.sh"
    "scripts/10-bootloader.sh"
    "scripts/11-dev.sh"
)

STEP_DESCS=(
    "System update + base packages"
    "CachyOS repos + BORE kernel"
    "AUR helper (paru / yay)"
    "Zsh + Oh My Zsh (agnoster)"
    "Niri, Noctalia, greetd, fonts, btop/cava, AUR extras"
    "GPU drivers (AMD / Intel / NVIDIA / All)"
    "Noctalia theming templates"
    "Neovim + LazyVim dependencies"
    "Dotfiles + configs from MXVXID/lx, LazyVim"
    "Bootloader (GRUB tuning / systemd-boot)"
    "Dev toolchain (cmake, Python, Node/nvm, Go, Rust, opencode)"
)

STEP_DEFAULTS=(
    on on on on on on on on on on off
)

STEP_TOTAL=${#STEP_PATHS[@]}

VALIDATE_STEP() {
    [[ "$1" =~ ^[0-9]+$ ]] || die "Internal error: invalid step '$1'"
    ((10#$1 >= 1 && 10#$1 <= STEP_TOTAL)) || die "Step $1 is out of range (1-$STEP_TOTAL)"
}

# ------------------------------------------------------------
# TUI helpers
# ------------------------------------------------------------

# Make sure a checkbox-capable UI is available for the interactive flows.
ensure_tui() {
    [[ "$MODE" == "backup" || "$MODE" == "restore" ]] && return 0

    if [[ "$HAS_WHIPTAIL" -eq 1 || "$HAS_DIALOG" -eq 1 ]]; then
        return 0
    fi

    # Non-interactive runs (--auto, --backup, --restore) never need the TUI.
    if [[ "$AUTO" -eq 1 ]]; then
        return 0
    fi

    warn "whiptail/dialog not found — the checkbox UI needs it."
    if [[ -t 0 ]] && yesno "Install newt (whiptail) with sudo?"; then
        sudo pacman -S --needed --noconfirm newt
        if command -v whiptail >/dev/null 2>&1; then
            HAS_WHIPTAIL=1
            ok "whiptail available — using the checkbox UI."
            return 0
        fi
    fi
    echo
    warn "Falling back to the manual toggle selector."
}

HAS_WHIPTAIL=0
HAS_DIALOG=0
if command -v whiptail >/dev/null 2>&1; then HAS_WHIPTAIL=1; fi
if command -v dialog   >/dev/null 2>&1; then HAS_DIALOG=1; fi

# Run a whiptail/dialog --checklist.
#   ui_checklist <title> <text> <height> <width> <listheight> <tag desc state>...
# Fills global OUT array with selected tags.
# Returns 0 = ok, 1 = cancel, 10 = no TUI available.
ui_checklist() {
    local title="$1" text="$2" height="$3" width="$4" lh="$5"
    shift 5

    local tmp tool

    if [[ "$HAS_WHIPTAIL" -eq 1 ]]; then
        tool=whiptail
    elif [[ "$HAS_DIALOG" -eq 1 ]]; then
        tool=dialog
    else
        return 10
    fi

    # whiptail/dialog need a real terminal; fall back on pipes/no-ttys.
    [[ -t 0 && -t 1 ]] || return 10

    tmp="$(mktemp)"
    if ! "$tool" --title "$title" --checklist "$text" \
            "$height" "$width" "$lh" "$@" 2>"$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    OUT=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && OUT+=("$line")
    done < <(tr -s ' ' '\n' < "$tmp" | tr -d '"')
    rm -f "$tmp"
    return 0
}

# Run a whiptail/dialog --menu (single choice).
# Fills global OUT with the tag. Returns 0/1/10 as above.
ui_menu() {
    local title="$1" text="$2" height="$3" width="$4" lh="$5"
    shift 5

    local tmp tool

    if [[ "$HAS_WHIPTAIL" -eq 1 ]]; then
        tool=whiptail
    elif [[ "$HAS_DIALOG" -eq 1 ]]; then
        tool=dialog
    else
        return 10
    fi

    [[ -t 0 && -t 1 ]] || return 10

    tmp="$(mktemp)"
    if ! "$tool" --title "$title" --menu "$text" \
            "$height" "$width" "$lh" "$@" 2>"$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    mapfile -t OUT < <(tr -s ' ' '\n' < "$tmp" | tr -d '"')
    rm -f "$tmp"
    return 0
}

# Fallback interactive toggle: type a number to flip it, ranges ok.
select_interactive() {
    local -a sel=()
    local n i answer

    for ((i = 0; i < STEP_TOTAL; i++)); do
        if [[ "${STEP_DEFAULTS[$i]}" == "on" ]]; then
            sel+=("$((i + 1))")
        fi
    done

    echo "  ${C_BOLD}Type the step number to toggle it.${C_RESET}"
    echo "  ${C_DIM}Examples: '5' flips step 5 · '1-3,8' selects a range · 'd' = done${C_RESET}"
    echo

    while true; do
        # Rebuild selection display
        printf "  Started:"
        for ((i = 0; i < STEP_TOTAL; i++)); do
            local sel_line=" "
            for n in "${sel[@]}"; do
                [[ "$n" == "$((i + 1))" ]] && sel_line="x"
            done
            if [[ "$sel_line" == "x" ]]; then
                printf "${C_GREEN}[x%2d]${C_RESET}" "$((i + 1))"
            else
                printf "${C_DIM}[ %2d]${C_RESET}" "$((i + 1))"
            fi
        done
        echo
        printf "  ${C_BOLD}Steps:${C_RESET}"
        for ((i = 0; i < STEP_TOTAL; i++)); do
            printf "\n  ${C_CYAN}%2d${C_RESET}  %s" "$((i + 1))" "${STEP_DESCS[$i]}"
        done
        echo
        printf "  ${C_BOLD}?${C_RESET} Toggle steps [d=done, a=all, n=none, q=quit]: "
        if ! read -r answer; then
            warn "Input closed — no selection made."
            return 1
        fi
        case "$answer" in
            d|D) break ;;
            a|A) sel=(); for ((i = 0; i < STEP_TOTAL; i++)); do sel+=("$((i + 1))"); done ;;
            n|N) sel=() ;;
            q|Q) return 1 ;;
            *)
                # apply spec toggles
                local filtered=()
                for part in ${answer//,/ }; do
                    if [[ "$part" =~ ^[0-9]+$ ]]; then
                        if [[ " ${sel[*]} " == *" $((10#$part)) "* ]]; then
                            filtered+=("-$((10#$part))")
                        else
                            filtered+=("$((10#$part))")
                        fi
                    elif [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                        for ((m = 10#${BASH_REMATCH[1]}; m <= 10#${BASH_REMATCH[2]}; m++)); do
                            ((m >= 1 && m <= STEP_TOTAL)) || die "Step $m out of range (1-$STEP_TOTAL)"
                            if [[ " ${sel[*]} " == *" $m "* ]]; then
                                filtered+=("-$m")
                            else
                                filtered+=("$m")
                            fi
                        done
                    else
                        warn "Ignoring invalid spec: '$part'"
                    fi
                done
                local toggled=0
                for t in "${filtered[@]}"; do
                    if [[ "$t" == -* ]]; then
                        local remove="${t#-}"
                        local rebuilt=()
                        for e in "${sel[@]}"; do
                            [[ "$e" == "$remove" ]] || rebuilt+=("$e")
                        done
                        sel=("${rebuilt[@]}")
                    else
                        sel+=("$t")
                    fi
                    toggled=1
                done
                # dedupe + sort
                mapfile -t sel < <(printf '%s\n' "${sel[@]}" | sort -nu)
                ;;
        esac
    done

    SELECTED=("${sel[@]}")
    [[ ${#SELECTED[@]} -gt 0 ]] || die "No steps selected."
}

select_steps_tui() {
    local -a checklist=()
    local i tag

    for ((i = 0; i < STEP_TOTAL; i++)); do
        tag="$((i + 1))"
        checklist+=("$tag" "${STEP_DESCS[$i]}" "$(tr 'a-z' 'A-Z' <<< "${STEP_DEFAULTS[$i]}")")
    done

    local rc=0
    ui_checklist "Install steps" \
        "Use SPACE to toggle a step, arrows to navigate, ENTER to confirm." \
        22 82 STEP_TOTAL "${checklist[@]}" || rc=$?
    if [[ "$rc" -eq 10 ]]; then
        warn "whiptail/dialog not found — using the manual toggle fallback."
        select_interactive
        return 0
    fi
    [[ "$rc" -eq 1 ]] && return 1

    SELECTED=()
    for tag in "${OUT[@]}"; do
        SELECTED+=("$((10#$tag))")
    done
    mapfile -t SELECTED < <(printf '%s\n' "${SELECTED[@]}" | sort -nu)

    [[ ${#SELECTED[@]} -gt 0 ]] || die "No steps selected."
}

# ------------------------------------------------------------
# Backup & restore
# ------------------------------------------------------------

# What the installer touches, relative to $HOME.
BACKUP_COPY_PATHS=(
    ".config/niri"
    ".config/kanata"
    ".config/kitty"
    ".config/fastfetch"
    ".config/nvim"
    ".zshrc"
)

BACKUP_EXTRAS=(
    "/etc/default/grub|etc/default-grub"
)

latest_backup() {
    local newest
    newest="$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name '????-??-??_????-??-??' 2>/dev/null | sort | tail -n 1)"
    [[ -n "$newest" ]] && printf '%s\n' "$newest"
}

make_backup() {
    local target="$1"
    local stamp pacman_count aur_count

    stamp="$(date +%Y-%m-%d_%H-%M-%S)"
    if [[ -z "$target" ]]; then
        target="$BACKUP_ROOT/$stamp"
    fi

    section "Creating backup at: ${C_YELLOW}$target${C_RESET}"
    mkdir -p "$target"/{packages,etc,home}

    if command -v pacman >/dev/null 2>&1; then
        pacman -Qqe 2>/dev/null | sort > "$target/packages/pacman-explicit.txt"
        pacman -Qqm 2>/dev/null | sort > "$target/packages/aur-foreign.txt"
        pacman_count="$(wc -l < "$target/packages/pacman-explicit.txt")"
        aur_count="$(wc -l < "$target/packages/aur-foreign.txt")"
    else
        : > "$target/packages/pacman-explicit.txt"
        : > "$target/packages/aur-foreign.txt"
        pacman_count=0
        aur_count=0
    fi

    for rel in "${BACKUP_COPY_PATHS[@]}"; do
        local src="$HOME/$rel"
        if [[ -e "$src" ]]; then
            local dest="$target/home/$(dirname "$rel")"
            mkdir -p "$dest"
            cp -a "$src" "$dest/"
            ok "packed ~/$rel"
        else
            warn "skipped ~/$rel (not present)"
        fi
    done

    for pair in "${BACKUP_EXTRAS[@]}"; do
        local src="${pair%%|*}" dest="$target/${pair#*|}"
        if [[ -e "$src" ]]; then
            mkdir -p "$(dirname "$dest")"
            cp -a "$src" "$dest"
            ok "packed $src"
        else
            warn "skipped $src (not present)"
        fi
    done

    {
        printf 'timestamp=%s\n' "$(date --iso-8601=seconds)"
        printf 'hostname=%s\n' "$(hostname 2>/dev/null || echo unknown)"
        printf 'pacman_explicit=%s\n' "$pacman_count"
        printf 'aur_foreign=%s\n' "$aur_count"
    } > "$target/MANIFEST"

    echo
    ok "Backup complete: ${C_BOLD}$target${C_RESET}"
    info "packages : $pacman_count repo / $aur_count AUR"
    info "configs  : $(find "$target/home" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l) top-level entries"
}

restore_backup() {
    local src="$1"

    if [[ -z "$src" ]]; then
        src="$(latest_backup)"
    fi
    [[ -n "$src" ]] || die "No backup found in $BACKUP_ROOT (use --backup first)."
    [[ -d "$src" ]] || die "Backup directory not found: $src"
    [[ -f "$src/MANIFEST" ]] || die "Not a valid backup (MANIFEST missing): $src"

    line
    section "Restoring from: ${C_YELLOW}$src${C_RESET}"
    [[ -f "$src/MANIFEST" ]] && cat "$src/MANIFEST" | sed 's/^/  /'
    line

    local restore_configs=1 restore_packages=0
    if yesno "Restore configs (dotfiles, xrandr/grub etc.)?"; then
        restore_configs=1
    else
        restore_configs=0
    fi

    if yesno "Restore the saved Pacman package list? (can be slow)"; then
        restore_packages=1
    fi

    if [[ "$restore_configs" -eq 1 ]]; then
        local stamp="$BACKUP_ROOT/.pre-restore-$(date +%Y-%m-%d_%H-%M-%S)"
        mkdir -p "$stamp"

        while IFS= read -r -d '' src_entry; do
            local rel="${src_entry#"$src/home/"}"
            local target="$HOME/$rel"
            mkdir -p "$(dirname "$target")"

            if [[ -e "$target" ]]; then
                mkdir -p "$(dirname "$stamp/$rel")"
                cp -a "$target" "$stamp/$rel"
                warn "current ~/$rel moved to ${C_DIM}$stamp${C_RESET}"
            fi
            cp -a "$src_entry" "$target"
            ok "restored ~/$rel"
        done < <(find "$src/home" -mindepth 1 -maxdepth 1 -print0)
    fi

    local grub_src="$src/etc/default-grub"
    if [[ -f "$grub_src" ]]; then
        if yesno "Restore /etc/default/grub (needs sudo)?"; then
            sudo cp -a "$grub_src" /etc/default/grub
            ok "restored /etc/default/grub"
        fi
    fi

    if [[ "$restore_packages" -eq 1 ]]; then
        local explicit="$src/packages/pacman-explicit.txt" aur="$src/packages/aur-foreign.txt"
        if [[ -s "$explicit" ]]; then
            info "Reinstalling $(wc -l < "$explicit") explicit packages …"
            sudo pacman -S --needed --noconfirm - < "$explicit"
            ok "pacman packages restored"
        else
            warn "no explicit package list in backup"
        fi
        if [[ -s "$aur" ]]; then
            local helper=""
            command -v paru >/dev/null 2>&1 && helper=paru
            if [[ -z "$helper" ]]; then command -v yay >/dev/null 2>&1 && helper=yay; fi
            if [[ -n "$helper" ]]; then
                if yesno "Reinstall $(wc -l < "$aur") AUR packages via $helper?"; then
                    $helper -S --needed --noconfirm - < "$aur"
                    ok "AUR packages restored"
                fi
            else
                warn "no AUR helper found — saved list: $aur"
            fi
        fi
    fi

    line
    ok "Restore finished."
}

# ------------------------------------------------------------
# Banner
# ------------------------------------------------------------

banner() {
    local art=$'███╗   ███╗██╗  ██╗██╗   ██╗██╗  ██╗\n████╗ ████║╚██╗██╔╝██║   ██║╚██╗██╔╝\n██╔████╔██║ ╚███╔╝ ██║   ██║ ╚███╔╝\n██║╚██╔╝██║ ██╔██╗ ╚██╗ ██╔╝ ██╔██╗\n██║ ╚═╝ ██║██╔╝ ██╗ ╚████╔╝ ██╔╝ ██╗\n╚═╝     ╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝  ╚═╝'

    printf "${C_BOLD}${C_CYAN}%s${C_RESET}\n" "$art"
    printf "${C_BOLD}   Arch Linux bootstrap${C_RESET}  ${C_DIM}•${C_RESET}  Niri  ${C_DIM}•${C_RESET}  Noctalia  ${C_DIM}•${C_RESET}  greetd\n\n"
}

# ------------------------------------------------------------
# Preflight checks
# ------------------------------------------------------------

preflight() {
    if [[ "$EUID" -eq 0 ]]; then
        die "Do not run this installer as root. Run it as your normal user."
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        die "sudo is required but was not found."
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        die "This installer is for Arch-based systems only."
    fi

    if ! command -v curl >/dev/null 2>&1; then
        die "curl is required but was not found."
    fi
}

# ------------------------------------------------------------
# System info
# ------------------------------------------------------------

system_info() {
    local distro=""
    local host=""
    [[ -f /etc/os-release ]] && distro="$(sed -n 's/^PRETTY_NAME="\?\([^"]*\)"\?/\1/p' /etc/os-release)"
    host="$(hostname 2>/dev/null || hostnamectl hostname 2>/dev/null || echo unknown)"

    printf "  ${C_BOLD}System${C_RESET}\n"
    printf "  %-12s %s\n" "User:"     "$USER"
    printf "  %-12s %s\n" "Host:"     "$host"
    printf "  %-12s %s\n" "Distro:"   "${distro:-unknown}"
    printf "  %-12s %s\n" "Kernel:"   "$(uname -r)"
    printf "  %-12s %s\n" "Shell:"    "$(basename "${SHELL:-unknown}")"
    printf "  %-12s %s\n" "Repo:"     "$ROOT_DIR"
    printf "  %-12s %s\n" "Disk free:" "$(df -h / | awk 'NR==2 {print $4, "available (" $6 ")"}')"
    echo
}

# ------------------------------------------------------------
# Step runner
# ------------------------------------------------------------

run_steps() {
    local count=0 n
    for n in "${SELECTED[@]}"; do
        count=$((count + 1))
        run_step "$count" "${STEP_PATHS[$((n - 1))]}" "${STEP_DESCS[$((n - 1))]}"
    done
}

run_step() {
    local n="$1" path="$2" desc="$3"

    echo
    line
    printf "${C_BOLD}  STEP %d/%d${C_RESET}  ${C_CYAN}%s${C_RESET}  ${C_DIM}— %s${C_RESET}\n" \
        "$n" "${#SELECTED[@]}" "$(basename "$path")" "$desc"
    line

    if bash "$ROOT_DIR/$path"; then
        ok "Step $n done"
    else
        fail "Step $n failed"
        read -rp "  Continue with remaining steps? [y/N] " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            die "Aborted by user."
        fi
    fi
}

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

summary() {
    echo
    line
    printf "${C_GREEN}${C_BOLD}  INSTALL COMPLETE${C_RESET}\n"
    line

    local -a checks=(
        "linux-cachyos-bore|CachyOS BORE kernel"
        "niri|Niri compositor"
        "noctalia|Noctalia theming"
        "greetd|greetd + Noctalia Greeter"
        "kanata|Kanata remapper"
        "zsh|Zsh"
        "fastfetch|Fastfetch"
        "nvim|Neovim"
        "cmake|Dev toolchain (optional)"
    )

    for entry in "${checks[@]}"; do
        local pkg="${entry%%|*}"
        local label="${entry#*|}"
        if command -v "$pkg" >/dev/null 2>&1 || pacman -Q "$pkg" >/dev/null 2>&1; then
            printf "  ${C_GREEN}✓${C_RESET}  %-28s installed\n" "$label"
        else
            printf "  ${C_DIM}•${C_RESET}  %-28s not installed (skipped)\n" "$label"
        fi
    done

    echo
    info "After login:"
    info "  · Oh My Zsh — change ZSH_THEME in .zshrc (default: agnoster)"
    info "  · qt6ct → Appearance → Color scheme: noctalia (KColorScheme)"
    info "  · Noctalia Settings → Templates → enable 'pywalfox-beta4'"
    info "  · Noctalia Settings → Security → Noctalia Greeter → Sync Now"
    info "  · After Noctalia Sync: re-run script 07 to apply the Telegram theme"
}

# ------------------------------------------------------------
# Usage
# ------------------------------------------------------------

usage() {
    cat <<EOF
Usage: ./install.sh [options]

Modes:
  (no option)         Interactive menu (install / backup / restore)
  --install           Run the install wizard
  --backup [dir]      Snapshot packages + configs before significant changes
  --restore [dir]     Restore from a backup (defaults to the latest)

Options:
  --auto              Run all core steps (1-$((STEP_TOTAL - 1))) without prompts
  --steps <spec>      Run only the given steps, e.g. --steps 1-3,5
  --help, -h          Show this help

Environment:
  BACKUP_ROOT         Backup directory (default: $HOME/archbackups)

Steps:
$(for i in "${!STEP_PATHS[@]}"; do printf "  %2d  %s\n" "$((i + 1))" "${STEP_DESCS[$i]}"; done)
EOF
    exit 0
}

# ------------------------------------------------------------
# Main menu
# ------------------------------------------------------------

main_menu() {
    echo "  ${C_BOLD}What do you want to do?${C_RESET}"
    echo

    local -a items=(
        "install"   "Run the installer (pick steps with checkboxes)"
        "backup"    "Create a package + config snapshot"
        "restore"   "Restore from an existing backup"
        "quit"      "Exit"
    )

    local rc=0
    ui_menu "MXVX Arch Setup" "Choose a mode:" 14 72 8 "${items[@]}" || rc=$?
    if [[ "$rc" -eq 10 ]]; then
        echo "  1) Install"
        echo "  2) Backup"
        echo "  3) Restore"
        echo "  4) Quit"
        printf "  ${C_BOLD}?${C_RESET} Choice [1]: "
        if ! read -r choice; then
            choice="4"
        fi
        choice="${choice:-1}"
        case "$choice" in
            1|install)   choice="install" ;;
            2|backup)    choice="backup" ;;
            3|restore)   choice="restore" ;;
            *)           choice="quit" ;;
        esac
    elif [[ "$rc" -eq 1 ]]; then
        echo "  Cancelled."
        exit 0
    else
        choice="${OUT[0]}"
    fi

    case "$choice" in
        install) install_mode ;;
        backup)  make_backup "" ;;
        restore) restore_backup "" ;;
        quit|*)  exit 0 ;;
    esac
}

# ------------------------------------------------------------
# Install flow
# ------------------------------------------------------------

install_mode() {
    if [[ "$AUTO" -eq 1 ]]; then
        if [[ "$STEPS_SET" -ne 1 ]]; then
            SELECTED=()
            for ((i = 1; i < STEP_TOTAL; i++)); do
                SELECTED+=("$i")
            done
            info "Auto mode — running core steps 1-$((STEP_TOTAL - 1)) (dev toolchain skipped, use --steps $STEP_TOTAL)"
        else
            info "Auto mode — running selected steps without prompts"
        fi
    else
        if [[ "$STEPS_SET" -ne 1 ]]; then
            select_steps_tui || { echo "  Cancelled."; exit 0; }

            # offer the optional dev step explicitly when not picked
            if [[ " ${SELECTED[*]} " != *" $STEP_TOTAL "* ]]; then
                if yesno "Also install the dev toolchain (step $STEP_TOTAL)?"; then
                    SELECTED+=("$STEP_TOTAL")
                    mapfile -t SELECTED < <(printf '%s\n' "${SELECTED[@]}" | sort -nu)
                fi
            fi
        fi
    fi

    # Save the selection both as a display and as the run list
    echo
    line
    printf "${C_BOLD}  SELECTED ${#SELECTED[@]} STEP(S)${C_RESET}\n"
    line
    for n in "${SELECTED[@]}"; do
        printf "  ${C_GREEN}[x]${C_RESET}  %2d  %s\n" "$n" "${STEP_DESCS[$((n - 1))]}"
    done
    echo

    if [[ "$AUTO" -eq 0 ]]; then
        if yesno "Create a safety backup before starting?"; then
            make_backup ""
        fi
        if ! yesno "Begin installation now?"; then
            echo "  Cancelled."
            exit 0
        fi
    fi

    run_steps
    summary

    if [[ "$AUTO" -eq 0 ]]; then
        echo
        read -rp "  Reboot now? [y/N] " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            sudo reboot
        fi
    fi

    echo
    ok "Done. See you on the other side — rebooting is recommended."
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

AUTO=0
STEPS_SET=0
MODE="menu"
BACKUP_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)        AUTO=1; shift ;;
        --steps)
            if [[ $# -lt 2 ]]; then
                die "--steps needs an argument"
            fi
            MODE="install"
            SELECTED=()
            for part in ${2//,/ }; do
                if [[ "$part" =~ ^[0-9]+$ ]]; then
                    VALIDATE_STEP "$part"
                    SELECTED+=("$((10#$part))")
                elif [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                    for ((m = 10#${BASH_REMATCH[1]}; m <= 10#${BASH_REMATCH[2]}; m++)); do
                        VALIDATE_STEP "$m"
                        SELECTED+=("$m")
                    done
                else
                    die "Invalid step spec: '$part' (expected e.g. 1-3,5)"
                fi
            done
            mapfile -t SELECTED < <(printf '%s\n' "${SELECTED[@]}" | sort -nu)
            if [[ ${#SELECTED[@]} -eq 0 ]]; then
                die "No steps selected."
            fi
            STEPS_SET=1
            shift 2
            ;;
        --install)     MODE="install"; shift ;;
        --backup)
            MODE="backup"
            if [[ $# -ge 2 && "$2" != -* ]]; then
                BACKUP_ARG="$2"; shift 2
            else
                shift
            fi
            ;;
        --restore)
            MODE="restore"
            if [[ $# -ge 2 && "$2" != -* ]]; then
                BACKUP_ARG="$2"; shift 2
            else
                shift
            fi
            ;;
        --help|-h)     usage ;;
        *)             die "Unknown option: $1 (try --help)" ;;
    esac
done

trap 'echo; warn "Interrupted — partial install, safe to re-run."; exit 130' INT TERM

preflight

banner
system_info

if [[ "$AUTO" -eq 1 && "$MODE" == "menu" ]]; then
    MODE="install"
fi

ensure_tui

case "$MODE" in
    menu)     main_menu ;;
    install)  install_mode ;;
    backup)   make_backup "$BACKUP_ARG" ;;
    restore)  restore_backup "$BACKUP_ARG" ;;
esac