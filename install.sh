#!/usr/bin/env bash
#
# Set up a fresh Arch install the way I like it: packages, fonts, config links,
# and services. Safe to run again on a machine that's already set up.
#
# Every step has a "done" check. If the check passes the step is skipped, so a
# second run only does whatever is missing. Any real file a link would replace
# is moved to <name>.bak.<timestamp> first.
#
# Each run appends one line per step to ~/.local/state/dotfiles/install.log so
# there's a history of what ran when. Full command output for the current run
# goes to a temp log, which is printed if a step fails.
#
# Before running it, the fresh install needs:
#   - A normal user with sudo. archinstall does this when you add a user and
#     give them sudo; a bare pacstrap of base doesn't even include sudo.
#   - NetworkManager as the network setup (archinstall's "NetworkManager"
#     option). This script enables it, and a second network manager like iwd
#     or systemd-networkd would fight with it after the reboot.
#   - The headers for every installed kernel, e.g. linux-zen-headers for
#     linux-zen. The nvidia driver is built against them, and without them it
#     doesn't build. nvidia-utils also blacklists nouveau, so the card ends up
#     with no driver and X won't start. Only matters on machines with nvidia.
#   - git, to clone this repo.
#
# Run as your normal user (not root) from anywhere:
#   git clone https://github.com/clintjedwards/dotfiles ~/Documents/dotfiles
#   ~/Documents/dotfiles/install.sh
#
# If a step fails (usually an AUR build), fix it and run the script again; it
# picks up where it left off. Reboot only after a clean run, because the
# display manager is enabled late. Rebooting before that gives you a plain
# text login instead of ly and i3.
#
# Other modes, neither of which changes anything:
#   install.sh --check   show which steps are done and which would run
#   install.sh --diff    list installed packages that aren't tracked below

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="$(mktemp -t dotfiles-install.XXXXXX.log)"
HISTORY="$HOME/.local/state/dotfiles/install.log"

##############
# Packages   #
##############

pacman_packages=(
    # System
    base-devel git openssh rsync wget unzip zip man-db less tree strace
    net-tools cifs-utils nfs-utils dosfstools gptfdisk mdadm zram-generator
    cpupower pacman-contrib networkmanager cups system-config-printer acpi

    # Desktop: X, i3, and the things the i3 config calls
    xorg-server xorg-xinit xorg-xrandr xorg-xauth xorg-xev xorg-xset ly
    i3-wm i3blocks i3lock xss-lock dunst rofi autorandr arandr
    flameshot xclip imagemagick lxappearance thunar sysstat libnotify

    # Audio and bluetooth
    pipewire pipewire-alsa pipewire-pulse wireplumber gst-plugin-pipewire
    libpulse pavucontrol bluez bluez-utils blueman

    # Graphics
    nvidia-open-dkms nvidia-utils nvidia-settings mesa-utils

    # Fonts
    ttf-inconsolata ttf-dejavu ttf-meslo-nerd woff2-font-awesome

    # Shell and CLI tools
    zsh starship fzf eza bat ripgrep duf gdu htop doggo xh jq yazi vim

    # Apps
    ghostty firefox obsidian signal-desktop mpv gimp inkscape
    obs-studio openscad yt-dlp flatpak

    # Development
    go gopls rustup rust-analyzer npm typescript-language-server
    bash-language-server marksman dprint typst typstyle hurl tidy github-cli
    docker docker-buildx lazydocker terraform ansible-core aws-cli-v2
    python-pip python-tinycss2 websocat vhs gram musl

    # Keyboards and microcontrollers
    qmk avrdude avr-binutils avr-libc dfu-programmer dfu-util
    arm-none-eabi-binutils arm-none-eabi-gcc arm-none-eabi-newlib
    riscv64-elf-binutils riscv64-elf-gcc riscv64-elf-newlib

    # Virtual machines
    qemu-base libvirt virt-manager edk2-ovmf dnsmasq iptables

    # Local LLM, used by sync-dotdocs to write commit messages. The cuda
    # build is for the desktop's nvidia card.
    ollama-cuda
)

aur_packages=(
    claude-code aseprite brother-hll2340dw ebgaramond-otf mpls-git
    proton-ge-custom-bin rpfm-bin scooter terraform-ls vial-appimage
    arch-manwarn
)

