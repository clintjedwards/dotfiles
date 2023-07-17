#!/bin/bash

# Meant to be run on an arch based system with yay and sudo already installed

# Prompt for password
read -s -p "Enter the mount password: " mount_password
echo

read -s -p "Enter the decrypt password: " decrypt_password
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

headline "Starting new OS init script"

echo -e "\e[34m┊\e[0m"

headline "Updating system"

sudo pacman -Syu --noconfirm > /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success "System Updated")"

headline "Installing base packages"

pacman -S --needed git base-devel --noconfirm &> /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success git installed)"
printf "\e[34m├ \e[0m %s%s\n" "$(success base-devel installed)"

headline "Installing packages"

## Insert packages here.
packages=(
    "acpi"
    "alacritty"
    "autorandr"
    "bat"
    "btop"
    "cifs-utils"
    "code"
    "duf"
    "exa"
    "flameshot"
    "fzf"
    "gdu"
    "git"
    "google-chrome"
    "i3"
    "i3blocks"
    "i3lock"
    "lxappearance"
    "networkmanager"
    "nerd-fonts-complete"
    "npm"
    "obsidian"
    "pavucontrol"
    "ripgrep"
    "rofi"
    "rustup"
    "sysstat" # for i3block cpu_usage
    "vim"
    "vlc"
    "wget"
    "xfce4-power-manager"
    "zsh"
)

for package_name in "${packages[@]}"; do
    # Check if package is already installed
    if yay -Qs "$package_name" > /dev/null; then
        :
    else
        # Package not found, attempt to install it
        yay -S --noconfirm "$package_name" &> /dev/null

        # Check if installation was successful
        if yay -Qs "$package_name" > /dev/null; then
            printf "\e[34m├ \e[0m %s%s\n" "$(success "$package_name" installed)"
        else
            printf "\e[34m├ \e[0m %s%s\n" "$(failed "$package_name" couldn\'t be installed)"
        fi
    fi
done

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

headline "Installing ZSH"

sudo chsh -s "/usr/sbin/zsh" "clintjedwards"

printf "\e[34m├ \e[0m %s%s\n" "$(success "Changed shell to zsh")"

sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O - &>/dev/null)" "" --unattended &> /dev/null

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed Oh-My-ZSH")"

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

headline "Linking configuration files"

mkdir ~/.bin

cd ~/Documents
git clone https://github.com/clintjedwards/dotfiles &> /dev/null

ln -s /home/clintjedwards/Documents/dotfiles/i3/config /home/clintjedwards/.config/i3/config
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3 config")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/scripts /home/clintjedwards/.config/i3/scripts
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3 scripts dir")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/i3blocks.conf /home/clintjedwards/.config/i3/i3blocks.conf
printf "\e[34m├ \e[0m %s%s\n" "$(success "i3blocks.conf")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/lock.png /home/clintjedwards/.config/i3/lock.png
printf "\e[34m├ \e[0m %s%s\n" "$(success "lock.png")"

ln -s /home/clintjedwards/Documents/dotfiles/i3/lock.sh /home/clintjedwards/.config/i3/lock.sh
printf "\e[34m├ \e[0m %s%s\n" "$(success "lock.sh")"

ln -s /home/clintjedwards/Documents/dotfiles/.alacritty.yml /home/clintjedwards/.alacritty.yml
printf "\e[34m├ \e[0m %s%s\n" "$(success "alacritty.yml")"

ln -s /home/clintjedwards/Documents/dotfiles/.Xresources /home/clintjedwards/.Xresources
printf "\e[34m├ \e[0m %s%s\n" "$(success ".Xresources")"

ln -s /home/clintjedwards/Documents/dotfiles/.gitconfig /home/clintjedwards/.gitconfig
printf "\e[34m├ \e[0m %s%s\n" "$(success ".gitconfig")"

rm /home/clintjedwards/.zshrc
ln -s /home/clintjedwards/Documents/dotfiles/zsh/.zshrc /home/clintjedwards/.zshrc
printf "\e[34m├ \e[0m %s%s\n" "$(success ".zshrc")"

ln -s /home/clintjedwards/Documents/dotfiles/zsh/gitstatus /home/clintjedwards/.oh-my-zsh/plugins/gitstatus
printf "\e[34m├ \e[0m %s%s\n" "$(success "gitstatus")"

sudo ln -s /home/clintjedwards/Documents/dotfiles/30-touchpad.conf /usr/share/X11/xorg.conf.d/30-touchpad.conf
printf "\e[34m├ \e[0m %s%s\n" "$(success "30-touchpad.conf")"

ln -s /home/clintjedwards/Documents/dotfiles/vscode/settings.json /home/clintjedwards/.config/Code/User/settings.json
printf "\e[34m├ \e[0m %s%s\n" "$(success "vscode settings.json")"

ln -s /home/clintjedwards/Documents/dotfiles/wildcard.clintjedwards.home.crt /home/clintjedwards/wildcard.clintjedwards.home.crt
printf "\e[34m├ \e[0m %s%s\n" "$(success "home cert")"
sudo trust anchor --store ~/wildcard.clintjedwards.home.crt


headline "Installing node"
mkdir -p ~/.bin/node
npm config set prefix /home/clintjedwards/.bin/node

printf "\e[34m├ \e[0m %s%s\n" "$(success "Installed Node JS")"

headline "Installing fonts"
mkdir -p ~/.local/share/fonts
cp /home/clintjedwards/Documents/dotfiles/.fonts/* ~/.local/share/fonts
fc-cache

headline "Configuring VSCode"

## Insert packages here.
packages=(
    "rust-lang.rust-analyzer"
    "golang.go"
    "wayou.vscode-todo-highlight"
    "bradlc.vscode-tailwindcss"
    "esbenp.prettier-vscode"
    "svelte.svelte-vscode"
    "xaver.clang-format"
    "pkief.material-icon-theme"
    "zxh404.vscode-proto3"
    "clintjedwards.eastwood"
    "bufbuild.vscode-buf"
)

wget --no-verbose https://github.com/Macchina-CLI/macchina/releases/download/v6.1.8/macchina-linux-x86_64
chmod +x ./macchina-linux-x86_64
mv ./macchina-linux-x86_64 ~/.bin/macchina
echo ""
