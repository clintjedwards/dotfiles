#!/bin/bash

# Prompt for password
read -s -p "Enter the mount password: " mount_password
echo

# Function to prepend a green checkmark to a text message
success() {
    # Green checkmark Unicode character
    green_checkmark="\u2714"

    # Print the checkmark and the provided message
    echo -e "\033[32m$green_checkmark $1\033[0m"
}

headline() {
    # Print the checkmark and the provided message
    echo -e "\e[34m│ $1\e[0m"
}

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

