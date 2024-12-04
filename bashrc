# bash prompt
parse_git_branch() {
    # git branch in prompt.                                                                             
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'                              
}
export PS1="\d \T \w\$(parse_git_branch)                                          
$ "

alias cb='git symbolic-ref --short -q HEAD'

# Ubuntu only
#alias pbcopy=xclip
#alias pbpaste="xclip -o"
