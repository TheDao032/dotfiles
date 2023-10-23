!#/bin/zsh

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Optional: exposing nvim globally.
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim

rm -r nvim.appimage

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
exec source $HOME/.zshrc

nvm install --lts
nvm use --lts

# Rubygems install
sudo apt-get install ruby-full rubygems -y

# Build-essential
sudo apt-get install Build-essential -y
