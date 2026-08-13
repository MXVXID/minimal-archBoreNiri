#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo
echo "=============================================="
echo "         DEV TOOLCHAIN (OPTIONAL)"
echo "=============================================="

echo
echo "==> Installing packages (cmake, Python, Node, Go, Rust, nvm)"

mapfile -t PACKAGES < <(
    sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' \
        "$ROOT_DIR/packages/dev.txt"
)

sudo pacman -S --needed "${PACKAGES[@]}"

echo
echo "==> Installing opencode (latest)"

if command -v opencode >/dev/null 2>&1; then
    echo "==> Updating opencode"
    opencode upgrade
else
    curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/v2/install | bash
fi

echo
echo "==> Setting Rust stable toolchain"

if command -v rustup >/dev/null 2>&1; then
    rustup default stable
fi

echo
echo "==> Installing Go tools (migrate, protoc plugins)"

if command -v go >/dev/null 2>&1; then
    go install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
fi

echo
echo "==> Verifying toolchain"

for tool in cmake python3 node go gopls cargo rustc opencode uv pipx bun protoc; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  %-14s %s\n" "$tool" "$("$tool" --version 2>/dev/null | head -n 1)"
    else
        printf "  %-14s not found\n" "$tool"
    fi
done

for tool in migrate protoc-gen-go protoc-gen-go-grpc; do
    if [[ -x "$HOME/go/bin/$tool" ]]; then
        printf "  %-14s %s\n" "$tool" "$("$HOME/go/bin/$tool" --version 2>/dev/null | head -n 1)"
    else
        printf "  %-14s not found\n" "$tool"
    fi
done

echo
echo "==> NVM is ready via /usr/share/nvm/init-nvm.sh (already sourced in .zshrc)"
echo "==> Node packages run through pnpm (PNPM_HOME already set in .zshrc)"

echo
echo "=============================================="
echo "          DEV TOOLCHAIN READY"
echo "=============================================="