

rice:
	sudo apt update

	#i3 window manager
	sudo apt install i3 -y

	#wallpaper loader
	sudo apt install feh -y

	#install font awesome
	wget https://github.com/FortAwesome/Font-Awesome/releases/download/5.2.0/fontawesome-free-5.2.0-desktop.zip

	#install System SF font
	wget https://github.com/supermarin/YosemiteSanFranciscoFont/archive/master.zip

	#copy both to the ~/.fonts folder

	#install lxapperance
	sudo apt install lxapperance -y

	#install GTX themes and icon themes

	#install application launcher
	sudo apt install rofi -y

	#install window opacity manager
	sudo apt install compton -y

	#download lock icon
	wget https://www.iconfinder.com/icons/1055033/download/png/512
	#download lock tools
	sudo apt install scrot -y
	sudo apt install imagemagick -y
	#move lock script to proper folder

	#install better i3status bar
	sudo apt isntall i3blocks
