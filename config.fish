function fish_greeting
end

if status is-interactive
end

function fish_prompt -d "Write out the prompt"
    printf '%s<%s %s%s%s %s>%s ' (set_color green) (set_color normal) (set_color $fish_color_cwd) (prompt_pwd -D 100) (set_color normal) (set_color green) (set_color normal)
end

alias ls='ls --color'
alias cdl='cd ~/landing'
alias cdp='cd ~/landing/projects'
alias cda='cd ~/landing/analyses'
alias cdd='cd ~/landing/data'
alias esh='tmux detach -P'
alias ds9='/Applications/SAOImageDS9.app/Contents/MacOS/ds9'
alias ds9lock='/Applications/SAOImageDS9.app/Contents/MacOS/ds9 -lock frame image -colorbar lock yes'
alias sjl='~/landing/scripts/start_tmux_jupyter_lab.sh'

alias sshdquick='ssh -Y -p 12392 jsn@dquick.local'
alias sshdecaf='ssh -Y jsn@decaf.ucsd.edu'
alias sshtrenta='ssh -Y jsn@trenta.ucsd.edu'
alias vnctunnel='~/landing/scripts/vnc_tunnel_decaf.sh'

# pyenv stuff
if command -v pyenv 1>/dev/null 2>&1;
      eval "$(pyenv init -)"
end

# tmux on ssh
if [ "$TERM_PROGRAM" != "vscode" ];
    if [ -z "$TMUX" ] && [ -n "$SSH_CONNECTION" ];
        tmux attach-session -t ssh_tmux || tmux new-session -s ssh_tmux
    else
        # always run tmux
        set DEFAULT_TMUX_NAME "dtmux"
        if [ -z "$TMUX" ];
            tmux attach-session -t {$DEFAULT_TMUX_NAME} || tmux new-session -s {$DEFAULT_TMUX_NAME}
        end
    end
end
