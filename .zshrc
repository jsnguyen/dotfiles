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

export PS1="[%c]: "
  alias ls='ls --color'
bindkey "^[[3~" delete-char
