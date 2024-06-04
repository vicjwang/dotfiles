# Find and set branch name var if in git repository.                                                   
function git_branch_name()                                                                             
{                                                                                                      
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')                       
  if [[ $branch == "" ]];                                                                              
  then                                                                                                 
    :                                                                                                  
  else                                                                                                 
    echo '('$branch')'                                                                                 
  fi                                                                                                   
}                                                                                                      
                                                                                                       
# Enable substitution in the prompt.                                                                   
setopt prompt_subst                                                                                    
                                                                                                       
export PS1="%F{cyan}%D %*%f %d %F{yellow}$(git_branch_name)%f                                                                                                     
$ "
