#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
fail() { printf "${C_RED}[✗]${C_RESET} %s\n" "$*" >&2; }
die()  { fail "$*"; exit 1; }

line() { printf "${C_DIM}────────────────────────────────────────────────────────${C_RESET}\n"; }

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
    "Dev toolchain (cmake, Python/uv/pipx, Node/pnpm/bun, Go/gopls/migrate/grpc, Rust, opencode) — optional"
)

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
# Step selection
# ------------------------------------------------------------

print_steps() {
    for i in "${!STEP_PATHS[@]}"; do
        printf "  ${C_CYAN}%2d${C_RESET}  %s\n" "$((i + 1))" "${STEP_DESCS[$i]}"
    done
    echo
}

parse_step_spec() {
    local spec="$1"
    local -a selected=()
    local part n lo hi

    IFS=',' read -ra parts <<< "$spec"

    for part in "${parts[@]}"; do
        if [[ "$part" =~ ^[0-9]+$ ]]; then
            selected+=("$((10#$part))")
        elif [[ "$part" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            lo=$((10#${BASH_REMATCH[1]}))
            hi=$((10#${BASH_REMATCH[2]}))
            for ((n = lo; n <= hi; n++)); do
                selected+=("$n")
            done
        else
            die "Invalid step spec: '$part' (expected e.g. 1-3,5)"
        fi
    done

    for n in "${selected[@]}"; do
        ((n >= 1 && n <= ${#STEP_PATHS[@]})) || die "Step $n is out of range (1-${#STEP_PATHS[@]})"
    done

    mapfile -t SELECTED < <(printf '%s\n' "${selected[@]}" | sort -nu)

    [[ ${#SELECTED[@]} -gt 0 ]] || die "No steps selected."
}

select_interactive() {
    echo "  ${C_BOLD}Install steps${C_RESET}"
    print_steps
    read -rp "  Steps to run [all / e.g. 1-3,5]: " answer

    if [[ -z "$answer" || "$answer" == "all" ]]; then
        SELECTED=()
        local total=${#STEP_PATHS[@]}
        for ((i = 1; i < total; i++)); do
            SELECTED+=("$i")
        done
    else
        parse_step_spec "$answer"
    fi
}

# ------------------------------------------------------------
# Step runner
# ------------------------------------------------------------

run_step() {
    local n="$1"
    local path="$2"
    local desc="$3"

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

Options:
  --auto           Run all steps without any prompts
  --steps <spec>   Run only the given steps, e.g. --steps 1-3,5
  --help           Show this help

Steps:
$(for i in "${!STEP_PATHS[@]}"; do printf "  %2d  %s\n" "$((i + 1))" "${STEP_DESCS[$i]}"; done)
EOF
    exit 0
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

AUTO=0
STEPS_SET=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)      AUTO=1; shift ;;
        --steps)     parse_step_spec "$2"; STEPS_SET=1; shift 2 ;;
        --help|-h)   usage ;;
        *)           die "Unknown option: $1 (try --help)" ;;
    esac
done

trap 'echo; warn "Interrupted — partial install, safe to re-run."; exit 130' INT TERM

preflight

banner
system_info

if [[ "$AUTO" -eq 1 ]]; then
    if [[ "$STEPS_SET" -ne 1 ]]; then
        SELECTED=()
        total=${#STEP_PATHS[@]}
        for ((i = 1; i < total; i++)); do
            SELECTED+=("$i")
        done
        info "Auto mode — running core steps 1-$((total - 1)) (dev toolchain skipped, use --steps 11)"
    else
        info "Auto mode — running selected steps without prompts"
    fi
else
    if [[ "$STEPS_SET" -ne 1 ]]; then
        select_interactive

        if [[ " ${SELECTED[*]} " != *" ${#STEP_PATHS[@]} "* ]]; then
            read -rp "  Also install the dev toolchain (step ${#STEP_PATHS[@]})? [y/N] " dev_answer
            if [[ "$dev_answer" =~ ^[Yy]$ ]]; then
                SELECTED+=("${#STEP_PATHS[@]}")
            fi
        fi
    fi

    echo "  ${C_BOLD}Selected ${#SELECTED[@]} step(s):${C_RESET}"
    for n in "${SELECTED[@]}"; do
        printf "  ${C_CYAN}%2d${C_RESET}  %s\n" "$n" "${STEP_DESCS[$((n - 1))]}"
    done
    echo

    read -rp "  Begin installation? [Y/n] " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        echo "  Cancelled."
        exit 0
    fi
fi

count=0
for n in "${SELECTED[@]}"; do
    count=$((count + 1))
    run_step "$count" "${STEP_PATHS[$((n - 1))]}" "${STEP_DESCS[$((n - 1))]}"
done

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
