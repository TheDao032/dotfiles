#!/bin/bash

sudo apt-get update && sudo apt-get upgrade -y
sudo apt install zsh -y

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
