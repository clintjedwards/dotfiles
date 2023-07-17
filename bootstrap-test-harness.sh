pacman -Syu
pacman -S wget
pacman -S sudo
wget https://github.com/Jguer/yay/releases/download/v12.1.0/yay_12.1.0_x86_64.tar.gz
tar -xvf yay_12.1.0_x86_64.tar.gz
mv yay_12.1.0_x86_64/yay /usr/bin
chmod +x /usr/bin/yay
useradd -m "clintjedwards"
mkdir /home/clintjedwards/Documents
