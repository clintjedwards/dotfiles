export ZSH="/home/${USER}/.oh-my-zsh"

plugins=(
         git-auto-fetch # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-auto-fetch
         docker # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker
         httpie # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/httpie
	 ssh-agent
	 gpg-agent
	 fzf
	 )

source $ZSH/oh-my-zsh.sh

# Load custom prompt
# A combination of miloshadzic with gitstatus in terminal colors
# https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/miloshadzic.zsh-theme
source $ZSH/plugins/gitstatus/gitstatus.prompt.zsh
PROMPT='%{$fg[cyan]%}%1~%{$reset_color%}%{$fg[red]%}|%{$reset_color%}$GITSTATUS_PROMPT%{$fg[cyan]%}⇒%{$reset_color%} '

# Add personal bin path to path
export PATH=$PATH:~/.bin

# Make go packages executable
export PATH=$PATH:~/go/bin
export PATH=$PATH:/usr/local/go/bin

# Make rust packages executable
export PATH=$PATH:~/.cargo/bin

# Make python packages executable
# export PATH=$PATH:~/.local/bin

# Make node packages executable
export PATH=$PATH:~/.bin/node/bin

# Use $EDITOR for any quick edits
export EDITOR="helix"
export VISUAL="helix"

# Use Firefox for default browser
export BROWSER="firefox"

export GPG_TTY=$(tty)

#aliases
alias ls='eza'
alias cat='bat -p'
alias grep='rg -p'
alias printscr='flameshot gui'
alias df='duf'
alias du='gdu'
alias top='htop'
alias dig='dog'
alias code='helix'

# This fixes the issue where remote servers don't have alacritty terminfo
alias ssh='TERM=xterm-256color ssh'

export FZF_DEFAULT_OPTS='--height 40% --reverse --border=none --no-separator --no-scrollbar --no-info'
