export ZSH="/home/${USER}/.oh-my-zsh"

plugins=(
         git-auto-fetch # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-auto-fetch
         docker # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker
         httpie # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/httpie
         zsh-syntax-highlighting # https://github.com/zsh-users/zsh-syntax-highlighting
        )

source $ZSH/oh-my-zsh.sh

# Load custom prompt
# A combination of miloshadzic with gitstatus in terminal colors
# https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/miloshadzic.zsh-theme
source $ZSH/plugins/gitstatus/gitstatus.prompt.zsh
PROMPT='%{$fg[cyan]%}%1~%{$reset_color%}%{$fg[red]%}|%{$reset_color%}$GITSTATUS_PROMPT%{$fg[cyan]%}⇒%{$reset_color%} '

# Make go packages executable
export PATH=$PATH:~/go/bin
export PATH=$PATH:/usr/local/go/bin

# Make python packages executable
# export PATH=$PATH:~/.local/bin

# Make node packages executable
export PATH="$PATH:$HOME/npm/bin"
export NODE_PATH="$NODE_PATH:$HOME/npm/lib/node_modules"

#Use VScode for any quick edits
export EDITOR="code --new-window --wait"
export VISUAL="code --new-window --wait"
if [ /snap/bin/kubectl ]; then source <(kubectl completion zsh); fi
