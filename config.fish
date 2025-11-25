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
alias cdl='cd ~/landing'
alias cdp='cd ~/landing/projects'
alias cda='cd ~/landing/analyses'
alias cdd='cd ~/landing/data'
alias det='tmux detach -P'
alias ds9='/Applications/SAOImageDS9.app/Contents/MacOS/ds9'
alias ds9lock='/Applications/SAOImageDS9.app/Contents/MacOS/ds9 -lock frame image -colorbar lock yes'
alias sjl='~/landing/scripts/start_tmux_jupyter_lab.sh'
alias sm='~/landing/scripts/start_tmux_marimo.sh'
alias sp='~/landing/scripts/start_tmux_pluto.sh'

alias vnctunnel='~/landing/scripts/vnc_tunnel_decaf.sh'
alias backup='~/landing/scripts/decaf_backup.sh'
alias vncviewer='/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer'

if status is-interactive
    if [ "$TERM_PROGRAM" != "vscode" ] && [ "$TERM_PROGRAM" != "zed" ];
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

function ll --wraps ls --description "List contents of directory using long format -haltr"
    ls -haltr $argv
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

set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY YES

# pyenv stuff
if command -v pyenv 1>/dev/null 2>&1;
      eval "$(pyenv init -)"
end

# Added by Antigravity
fish_add_path /Users/jsn/.antigravity/antigravity/bin

zoxide init fish | source
