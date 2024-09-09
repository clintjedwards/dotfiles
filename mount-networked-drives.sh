#!/bin/bash

# Prompt for password
read -s -p "Enter the mount password: " mount_password
echo

source ./common.sh

# Mount NAS so we can get private files.

headline "Setup NAS connection"

sudo mkdir /mnt/safe &> /dev/null
sudo mkdir /mnt/media &> /dev/null

# Only mount if we it doesn't already have this line
if ! grep -qF "//10.0.1.9/safe             /mnt/safe     cifs   user=home,pass=$mount_password 0 0" /etc/fstab; then
    echo "//10.0.1.9/safe             /mnt/safe     cifs   user=home,pass=$mount_password 0 0" | sudo tee -a /etc/fstab &> /dev/null
else
    :
fi

if ! grep -qF "//10.0.1.9/media            /mnt/media    cifs   user=home,pass=$mount_password 0 0" /etc/fstab; then
    echo "//10.0.1.9/media            /mnt/media    cifs   user=home,pass=$mount_password 0 0" | sudo tee -a /etc/fstab &> /dev/null
else
    :
fi

sudo mount -a
printf "\e[34m├ \e[0m %s%s\n" "$(success 'mounted /mnt/safe to //10.0.1.9/safe')"
printf "\e[34m├ \e[0m %s%s\n" "$(success 'mounted /mnt/media to //10.0.1.9/media')"

sudo systemctl daemon-reload