flatpak_apps=(
    com.discordapp.Discord
    com.bambulab.BambuStudio
)

# "path in this repo:where it should live"
links=(
    "files/zsh/zshrc:$HOME/.zshrc"
    "files/gitconfig:$HOME/.gitconfig"
    "files/gpg-agent.conf:$HOME/.gnupg/gpg-agent.conf"
    "files/starship.toml:$HOME/.config/starship.toml"
    "files/ghostty.config:$HOME/.config/ghostty/config"
    "files/eastwood_theme.ghostty:$HOME/.config/ghostty/eastwood.theme"
    "files/editor/helix:$HOME/.config/helix"
    "files/flameshot.ini:$HOME/.config/flameshot/flameshot.ini"
    # Global agent instructions. Claude Code only reads AGENTS.md when no
    # CLAUDE.md exists in the working dir or above, so a project with its own
    # CLAUDE.md would skip ~/AGENTS.md. ~/.claude/CLAUDE.md always loads, so it
    # just imports AGENTS.md to make sure Claude sees it everywhere.
    "files/AGENTS.md:$HOME/AGENTS.md"
    "files/claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    "files/toggle-office-lights:$HOME/.bin/toggle-office-lights"
    "git-permalink:$HOME/.bin/git-permalink"
    # Finds sampler.lua and its list of folders through this link, so mpv's
    # own config isn't touched.
    "files/mpv-sampler/mpv-sampler:$HOME/.bin/mpv-sampler"
    "files/upload-to-weow:$HOME/.bin/upload-to-weow"
    "files/mpv/upload-to-weow.lua:$HOME/.config/mpv/scripts/upload-to-weow.lua"
    "i3:$HOME/.config/i3"
    "i3/dunstrc:$HOME/.config/dunst/dunstrc"
    "files/autorandr:$HOME/.config/autorandr"
)

# Things --diff shouldn't flag: the Arch installer sets these up (kernels,
# firmware, bootloader), this script installs them itself, or they get
# installed by hand per machine.
diff_ignore=(
    base linux linux-lts linux-zen linux-zen-headers linux-firmware
    amd-ucode efibootmgr dkms yay lib32-glibc

    # Installed by hand only on machines that need it, so it never lands on
    # a work computer.
    steam
)

services=(
    NetworkManager.service bluetooth.service cpupower.service
    fstrim.timer ly@tty2.service ollama.service
)

# Keep in sync with SYNC_LOCAL_MODEL in files/zsh/zshrc.
OLLAMA_MODEL="gemma4:12b"

KEYBOARD_CONF=/etc/X11/xorg.conf.d/20-keyboard-repeat.conf
HOME_CERT_LABEL='*.clintjedwards.home'
NAS_SHARES=(safe media)

##############
# Output     #
##############

changed=()
skipped=()

headline() {
    printf '\n\e[34m│ %s\e[0m\n' "$1"
}

record() {
    printf '%s  %-8s %s\n' "$(date '+%F %T')" "$1" "$2" >>"$HISTORY"
}

# step <name> <function>
#
# If <function>_done exists and succeeds, the step is already done and skipped.
# Otherwise <function> runs with its output going to the log. On failure we
# show the end of the log and stop.
#
# The step runs as a background job and we wait on it, because bash ignores
# `set -e` inside anything run as an `if` condition. Running it this way means
# a failing command in the middle of a step function actually stops that step.
step() {
    local name=$1 fn=$2

    if declare -F "${fn}_done" >/dev/null && "${fn}_done" >/dev/null 2>&1; then
        printf '\e[34m├\e[0m \e[2m✔ %s (already done)\e[0m\n' "$name"
        skipped+=("$name")
        record skipped "$name"
        return 0
    fi

    printf '\e[34m├\e[0m %s...' "$name"
    echo "==> $name" >>"$LOG"

    "$fn" >>"$LOG" 2>&1 &
    if wait $!; then
        printf '\r\e[2K\e[34m├\e[0m \e[32m✔\e[0m %s\n' "$name"
        changed+=("$name")
        record done "$name"
    else
        printf '\r\e[2K\e[34m├\e[0m \e[31m✘\e[0m %s\n\n' "$name"
        record failed "$name"
        tail -n 25 "$LOG"
        printf '\nFull log: %s\n' "$LOG"
        exit 1
    fi
}

