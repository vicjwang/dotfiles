#!/bin/bash

SESSION=session
CODEDIR=~/code/

tmux new-session -s $SESSION -d

tmux new-window -t $SESSION:1
tmux new-window -t $SESSION:2
tmux new-window -t $SESSION:3 -n test

tmux new-window -t $SESSION:4 -n run
tmux split-window -v -t $SESSION:4

tmux new-window -t $SESSION:5 -n git

tmux new-window -t $SESSION:6 -n db
tmux split-window -v -t $SESSION:6

tmux new-window -t $SESSION:7 -n server
tmux new-window -t $SESSION:8
tmux new-window -t $SESSION:9

tmux -2 attach-session -t $SESSION
