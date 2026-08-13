# ============================================================
# History
# ============================================================

HISTFILE="$HOME/.zsh_history"

HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# ============================================================
# Completion
# ============================================================

fpath=(/usr/share/zsh/site-functions "$HOME/.local/share/zsh/completions" $fpath)

autoload -Uz compinit
compinit

# ============================================================
# Theme: Powerlevel10k
# ============================================================

[[ -f "$HOME/.local/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme" ]] &&
    source "$HOME/.local/share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme"

# ============================================================
# Plugins
# ============================================================

source "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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