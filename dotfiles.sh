#!/bin/bash

# Create needed symlinks

FOLDERS=(bspwm dunst gtk-3.0 kitty nvim picom pipewire polybar ranger rofi scripts sxhkd themes wallpapers wireplumber)

for folder in ${FOLDERS[@]}; do
  ln -sn $HOME/.dotfiles/$folder $HOME/.config/$folder
done


HOME_FILES=(.zshrc .zshenv .XCompose)

for home_file in ${HOME_FILES[@]}; do
  ln -sn $HOME/.dotfiles/$home_file $HOME/$home_file
done

CONFIG_FILES=(starship.toml)

for config_file in ${CONFIG_FILES[@]}; do
  ln -sn $HOME/.dotfiles/$config_file $HOME/.config/$config_file
done
