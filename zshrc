# ============================================================
# ~/.zshrc — M4 MacBook Pro Bulletproof Version
# ============================================================
setopt PROMPT_SUBST
export CLAUDE_SHELL_REPLAY_GUARD=1

# ------------------------------------------------------------
# PATH & Toolchain
# ------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/.lmstudio/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT ]] && eval "$(pyenv init - --no-rehash)"

# ------------------------------------------------------------
# Editor & Shell Options
# ------------------------------------------------------------
export EDITOR=/usr/bin/vi
bindkey -e                               # Enable Emacs bindings
bindkey '^P' up-line-or-history          # Ctrl-P for previous
bindkey '^N' down-line-or-history        # Ctrl-N for next
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS

# ------------------------------------------------------------
# Aliases
# ------------------------------------------------------------
alias cb='git symbolic-ref --short -q HEAD'
alias pr='poetry run'
alias ur='uv run'
alias lsdt='lsd --tree --depth 2 --long --human-readable'
alias done="osascript -e 'display notification \"Terminal program finished!\"' && tput bel"

# ------------------------------------------------------------
# zoxide (Init but don't let it touch the prompt)
# ------------------------------------------------------------
if [[ $- == *i* ]]; then
  eval "$(zoxide init zsh)"
fi

# ------------------------------------------------------------
# High-Priority Git Prompt Logic (Color Swapped)
# ------------------------------------------------------------
autoload -Uz vcs_info
autoload -Uz add-zsh-hook

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedfmt '%F{red}●%f'
zstyle ':vcs_info:git:*' stagedfmt '%F{green}●%f'

# Swapped: Branch name is now Yellow (%F{yellow})
zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b%u%c)%f'
zstyle ':vcs_info:git:*' actionformats ' %F{yellow}(%b|%F{magenta}%a%f%u%c)%f'

force_prompt_config() {
  vcs_info
  # Swapped: Directory path is now Cyan (%F{cyan})
  PROMPT='%F{242}%D{%Y-%m-%d} %*%f %F{cyan}%~%f${vcs_info_msg_0_}
$ '
  PS1="$PROMPT"
}

add-zsh-hook precmd force_prompt_config

# Fix $PWD inside tmux
[[ -n $TMUX ]] && cd "$PWD" >/dev/null 2>&1
