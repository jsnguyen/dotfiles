# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory nomatch
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/jsnguyen/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

autoload -U colors && colors
export PS1="%{$fg[green]%}[%c]: %{$reset_color%}"
  alias ls='ls --color'
bindkey "^[[3~" delete-char

if [[ -n "$PS1" ]] && [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]]; then
  tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
fi

PATH=$PATH:/home/jsn/.local/bin
export GEM_HOME="$HOME/gems" 
export PATH="$HOME/gems/bin:$PATH"
