#!/bin/bash

source ./common.sh

read -s -p "Enter the decrypt password: " decrypt_password
echo

headline "Installing SSH and GPG Key"

cp /mnt/safe/software/id_rsa.gpg  .
gpg --output id_rsa --decrypt --passphrase="$decrypt_password" --yes --batch id_rsa.gpg
mv id_rsa ~/Documents/clintjedwards/.ssh/id_rsa
sudo chmod 600 ~/Documents/clintjedwards/.ssh/id_rsa
rm ./id_rsa.gpg

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed SSH Key")"

cp /mnt/safe/software/gpg.key.gpg  .
gpg --output gpg.key --decrypt --passphrase="$decrypt_password" --yes --batch gpg.key.gpg
gpg --import gpg.key
rm ./gpg.key
rm ./gpg.key.gpg

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed GPG Key")"
