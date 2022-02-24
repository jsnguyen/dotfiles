# command history
HISTFILE=~/.zsh_histfile
HISTSIZE=100000
SAVEHIST=100000
setopt appendhistory

# zsh completions
autoload -Uz compinit
compinit

# prompt
autoload -U colors && colors
export PS1="%{$fg[green]%}%c | %{$reset_color%}"

# delete key to work on macos
bindkey "^[[3~" delete-char

# aliases
alias ls='ls --color'
alias cdl='cd ~/landing'
alias esh='tmux detach -P'

# misc
setopt nomatch

# tmux on ssh
if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
    tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
else
    # always run tmux
    DEFAULT_TMUX_NAME="dtmux"
    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t ${DEFAULT_TMUX_NAME} || tmux new-session -s ${DEFAULT_TMUX_NAME}
    fi
fi
