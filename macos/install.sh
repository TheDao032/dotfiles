!#/bin/zsh

brew install neovim HEAD

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
exec source $HOME/.zshrc

nvm install --lts
nvm use --lts

# Rubygems install
sudo apt-get install ruby-full rubygems -y

# Build-essential
sudo apt-get install Build-essential -y
