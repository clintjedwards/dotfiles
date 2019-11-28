#Setup for Ubuntu 19

#TODO: Actually finish this next time I wipe my computer
#TODO: Set up makefile requirement chains

init:
	mkdir -p ~/Documents
	git clone https://github.com/clintjedwards/dotfiles.git ~/Downloads/dotfiles

# gitstatus is a custom prompt that remains minimal while allowing you to keep track of the status of your git workspace
# Requires oh-my-zsh
gitstatus:
	ln -s ~/Documents/dotfiles/zsh/gitstatus ~/.oh-my-zsh/plugins/gitstatus

