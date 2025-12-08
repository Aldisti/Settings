#!/bin/bash


# This is an installation script.

# It allows to easly set up a system with some useful commands and some
# predefined configurations, like a bashrc with many aliases for different
# tools (docker and git).
# Also, it makes available some useful scripts/programs inside
# the folder 'commands' to the system.


COMMANDS_DIR="/usr/local/bin"
ROOT_DIR="$PWD/$(dirname $0)"
CMDS_DIR="$ROOT_DIR/commands"
CONFS_DIR="$ROOT_DIR/confs"
RSC_DIR="$ROOT_DIR/resources"

main() {
    _install
    set_commands
    set_bashrc
    set_vim
    set_ghostty
    set_go
}

set_commands() {
    if ! ask_bool "Install all the commands?"; then
        return 0
    fi
	for cmd in $CMDS_DIR/*; do
		if ask_bool "Install $cmd?"; then
			sudo ln -fs $CMDS_DIR/$cmd $COMMANDS_DIR/$cmd
		fi
	done
}

set_bashrc() {
    if ! ask_bool "Set up bashrc?"; then
        return 0
    fi
    echo -e "\nexport MY_BASHRC=$CONFS_DIR/bashrc" >> $HOME/.bashrc
    echo -e "source \$MY_BASHRC\n" >> $HOME/.bashrc
}

set_vim() {
    if ! ask_bool "Set up vimrm?"; then
        return 0
    fi
    mkdir -p $HOME/.vim
    ln -fs $CONFS_DIR/vimrc $HOME/.vim/vimrc

    if ! ask_bool "Install vim plugin for indentation?"; then
        return 0
    fi
    # install vim plugin manager
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

set_go() {
    if ! ask_bool "Compile and install randmj?"; then
        return 0
    fi
    set -e
    cd $ROOT_DIR/src/random-emoji
    go run gen_emojis.go
    go build -o randmj randmj.go
    rm emojis_zipped
    cd - > /dev/null
    sudo mv $ROOT_DIR/src/random-emoji/randmj $COMMANDS_DIR/.
}

set_ghostty() {
    if ! ask_bool "Set up ghostty config?"; then
        return 0
    fi
    mkdir -p $HOME/.config/ghostty
    ln -fs $CONFS_DIR/ghostty.config $HOME/.config/ghostty/config
    ln -fs $RSC_DIR/ghostty-background.png $HOME/.config/ghostty/background.png
}

_install() {
    sudo apt update

    if ask_bool "Install some apps using apt?"; then
        sudo apt install git vim nasm gparted valgrind jq xq wl-clipboard
    fi

    for ver in 8 17 21 25; do
        if ask_bool "Install Java ${ver}?"; then
            sudo apt install openjdk-${ver}-jdk
        fi
    done

    if ask_bool "Install some apps using snap?"; then
        sudo snap install \
            code ghostty helm intellij-idea-ultimate \
            obsidian postman brave kubectl go
    fi
}

set_gnome() {
    if ! ask_bool "Customize Gnome?"; then
        return 0
    fi
    sudo apt install -y \
        gnome-shell-extensions gnome-shell-extension-manager
    echo -e "Install following extensions: aztaskbar, vitals"
    if ! ask_bool "Configure Gnome extensions?"; then
        return 0
    fi
    dconf load /org/gnome/shell/extensions/ < "$CONFS_DIR/gnome-extensions.conf"
}

# 1: message (without [Y/n])
# Usage: if ask_bool "Do you want it?"; then ...; fi
ask_bool() {
    read -p "$1 [Y/n] " res
    if [[ "$res" =~ ^[nN]$ ]]; then
        return 1 # false
    else
        return 0 # true
    fi
}

echo -e "COMMANDS_DIR: $COMMANDS_DIR"
echo -e "ROOT_DIR: $ROOT_DIR"

main
