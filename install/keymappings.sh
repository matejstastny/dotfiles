#!/bin/bash

set -e

sudo dnf copr enable alternateved/keyd
sudo dnf install keyd

sudo mkdir -p /etc/keyd
sudo ln -s "$HOME/dotfiles/configs/system/keyd.conf" /etc/keyd/default.conf
sudo systemctl enable --now keyd
