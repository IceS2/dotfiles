#!/bin/bash

# Create needed symlinks

FOLDERS=(dunst i3 kitty picom polybar ranger rofi wallpaper xres)

for folder in ${FOLDERS[@]}; do
  ln -s $HOME/.dotfiles/$folder $HOME/.config/$folder
done

ln -s $HOME/.dotfiles/nvim/init.vim $HOME/.config/nvim/init.vim

HOME_FILES=(.zshrc .zshenv)

for home_file in ${HOME_FILES[@]}; do
  ln -s $HOME/.dotfiles/$home_file $HOME/$home_file
done
