# ============================================================
# Oh My Zsh
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# ============================================================
# Plugins
# ============================================================

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ============================================================
# fzf
# ============================================================

if command -v fzf >/dev/null 2>&1; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
fi

# ============================================================
# Fastfetch
# ============================================================

if command -v fastfetch >/dev/null 2>&1 && [[ ! -v NO_FASTFETCH ]]; then
    fastfetch
fi

# ============================================================
# Aliases
# ============================================================

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'

alias v='nvim'
alias vi='nvim'

alias ff='fastfetch'

# ============================================================
# Environment
# ============================================================

export EDITOR='nvim'
export VISUAL='nvim'
export QT_QPA_PLATFORMTHEME='qt6ct'

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/go/bin"
export PATH="$HOME/.opencode/bin:$PATH"

export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

export PATH="$HOME/develop/flutter/bin:$PATH"
export CHROME_EXECUTABLE="/usr/bin/google-chrome-stable"

# ============================================================
# Dev tooling
# ============================================================

[[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh

[[ -f "$HOME/.openclaw/completions/openclaw.zsh" ]] &&
    source "$HOME/.openclaw/completions/openclaw.zsh"

if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1; then
    . "$(kiro --locate-shell-integration-path zsh)"
fi

# ============================================================
# Local overrides (machine-specific, never overwritten)
# ============================================================

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"