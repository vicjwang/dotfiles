# Make sure .bashrc is sourced from .bash_profile
#  e.g. Put this snippet in ~/.bash_profile:
#  if [ -f ~/.bashrc ]; then
#    source ~/.bashrc
#  fi
 

# bash prompt
parse_git_branch() {
    # git branch in prompt.                                                                             
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'                              
}
export PS1="\d \T \w\$(parse_git_branch)                                          
$ "

alias cb='git symbolic-ref --short -q HEAD'
alias chrome='open -a "Google Chrome"'
alias pr='poetry run'
alias table='column -t -s","'

# Ubuntu only
#alias pbcopy=xclip
#alias pbpaste="xclip -o"



# To ensure copy/paste works with tmux
bind 'set enable-bracketed-paste on'

