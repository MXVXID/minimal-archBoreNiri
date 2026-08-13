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

autoload -Uz compinit
compinit

# ============================================================
# Autosuggestions
# ============================================================

source "$HOME/.local/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ============================================================
# Syntax Highlighting
# ============================================================

source "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ============================================================
# Git
# ============================================================

autoload -Uz vcs_info

precmd() {
    vcs_info
}

zstyle ':vcs_info:git:*' formats ' [%b]'

setopt PROMPT_SUBST

PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f %# '

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

# ============================================================
# Environment
# ============================================================

export EDITOR='nvim'
export VISUAL='nvim'
export QT_QPA_PLATFORMTHEME='qt6ct'