# Like step, but only reports whether there's anything to do. Used by --check.
check_step() {
    local name=$1 fn=$2

    if ! declare -F "${fn}_done" >/dev/null; then
        printf '\e[34m├\e[0m \e[2m- %s (runs every time)\e[0m\n' "$name"
    elif "${fn}_done" >/dev/null 2>&1; then
        printf '\e[34m├\e[0m \e[32m✔\e[0m %s\n' "$name"
    else
        printf '\e[34m├\e[0m \e[33m●\e[0m %s (needs to run)\e[0m\n' "$name"
    fi
}

# List anything installed on this machine that the lists above don't know
# about, so the lists can stay in sync with what's actually in use.
diff_packages() {
    local ignored tracked
    ignored="$(printf '%s\n' "${diff_ignore[@]}" | sort)"

    tracked="$(printf '%s\n' "${pacman_packages[@]}" | sort)"
    headline "Repo packages installed but not in pacman_packages"
    comm -23 <(pacman -Qqen | sort) <(sort -u <(echo "$tracked") <(echo "$ignored")) | sed 's/^/  /'

    # -debug packages come along with AUR builds; nobody installs them on purpose.
    tracked="$(printf '%s\n' "${aur_packages[@]}" | sort)"
    headline "AUR packages installed but not in aur_packages"
    comm -23 <(pacman -Qqem | grep -v -- '-debug$' | sort) <(sort -u <(echo "$tracked") <(echo "$ignored")) | sed 's/^/  /'

    tracked="$(printf '%s\n' "${flatpak_apps[@]}" | sort)"
    headline "Flatpaks installed but not in flatpak_apps"
    comm -23 <(flatpak list --app --columns=application | sort) <(echo "$tracked") | sed 's/^/  /'
}

summary() {
    printf '\n\e[32mDone.\e[0m %d changed, %d already done.\n' "${#changed[@]}" "${#skipped[@]}"
    local name
    for name in "${changed[@]}"; do
        printf '  \e[32m+\e[0m %s\n' "$name"
    done
    printf '\nHistory of every run: %s\n' "$HISTORY"
    if [ "${#changed[@]}" -gt 0 ]; then
        echo "Log out and back in to pick up any new shell, groups, or X config."
    fi
}

##############
# Steps      #
##############
#
# Each step is a function, plus an optional <function>_done that returns 0 when
# there's nothing to do.

# The gitconfig rewrites GitHub https URLs to ssh, but on a fresh machine the
# SSH key isn't installed until the last step. Cloning without the global
# config keeps these as plain https clones that don't need a key.
clone() {
    GIT_CONFIG_GLOBAL=/dev/null git clone "$@"
}

# Ours enables multilib, for 32-bit software like steam.
install_pacman_conf_done() {
    cmp -s "$DOTFILES/files/pacman.conf" /etc/pacman.conf
}
install_pacman_conf() {
    sudo cp /etc/pacman.conf "/etc/pacman.conf.bak.$(date +%s)"
    sudo install -m 644 "$DOTFILES/files/pacman.conf" /etc/pacman.conf
}

# No done check; pacman already does nothing when everything is current.
update_system() {
    sudo pacman -Syu --noconfirm
}

# pacman -T prints whichever of the given packages aren't installed.
install_packages_done() {
    [ -z "$(pacman -T "${pacman_packages[@]}")" ]
}
install_packages() {
    sudo pacman -S --needed --noconfirm "${pacman_packages[@]}"
}

install_yay_done() {
    command -v yay
}
install_yay() {
    local dir
    dir="$(mktemp -d)"
    clone --depth 1 https://aur.archlinux.org/yay-bin.git "$dir"
    (cd "$dir" && makepkg -si --noconfirm)
    rm -rf "$dir"
}

install_aur_packages_done() {
    [ -z "$(pacman -T "${aur_packages[@]}")" ]
}
install_aur_packages() {
    yay -S --needed --noconfirm "${aur_packages[@]}"
}

