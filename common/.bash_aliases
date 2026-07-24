#!/bin/sh

# necessary
alias v="nvim ."
# replace gls with ls on linux
# requires coreutils on mac (brew install coreutils)
alias ls="gls -lAh --color --group-directories-first"

# git commands
alias gs="git status --short"
alias gb="git --no-pager branch"
alias gl="git log --oneline --graph --parents --all --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short"
alias gnl="git --no-pager log --oneline --graph --parents --all --max-count=20 --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset' --date=short"
alias gcat="git cat-file -p"
alias glols="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' --stat"

# optionals
alias task="nvim $HOME/workspace/knowledge/todo.md"
