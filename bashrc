# bash prompt
parse_git_branch() {
    # git branch in prompt.                                                                             
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'                              
}
export PS1="\d \T \w\$(parse_git_branch)                                          
$ "
# osx prompt
export PS1="\[^[[38;5;6m\]\d\[$(tput sgr0)\]\[^[[38;5;6m\] \[$(tput sgr0)\]\[^[[38;5;6m\]\T\[$(tput sgr0)\] \w\[^[[38;5;3m\]\$(parse_git_branch)\[$(tput sgr0)\]
 $ "

alias cb='git symbolic-ref --short -q HEAD'
