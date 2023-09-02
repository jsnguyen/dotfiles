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
export PS1="%{$fg[green]%}%n@%m | %c -> %{$reset_color%}"

# delete key to work on macos
bindkey "^[[3~" delete-char

# aliases
alias ls='ls --color'
alias cdl='cd ~/landing'
alias cdp='cd ~/landing/projects'
alias cda='cd ~/landing/analyses'
alias cdd='cd ~/landing/data'
alias esh='tmux detach -P'
alias ds9='/Applications/SAOImageDS9.app/Contents/MacOS/ds9'
alias ds9lock='/Applications/SAOImageDS9.app/Contents/MacOS/ds9 -lock frame image -colorbar lock yes -lock scalelimits'
alias sjl='~/landing/scripts/start_tmux_jupyter_lab.sh'

alias sshdquick='ssh -Y -p 12392 jsn@dquick.local'
alias sshdecaf='ssh -Y jsn@decaf.ucsd.edu'
alias sshtrenta='ssh -Y jsn@trenta.ucsd.edu'
alias vnctunnel='~/landing/scripts/vnc_tunnel_decaf.sh'

# misc
setopt nomatch

# tmux on ssh
if [[ "$TERM_PROGRAM" != "vscode" ]]; then
    if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
        tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
    else
        # always run tmux
        DEFAULT_TMUX_NAME="dtmux"
        if [[ -z "$TMUX" ]]; then
            tmux attach-session -t ${DEFAULT_TMUX_NAME} || tmux new-session -s ${DEFAULT_TMUX_NAME}
        fi
    fi
fi
