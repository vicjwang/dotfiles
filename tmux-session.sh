#!/bin/sh

# Set Session Name
SESSION="replit"
SESSIONEXISTS=$(tmux list-sessions | grep $SESSION)

WORK_DIR="~/code/replit/trading"

# Only create tmux session if it doesn't already exist
if [ "$SESSIONEXISTS" = "" ]
then
    # Start New Session with our name
    tmux new-session -d -s $SESSION

    # Name first Pane and start zsh
    tmux rename-window -t 0 'main'
    tmux send-keys -t 'main' "cd ${WORK_DIR}" C-m

    tmux new-window -t $SESSION:1 -n '1'
    tmux send-keys -t '1' "cd ${WORK_DIR}" C-m

    tmux new-window -t $SESSION:2 -n 'tests'
    tmux send-keys -t '2' "cd ${WORK_DIR}" C-m
    tmux split-window -h -t '2'
    tmux send-keys -t '2.1' "cd ${WORK_DIR} && ENV=test poetry run pytest" C-m

    tmux new-window -t $SESSION:3 -n 'ipython'
    tmux send-keys -t 'ipython' "cd ${WORK_DIR} && poetry run ipython" C-m

    tmux new-window -t $SESSION:4 -n 'run'
    tmux send-keys -t 'run' "cd ${WORK_DIR}" C-m

    tmux new-window -t $SESSION:5 -n 'git'
    tmux send-keys -t 'git' "cd ${WORK_DIR}" C-m

    tmux new-window -t $SESSION:8 -n 'jtop'
    tmux send-keys -t 'jtop' "jtop" C-m

    # setup Writing window
#    tmux new-window -t $SESSION:2 -n 'Writing'
    #tmux send-keys -t 'Writing' "nvim" C-m

    # Setup an additional shell
    #tmux new-window -t $SESSION:3 -n 'Shell'
    #tmux send-keys -t 'Shell' "zsh" C-m 'clear' C-m
fi

# Attach Session, on the Main window
tmux attach-session -t $SESSION:2
