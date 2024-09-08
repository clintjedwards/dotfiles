#!/bin/bash

source ./common.sh

headline "Installing ZSH"

sudo chsh -s "/usr/sbin/zsh" "clintjedwards"

printf "\e[34m├ \e[0m %s%s\n" "$(success "Changed shell to zsh")"

sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - &>/dev/null)" "" --unattended &> /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed Oh-My-ZSH")"
