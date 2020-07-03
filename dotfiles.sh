#!/bin/bash

# Create needed symlinks

FOLDERS=(dunst i3 kitty picom polybar ranger rofi wallpaper xres nvim/config scripts)

for folder in ${FOLDERS[@]}; do
  ln -sn $HOME/.dotfiles/$folder $HOME/.config/$folder
done

ln -sn $HOME/.dotfiles/nvim/init.vim $HOME/.config/nvim/init.vim

HOME_FILES=(.zshrc .zshenv)

for home_file in ${HOME_FILES[@]}; do
  ln -sn $HOME/.dotfiles/$home_file $HOME/$home_file
done

CONFIG_FILES=(starship.toml)

for config_file in ${CONFIG_FILES[@]}; do
  ln -sn $HOME/.dotfiles/$config_file $HOME/.config/$config_file
done
