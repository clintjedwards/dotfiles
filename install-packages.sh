#!/bin/bash

source ./common.sh

echo -e "\e[34m┊\e[0m"

headline "Updating system"

sudo pacman -Syu --noconfirm > /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success "System Updated")"

headline "Installing base packages"

pacman -S --needed git base-devel --noconfirm &> /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success git installed)"
printf "\e[34m├ \e[0m %s%s\n" "$(success base-devel installed)"

headline "Installing packages"

## Insert packages here.
packages=(
    "acpi"
    "dog"
    "eza"
    "firefox"
    "fzf"
    "gdu"
    "git"
    "less"
    "helix"
    "htop"
    "kanshi"
    "mpv"
    "npm"
    "obsidian"
    "pavucontrol"
    "ripgrep"
    "rustup"
    "sysstat"
    "ttf-font-awesome"
    "ttf-meslo-nerd"
    "waybar"
    "zsh"
)

for package_name in "${packages[@]}"; do
    # Check if package is already installed
    if yay -Qs "$package_name" > /dev/null; then
        :
    else
        # Package not found, attempt to install it
        yay -S --noconfirm "$package_name" &> /dev/null

        # Check if installation was successful
        if yay -Qs "$package_name" > /dev/null; then
            printf "\e[34m├ \e[0m %s%s\n" "$(success "$package_name" installed)"
        else
            printf "\e[34m├ \e[0m %s%s\n" "$(failed "$package_name" couldn\'t be installed)"
        fi
    fi
done

mkdir ~/.bin

headline "Installing node"
mkdir -p ~/.bin/node
npm config set prefix /home/clintjedwards/.bin/node

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed Node JS")"