install_flatpaks_done() {
    local app
    for app in "${flatpak_apps[@]}"; do
        flatpak info "$app" || return 1
    done
}
install_flatpaks() {
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y --noninteractive flathub "${flatpak_apps[@]}"
}

install_fonts_done() {
    local font
    for font in "$DOTFILES"/files/fonts/*.ttf; do
        cmp -s "$font" "$HOME/.local/share/fonts/$(basename "$font")" || return 1
    done
}
install_fonts() {
    mkdir -p ~/.local/share/fonts
    cp "$DOTFILES"/files/fonts/*.ttf ~/.local/share/fonts/
    fc-cache
}

# The rofi launcher and power menu use themes from adi1090x/rofi, unmodified.
# Their setup script also installs the fonts those themes use.
install_rofi_themes_done() {
    [ -e ~/.config/rofi/config.rasi ]
}
install_rofi_themes() {
    local dir
    dir="$(mktemp -d)"
    clone --depth 1 https://github.com/adi1090x/rofi.git "$dir"
    (cd "$dir" && bash setup.sh)
    rm -rf "$dir"
}

link_configs_done() {
    local pair
    for pair in "${links[@]}"; do
        [ "$(readlink "${pair#*:}")" = "$DOTFILES/${pair%%:*}" ] || return 1
    done
}
link_configs() {
    # gpg complains if this isn't private, and mkdir -p would make it 755.
    install -d -m 700 ~/.gnupg

    local pair src dest
    for pair in "${links[@]}"; do
        src="$DOTFILES/${pair%%:*}"
        dest="${pair#*:}"

        if [ "$(readlink "$dest")" = "$src" ]; then
            continue
        fi

        mkdir -p "$(dirname "$dest")"
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            mv "$dest" "$dest.bak.$(date +%s)"
        fi
        ln -s "$src" "$dest"
        echo "linked $dest"
    done
}

# Right-click "Upload to weow" on any file in thunar. uca.xml isn't linked from
# this repo because thunar replaces the file whenever actions are edited in
# its settings, which would break the link. So the action gets added to
# whatever's already there instead. Thunar runs the command without a shell,
# so the path has to be absolute.
THUNAR_UCA="$HOME/.config/Thunar/uca.xml"
add_thunar_action_done() {
    grep -F '<unique-id>upload-to-weow</unique-id>' "$THUNAR_UCA"
}
add_thunar_action() {
    mkdir -p "$(dirname "$THUNAR_UCA")"
    if [ ! -f "$THUNAR_UCA" ]; then
        printf '<?xml version="1.0" encoding="UTF-8"?>\n<actions>\n</actions>\n' >"$THUNAR_UCA"
    fi

    local tmp
    tmp="$(mktemp "$THUNAR_UCA.XXXXXX")"
    {
        grep -v '</actions>' "$THUNAR_UCA"
        cat <<EOF
<action>
	<icon>document-send</icon>
	<name>Upload to weow</name>
	<submenu></submenu>
	<unique-id>upload-to-weow</unique-id>
	<command>$HOME/.bin/upload-to-weow %F</command>
	<description>Copy to weow on the NAS</description>
	<range></range>
	<patterns>*</patterns>
	<audio-files/>
	<image-files/>
	<other-files/>
	<text-files/>
	<video-files/>
</action>
</actions>
EOF
    } >"$tmp"
    mv "$tmp" "$THUNAR_UCA"

    # A running thunar keeps its old list of actions until it restarts.
    thunar -q || true
}

# Older copies of mpv-sampler kept their cache in ~/.vlc_durations* and put
# the lua script in mpv's own scripts folder, where its keys took over every
# mpv window. Carry the cached durations over so nothing gets probed again,
# then remove the old files. This can go once no machine has them.
SAMPLER_CACHE="$HOME/.cache/mpv-sampler"
cleanup_old_sampler_done() {
    [ ! -e ~/.vlc_durations_meta.tsv ] && [ ! -e ~/.vlc_durations.txt ] &&
        [ ! -e ~/.config/mpv/scripts/mpv_sampler.lua ]
}
cleanup_old_sampler() {
    if [ -f ~/.vlc_durations_meta.tsv ]; then
        mkdir -p "$SAMPLER_CACHE"
        # When both have the same file, the later line wins, so the new
        # cache goes second.
        cat ~/.vlc_durations_meta.tsv "$SAMPLER_CACHE/meta.tsv" 2>/dev/null >"$SAMPLER_CACHE/meta.tsv.new" || true
        mv "$SAMPLER_CACHE/meta.tsv.new" "$SAMPLER_CACHE/meta.tsv"
    fi
    rm -f ~/.vlc_durations_meta.tsv ~/.vlc_durations.txt ~/.config/mpv/scripts/mpv_sampler.lua
}

link_keyboard_conf_done() {
    [ "$(readlink "$KEYBOARD_CONF")" = "$DOTFILES/files/xorg/20-keyboard-repeat.conf" ]
}
link_keyboard_conf() {
    sudo mkdir -p "$(dirname "$KEYBOARD_CONF")"
    sudo ln -sfn "$DOTFILES/files/xorg/20-keyboard-repeat.conf" "$KEYBOARD_CONF"
}

# Trust the home network's wildcard cert so internal https sites work.
# No grep -q here; it exits early, trust gets SIGPIPE, and pipefail would read
# that as "not found".
trust_home_cert_done() {
    trust list | grep -F "label: $HOME_CERT_LABEL" >/dev/null
}
trust_home_cert() {
    sudo trust anchor --store "$DOTFILES/files/wildcard.clintjedwards.home.crt"
}

enable_services_done() {
    systemctl is-enabled "${services[@]}" && id -nG | grep -qw docker
}
enable_services() {
    sudo systemctl enable "${services[@]}"
    sudo usermod -aG docker "$USER"
}

install_zsh_plugins_done() {
    [ -d ~/.zsh-syntax-highlighting ] &&
        [ "$(getent passwd "$USER" | cut -d: -f7)" = /usr/bin/zsh ]
}
install_zsh_plugins() {
    if [ ! -d ~/.zsh-syntax-highlighting ]; then
        clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh-syntax-highlighting
    fi
    sudo chsh -s /usr/bin/zsh "$USER"
}

setup_dev_tools_done() {
    rustup default | grep -q '^stable' &&
        [ "$(npm config get prefix)" = "$HOME/.bin/node" ]
}
setup_dev_tools() {
    rustup default stable
    mkdir -p ~/.bin/node
    npm config set prefix ~/.bin/node
}

# Helix is my fork, built from source into ~/.bin/hx. It has to be cloned to
# ~/Documents/helix because the runtime link in files/editor/helix points there.
# The fork's `make install` builds, installs, and compiles grammars, but it
# doesn't download grammar sources, so fetch those first on a fresh clone.
HELIX_SRC="$HOME/Documents/helix"
install_helix_done() {
    [ -x ~/.bin/hx ] && [ -n "$(ls -A "$HELIX_SRC/runtime/grammars" 2>/dev/null)" ]
}
install_helix() {
    if [ ! -d "$HELIX_SRC" ]; then
        clone https://github.com/clintjedwards/helix.git "$HELIX_SRC"
    fi

    make -C "$HELIX_SRC" build
    HELIX_RUNTIME="$HELIX_SRC/runtime" "$HELIX_SRC/target/release/hx" --grammar fetch
    make -C "$HELIX_SRC" install
}

pull_ollama_model_done() {
    ollama list | grep -F "$OLLAMA_MODEL" >/dev/null
}
pull_ollama_model() {
    # On a fresh install the service is enabled but not started until reboot,
    # and pulling needs the server up.
    sudo systemctl start ollama.service
    local i
    for i in $(seq 30); do
        ollama list >/dev/null 2>&1 && break
        sleep 1
    done
    ollama pull "$OLLAMA_MODEL"
}

setup_nas_done() {
    local share
    for share in "${NAS_SHARES[@]}"; do
        mountpoint -q "/mnt/$share" || return 1
    done
}
setup_nas() {
    # Credentials go in a root-only file. /etc/fstab is world readable, so the
    # password shouldn't live there.
    sudo install -d -m 700 /etc/cifs
    printf 'username=home\npassword=%s\n' "$NAS_PASSWORD" |
        sudo install -m 600 /dev/stdin /etc/cifs/nas

    local share
    for share in "${NAS_SHARES[@]}"; do
        sudo mkdir -p "/mnt/$share"
        if ! grep -q "^//10.0.1.9/$share " /etc/fstab; then
            # nofail keeps boot from hanging when the NAS is down.
            echo "//10.0.1.9/$share /mnt/$share cifs credentials=/etc/cifs/nas,uid=$USER,gid=$USER,_netdev,nofail 0 0" |
                sudo tee -a /etc/fstab >/dev/null
        fi
    done

    sudo systemctl daemon-reload
    sudo mount -a
}

install_keys_done() {
    [ -f ~/.ssh/id_rsa ] && [ -n "$(gpg --list-secret-keys)" ]
}
install_keys() {
    # umask so the decrypted key is never readable by anyone else, even briefly.
    umask 077
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
        --output ~/.ssh/id_rsa --decrypt /mnt/safe/software/id_rsa.gpg 3<<<"$KEY_PASSWORD"

    gpg --batch --yes --pinentry-mode loopback --passphrase-fd 3 \
        --decrypt /mnt/safe/software/gpg.key.gpg 3<<<"$KEY_PASSWORD" |
        gpg --batch --import
}

##############
# Main       #
##############

# all_steps <runner>: runner is `step` to do the work or `check_step` to only
# report on it. Keeping one list means --check can't drift from a real run.
all_steps() {
    local run=$1

    headline "Packages"
    "$run" "Install pacman.conf" install_pacman_conf
    "$run" "Update system" update_system
    "$run" "Install packages" install_packages
    "$run" "Install yay" install_yay
    "$run" "Install AUR packages" install_aur_packages
    "$run" "Install flatpaks" install_flatpaks

    headline "Desktop"
    "$run" "Install fonts" install_fonts
    "$run" "Install rofi themes" install_rofi_themes
    "$run" "Link config files" link_configs
    "$run" "Add thunar upload action" add_thunar_action
    "$run" "Clean up old mpv sampler files" cleanup_old_sampler
    "$run" "Link keyboard repeat config" link_keyboard_conf
    "$run" "Trust home network certificate" trust_home_cert
    "$run" "Enable services" enable_services

    headline "Shell and tools"
    "$run" "Install zsh plugins" install_zsh_plugins
    "$run" "Set up rust and node" setup_dev_tools
    "$run" "Build helix" install_helix
    "$run" "Download local LLM model" pull_ollama_model

    if [ "$run" = check_step ] || [[ "$want_nas" =~ ^[Yy]$ ]]; then
        headline "NAS and keys"
        "$run" "Mount NAS" setup_nas
        "$run" "Install SSH and GPG keys" install_keys
    fi
}

if [ "$EUID" -eq 0 ]; then
    echo "Run this as your normal user, not root. It uses sudo when it needs to."
    exit 1
fi

want_nas=n

case "${1:-}" in
    --check)
        all_steps check_step
        exit 0
        ;;
    --diff)
        diff_packages
        exit 0
        ;;
    "") ;;
    *)
        echo "usage: $0 [--check | --diff]"
        echo "  (no flag)  set everything up, skipping what's already done"
        echo "  --check    show what's done and what would run, change nothing"
        echo "  --diff     list installed packages that aren't tracked here"
        exit 1
        ;;
esac

mkdir -p "$(dirname "$HISTORY")"
echo "--- run started $(date '+%F %T')" >>"$HISTORY"

# Ask everything up front so the rest can run unattended. Only ask for the NAS
# and key passwords if those steps still have work to do.
NAS_PASSWORD=""
KEY_PASSWORD=""
if ! setup_nas_done >/dev/null 2>&1 || ! install_keys_done >/dev/null 2>&1; then
    read -r -p "Mount the NAS and install SSH/GPG keys from it? [y/N] " want_nas
    if [[ "$want_nas" =~ ^[Yy]$ ]]; then
        read -r -s -p "NAS password: " NAS_PASSWORD
        echo
        read -r -s -p "Key decrypt password: " KEY_PASSWORD
        echo
    fi
fi

sudo -v
# Keep sudo from timing out during long AUR builds. Stops when we exit.
while sleep 50; do
    kill -0 "$$" 2>/dev/null || exit
    sudo -n true
done 2>/dev/null &

all_steps step
summary
