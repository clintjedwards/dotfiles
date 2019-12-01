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

power-management:
	sudo apt install xfce4-power-manager

# gitstatus is a custom prompt that remains minimal while allowing you to keep track of the status of your git workspace
# Requires oh-my-zsh
gitstatus:
	ln -s ~/Documents/dotfiles/zsh/gitstatus ~/.oh-my-zsh/plugins/gitstatus
