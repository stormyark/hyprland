# My Dotfiles

This directory contains the dotfiles for my arch hyprland setup

## Requirements

Ensure you have the following installed on your system

**Git**
```
sudo pacman -S git
```

**Stow**
```
sudo pacman -S stow
```

## Installation

clone the repo and use stow to create symlinks:
```
git clone https://github.com/stormyark/end4-dotfiles dotfiles
cd dotfiles
stow --adopt .
```

## Install Packages
```
sudo pacman -S --needed - < pkglist.txt
```
