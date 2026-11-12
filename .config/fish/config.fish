function fish_greeting
end

function fish_prompt -d "Write out the prompt"
    set -l last_status $status

    if not set -q TMUX
        set_color brblack
        echo -n ":: "
        set_color normal
    end

    set_color $fish_color_cwd
    echo -n (prompt_pwd -D 100)
    set_color normal

    if test $last_status -eq 0
        set_color cyan
        echo -n " ❯ "
    else
        set_color red
        echo -n " ❯ "
    end

    set_color normal
end

alias ls='eza'
alias ll='eza -halr'

alias cd='z'

alias cdl='cd ~/landing'
alias det='tmux detach -P'
alias att='~/.scripts/reattach_atmux.sh'

alias ds9='/Applications/SAOImageDS9.app/Contents/MacOS/ds9'
alias ds9lock='/Applications/SAOImageDS9.app/Contents/MacOS/ds9 -lock frame image -colorbar lock yes'

function st
    switch $argv[1]
        case jl
            ~/.scripts/start_tmux_jupyter_lab.sh
        case m
            ~/.scripts/start_tmux_marimo.sh
        case p
            ~/.scripts/start_tmux_pluto.sh
        case d
            ~/.scripts/start_tmux_dyre.sh
        case cc
            ~/.scripts/start_tmux_claude_code.sh
        case '*'
            echo "unknown shortcut: $argv[1]"
    end
end


alias vnctunnel='~/.scripts/vnc_tunnel_decaf.sh'
alias backup='~/.scripts/decaf_backup.sh'

set skip_programs vscode zed codex

#if status is-interactive
#    if not contains -- $TERM_PROGRAM $skip_programs && not set -q CODEX_SHELL
#        if [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ];
#            tmux new-session -A -s ssh_tmux
#        else
#            # always run tmux
#            set DEFAULT_TMUX_NAME "atmux"
#            if [ -z "$TMUX" ];
#                tmux attach-session -t {$DEFAULT_TMUX_NAME} || tmux new-session -s {$DEFAULT_TMUX_NAME}
#            end
#        end
#    end
#end

function ssh --wraps ssh --description 'Auto-detach tmux before ssh, re-attach after'
    if set -q TMUX
        tmux detach -E "ssh $argv; tmux new-session -A -s atmux"
    else
        command ssh $argv
    end
end

function lg -d "lazy git add commit push"
	if [ (count $argv) -eq 1 ];
		git add .
		git commit -a -m "$argv"
		git push origin main
	else
		echo "must specify a commmit message"
	end
	return
end


set -gx PYENV_ROOT "$HOME/.pyenv"
set -gx PATH "$PYENV_ROOT/bin:$PATH"
# pyenv stuff
if command -v pyenv 1>/dev/null 2>&1;
      eval "$(pyenv init - --no-rehash fish)"
      eval "$(pyenv virtualenv-init - fish)"
end

set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES

fish_add_path /opt/homebrew/share/android-commandlinetools/platform-tools

zoxide init fish | source
fzf --fish | source

set -gx PATH "$HOME/.scripts:$PATH"

if test -f ~/.config/fish/secrets.fish
    source ~/.config/fish/secrets.fish
end

set -gx TERM xterm-256color

set -gx MCFOST_INSTALL "$HOME/landing/programs/mcfost"
set -gx MCFOST_UTILS "$MCFOST_INSTALL/utils"
set -gx MCFOST_GIT 1
set -gx MCFOST_AUTO_UPDATE 0
set -gx MCFOST_XGBOOST yes
fish_add_path "$MCFOST_INSTALL/src"
