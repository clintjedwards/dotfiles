export ZSH="/home/${USER}/.oh-my-zsh"

ZSH_THEME="miloshadzic"

plugins=(git go docker httpie zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Make go packages executable
export PATH=$PATH:~/go/bin
export PATH=$PATH:/usr/local/go/bin

# Make python packages executable
export PATH=$PATH:~/.local/bin

# Make node packages executable
export PATH="$PATH:$HOME/npm/bin"
export NODE_PATH="$NODE_PATH:$HOME/npm/lib/node_modules"

#Use VScode for any quick edits
export EDITOR="code --new-window --wait"
export VISUAL="code --new-window --wait"

