#!/bin/bash

source ./common.sh

ln -s /home/clintjedwards/Documents/dotfiles/i3/config /home/clintjedwards/.config/i3/config
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3 config")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/scripts /home/clintjedwards/.config/i3/scripts
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3 scripts dir")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/i3blocks.conf /home/clintjedwards/.config/i3/i3blocks.conf
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3blocks.conf")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/lock.png /home/clintjedwards/.config/i3/lock.png
printf "\e[34m├ \e[0m %s%s\n" "$(success "lock.png")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/lock.sh /home/clintjedwards/.config/i3/lock.sh
printf "\e[34m├ \e[0m %s%s\n" "$(success "lock.sh")"

ln -s /home/clintjedwards/Documents/dotfiles/files/alacritty.toml /home/clintjedwards/.alacritty.toml
printf "\e[34m├ \e[0m %s%s\n" "$(success "alacritty.toml")"

ln -s /home/clintjedwards/Documents/dotfiles/files/gitconfig /home/clintjedwards/.gitconfig
printf "\e[34m├ \e[0m %s%s\n" "$(success "gitconfig")"

ln -s /home/clintjedwards/Documents/dotfiles/files/gpg-agent.conf /home/clintjedwards/.gnupg/gpg-agent.conf
printf "\e[34m├ \e[0m %s%s\n" "$(success "gpg-agent.conf")"

ln -s /home/clintjedwards/Documents/dotfiles/files/commit.sh /home/clintjedwards/.bin/commit.sh
printf "\e[34m├ \e[0m %s%s\n" "$(success "commit.sh")"

ln -s /home/clintjedwards/Documents/dotfiles/files/editor/helix /home/clintjedwards/.config/helix
printf "\e[34m├ \e[0m %s%s\n" "$(success "helix")"

rm -rf /home/clintjedwards/.config/hypr
ln -s /home/clintjedwards/Documents/dotfiles/files/hypr /home/clintjedwards/.config/hypr
printf "\e[34m├ \e[0m %s%s\n" "$(success "hyperland")"

ln -s /home/clintjedwards/Documents/dotfiles/files/waybar /home/clintjedwards/.config/waybar
printf "\e[34m├ \e[0m %s%s\n" "$(success "waybar")"

rm /home/clintjedwards/.zshrc
ln -s /home/clintjedwards/Documents/dotfiles/files/zsh/zshrc /home/clintjedwards/.zshrc
printf "\e[34m├ \e[0m %s%s\n" "$(success "zshrc")"

ln -s /home/clintjedwards/Documents/dotfiles/files/zsh/gitstatus /home/clintjedwards/.oh-my-zsh/plugins/gitstatus
printf "\e[34m├ \e[0m %s%s\n" "$(success "gitstatus")"

ln -s /home/clintjedwards/Documents/dotfiles/files/wildcard.clintjedwards.home.crt /home/clintjedwards/wildcard.clintjedwards.home.crt
printf "\e[34m├ \e[0m %s%s\n" "$(success "home cert")"
sudo trust anchor --store ~/wildcard.clintjedwards.home.crt
