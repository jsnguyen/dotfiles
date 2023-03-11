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
export PS1="%{$fg[green]%}%n@%c | %{$reset_color%}"

# delete key to work on macos
bindkey "^[[3~" delete-char

# aliases
alias ls='ls --color'
alias cdl='cd ~/landing'
alias cdc='cd ~/landing/code'
alias cdd='cd ~/landing/data'
alias esh='tmux detach -P'
#alias ds9='/Applications/SAOImageDS9.app/Contents/MacOS/ds9'
#alias ds9lock='/Applications/SAOImageDS9.app/Contents/MacOS/ds9 -lock frame image -lock scale -colorbar lock yes -lock scalelimits'
alias sjl='~/landing/repos/scripts/start_tmux_jupyter_lab.sh'

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
