#!/bin/bash

source ./common.sh

headline "Installing fonts"
mkdir -p ~/.local/share/fonts
cp /home/clintjedwards/Documents/dotfiles/files/fonts/* ~/.local/share/fonts
fc-cache
