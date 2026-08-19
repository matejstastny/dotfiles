#!/usr/bin/env bash
#@ enable rpm fusion (free + nonfree) and install libheif-freeworld for HEIC/HEVC decode support

sudo dnf install -y \
	"https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
	"https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

sudo dnf install -y libheif-freeworld
