#Setup for Ubuntu 19

#TODO: Actually finish this next time I wipe my computer
#TODO: Set up makefile requirement chains
#TODO: Set up laptop and desktop seperate installs

init:
	mkdir -p ~/Documents
	git clone https://github.com/clintjedwards/dotfiles.git ~/Downloads/dotfiles

default-packages:
	sudo apt install vim curl git fonts-font-awesome -y

i3wm:
	sudo apt install i3 xbacklight -y

lockscreen:
	sudo apt install compton feh scrot imagemagick

vscode:
	snap install code --classic

i3blocks:
	sudo apt install i3blocks -y

github:
	# Set up keys, gpg, config etc

# gitstatus is a custom prompt that remains minimal while allowing you to keep track of the status of your git workspace
# Requires oh-my-zsh
gitstatus:
	ln -s ~/Documents/dotfiles/zsh/gitstatus ~/.oh-my-zsh/plugins/gitstatus

# turn off middle and right click for lenovo touchpads
# This needs to go into the startup scripts somehow so its not implemented
# correctly yet
touchpad-map:
	/bin/bash -c "sleep 15 && xinput set-button-map 11 1 1 1 4 5 6 7"
