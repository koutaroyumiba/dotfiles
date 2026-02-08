#!/bin/sh

# necessary
alias v="nvim ."
# replace gls with ls on linux
# requires coreutils on mac (brew install coreutils)
alias ls="gls -lAh --color --group-directories-first"

# git commands
alias gs="git status --short"
alias gb="git --no-pager branch"
alias gl="git log --oneline --graph --parents --all"
alias gnl="git --no-pager log --oneline --graph --parents --all --max-count=20"
alias gcat="git cat-file -p"
