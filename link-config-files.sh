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

ln -s /home/clintjedwards/Documents/dotfiles/.alacritty.yml /home/clintjedwards/.alacritty.yml
printf "\e[34m├ \e[0m %s%s\n" "$(success "alacritty.yml")"

ln -s /home/clintjedwards/Documents/dotfiles/.Xresources /home/clintjedwards/.Xresources
printf "\e[34m├ \e[0m %s%s\n" "$(success ".Xresources")"

ln -s /home/clintjedwards/Documents/dotfiles/.gitconfig /home/clintjedwards/.gitconfig
printf "\e[34m├ \e[0m %s%s\n" "$(success ".gitconfig")"

rm /home/clintjedwards/.zshrc
ln -s /home/clintjedwards/Documents/dotfiles/zsh/.zshrc /home/clintjedwards/.zshrc
printf "\e[34m├ \e[0m %s%s\n" "$(success ".zshrc")"

ln -s /home/clintjedwards/Documents/dotfiles/zsh/gitstatus /home/clintjedwards/.oh-my-zsh/plugins/gitstatus
printf "\e[34m├ \e[0m %s%s\n" "$(success "gitstatus")"

sudo ln -s /home/clintjedwards/Documents/dotfiles/30-touchpad.conf /usr/share/X11/xorg.conf.d/30-touchpad.conf
printf "\e[34m├ \e[0m %s%s\n" "$(success "30-touchpad.conf")"

ln -s /home/clintjedwards/Documents/dotfiles/vscode/settings.json /home/clintjedwards/.config/Code/User/settings.json
printf "\e[34m├ \e[0m %s%s\n" "$(success "vscode settings.json")"

ln -s /home/clintjedwards/Documents/dotfiles/wildcard.clintjedwards.home.crt /home/clintjedwards/wildcard.clintjedwards.home.crt
printf "\e[34m├ \e[0m %s%s\n" "$(success "home cert")"
sudo trust anchor --store ~/wildcard.clintjedwards.home.crt
