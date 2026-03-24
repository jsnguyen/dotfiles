function fish_greeting
end

function fish_prompt -d "Write out the prompt"
    if not set -q TMUX
        set_color yellow # Choose your preferred color
        echo -n "$(prompt_hostname) |"
        set_color normal
        echo -n ' '
    end
    printf '%s%s%s %s>%s ' (set_color $fish_color_cwd) (prompt_pwd -D 100) (set_color normal) (set_color green) (set_color normal)
end

alias ls='eza'
alias ll='eza -halr'

alias cd='z'

alias cdl='cd ~/landing'
alias det='tmux detach -P'
alias att='~/.scripts/reattach_dtmux.sh'

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
        case '*'
            echo "unknown shortcut: $argv[1]"
    end
end


alias vnctunnel='~/.scripts/vnc_tunnel_decaf.sh'
alias backup='~/.scripts/decaf_backup.sh'

set skip_programs vscode zed codex

if status is-interactive
    if not contains -- $TERM_PROGRAM $skip_programs && not set -q CODEX_SHELL
        if [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ];
            tmux new-session -A -s ssh_tmux
        else
            # always run tmux
            set DEFAULT_TMUX_NAME "dtmux"
            if [ -z "$TMUX" ];
                tmux attach-session -t {$DEFAULT_TMUX_NAME} || tmux new-session -s {$DEFAULT_TMUX_NAME}
            end
        end
    end
end

function ssh --wraps ssh --description 'Auto-detach tmux before ssh, re-attach after'
    if set -q TMUX
        tmux detach -E "ssh $argv; tmux new-session -A -s dtmux"
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
      eval "$(pyenv init -)"
      eval "$(pyenv virtualenv-init -)"
end

set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES

zoxide init fish | source
fzf --fish | source
