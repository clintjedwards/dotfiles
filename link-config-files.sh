#!/bin/bash

source ./common.sh

#!/bin/bash

source ./common.sh

# Function to create symbolic links, removing any existing file or symlink
create_symlink() {
  local target=$1
  local link=$2
  local name=$3

  if [ -e "$link" ] || [ -L "$link" ]; then
    rm -rf "$link"
  fi

  ln -s "$target" "$link"
  printf "\e[34m├ \e[0m %s%s\n" "$(success "$name")"
}

# Alacritty
create_symlink "/home/clintjedwards/Documents/dotfiles/files/alacritty.toml" "/home/clintjedwards/.alacritty.toml" "alacritty.toml"

# Git config
create_symlink "/home/clintjedwards/Documents/dotfiles/files/gitconfig" "/home/clintjedwards/.gitconfig" "gitconfig"

# GPG Agent
create_symlink "/home/clintjedwards/Documents/dotfiles/files/gpg-agent.conf" "/home/clintjedwards/.gnupg/gpg-agent.conf" "gpg-agent.conf"

# Commit script
create_symlink "/home/clintjedwards/Documents/dotfiles/files/commit.sh" "/home/clintjedwards/.bin/commit.sh" "commit.sh"

# Helix config
create_symlink "/home/clintjedwards/Documents/dotfiles/files/editor/helix" "/home/clintjedwards/.config/helix" "helix"

# Hyperland config
create_symlink "/home/clintjedwards/Documents/dotfiles/files/hypr" "/home/clintjedwards/.config/hypr" "hyperland"

# Waybar config
create_symlink "/home/clintjedwards/Documents/dotfiles/files/waybar" "/home/clintjedwards/.config/waybar" "waybar"

# Zsh config
create_symlink "/home/clintjedwards/Documents/dotfiles/files/zsh/zshrc" "/home/clintjedwards/.zshrc" "zshrc"

# Gitstatus plugin
create_symlink "/home/clintjedwards/Documents/dotfiles/files/zsh/gitstatus" "/home/clintjedwards/.oh-my-zsh/plugins/gitstatus" "gitstatus"

# Home certificate
create_symlink "/home/clintjedwards/Documents/dotfiles/files/wildcard.clintjedwards.home.crt" "/home/clintjedwards/wildcard.clintjedwards.home.crt" "home cert"

# Store home certificate as trust anchor
sudo trust anchor --store ~/wildcard.clintjedwards.home.crt
