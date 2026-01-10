# ============================================================
# ~/.zshrc — M4 MacBook Pro | Optimized, Fork-Safe & Professional
# ============================================================

# ------------------------------------------------------------
# 1. Guard: Prevent Recursive Sourcing / Fork Bombs
# ------------------------------------------------------------
# This prevents the "fork: Resource temporarily unavailable" 
# issue by stopping child processes from re-running the script.
if [[ -n "$ZSHRC_INITIALIZED" ]]; then
  return
fi
export ZSHRC_INITIALIZED=1

# ------------------------------------------------------------
# 2. Editor & Shell Options
# ------------------------------------------------------------
export EDITOR=/usr/bin/vi

# Keybindings: Force Emacs mode to ensure Ctrl+P/N work correctly
bindkey -e
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history

setopt PROMPT_SUBST                      # Essential for dynamic Git/Venv info
setopt INTERACTIVE_COMMENTS              # Allow comments (starting with #)
setopt SHARE_HISTORY                     # Share history across all tmux panes
setopt HIST_IGNORE_DUPS                  # Don't clutter history with duplicates

# Resource Limits: Overriding macOS defaults for heavy dev work
ulimit -n 4096                           # Increase file descriptors (from 256)
ulimit -u 4000                           # Maintain healthy process limit

# ------------------------------------------------------------
# 3. PATH & Toolchain
# ------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.lmstudio/bin:$PATH"

# pyenv initialization
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d $PYENV_ROOT ]]; then
  eval "$(pyenv init - --no-rehash)"
fi

# ------------------------------------------------------------
# 4. Aliases
# ------------------------------------------------------------
alias cb='git symbolic-ref --short -q HEAD'
alias code='cd ~/code/replit/trading && ~/.tmux/sessions/trading.sh'
alias gr="git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ | head -10"

alias pr='poetry run'
alias prp='poetry run python'
alias prt='poetry run pytest'
alias ur='uv run'
alias urt='uv run pytest'
alias jr='just run'

alias mtwr='cd ~/code/moontower'
alias trading='cd ~/code/trading/options'
alias eic='cd ~/code/trading/options && time poetry run python -m options.workflows.candidates.iron_condors'
alias els='cd ~/code/trading/options && time poetry run python -m options.workflows.candidates.long_straddle'

alias chrome='open -a "Google Chrome"'
alias table='column -t -s","'
alias ff='find . | grep'
alias lsdt='lsd --tree --depth 2 --long --human-readable'
alias rgpy="rg -g '!docs' -g '!tests' -g '!*.log*'"
alias plans="ls -ltr ~/.claude/plans && echo '~/.claude/plans'"
alias done="osascript -e 'display notification \"Terminal finished!\"' && tput bel"

# ------------------------------------------------------------
# 5. Third-Party Initializers
# ------------------------------------------------------------
if [[ $- == *i* ]]; then
  eval "$(zoxide init zsh)"
fi

# ------------------------------------------------------------
# 6. Prompt Logic: The "Final Word" Hook
# ------------------------------------------------------------
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

# Git Info Configuration
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedfmt '%F{red}●%f'
zstyle ':vcs_info:git:*' stagedfmt '%F{green}●%f'

# Swapped: Branch is Yellow, Path is Cyan
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b%u%c)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%F{magenta}%a%f%u%c)%f'

# Helper: Detect Virtual Environments (Poetry/uv/venv) - Now Magenta with Parentheses
venv_info() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "%F{magenta}(${VIRTUAL_ENV:t})%f "
  fi
}

# The Render Function: Overwrites /etc/zshrc defaults
force_prompt_config() {
  vcs_info
  # Layout: (magenta-venv) YYYY-MM-DD HH:MM:SS CyanPath (YellowBranch)
  local base_prompt='$(venv_info)%F{242}%D{%Y-%m-%d} %*%f %F{cyan}%~%f${vcs_info_msg_0_}'
  PROMPT="$base_prompt
$ "
  PS1="$PROMPT" 
}

# The hook ensures this runs last before every prompt display
add-zsh-hook precmd force_prompt_config

# Fix $PWD inheritance inside tmux
if [[ -n $TMUX ]]; then
  cd "$PWD" >/dev/null 2>&1
fi

# ============================================================
# End of ~/.zshrc
# ============================================================