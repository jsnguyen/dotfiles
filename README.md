# Dotfiles

## Mac Stuff
Install Xcode command line tools, Rosetta

## Brew Install 

``` sh
brew install  git alacritty vim rust juliaup pyenv tmux curl htop ffmpeg imagemagick fish eza zoxide fzf cyberduck vlc zoom zotero spotify vnc-viewer rectangle llvm libomp nvim node
```

## pip install 

``` sh
pip install numpy scipy astropy matplotlib jupyter jupyterlab
```

## Colorthemes 
snazzy
gruvbox
dracula
ayu

## Applications 

Lightroom
Adobe Creative Cloud
Microsoft Suite # use UCSD login
FastRawViewer
tailscale

## Other Commands 

``` sh
brew install --cask keepassxc 
brew install --cask discord
brew install --cask xquartz
brew install --cask saoimageds9
brew install --cask tigervnc-viewer
brew install --cask visual-studio-code
brew install --cask notion
brew install --cask inkscape
brew install --cask sioyek
brew install --cask spotify
brew install --cask slack
brew install --cask zotero
brew install --cask rectangle
brew install --cask google-drive
brew install --cask mullvadvpn
brew install --cask slack
brew install --cask logi-options-plus
brew install --cask notion-calendar
brew install --cask cyberduck
brew install --cask whatsapp
brew install --cask chatgpt
brew install --cask zoom
brew install --cask stellarium
```

## Other brew install

``` sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew tap homebrew/cask-fonts
brew install font-iosevka
brew install font-ibm-plex
```

## Installing pyenv

For pyenv on Rocky Linux, you need these 
yum install bzip2-devel ncurses-devel libffi-devel readline-devel sqlite-devel

## pyenv on Linux

curl https://pyenv.run | bash

## pyenv stuff

``` sh
pyenv install -l
pyenv install 3.14
pyenv global 3.14
```

## Installing juliaup without brew

``` sh
curl -fsSL https://install.julialang.org | sh
juliaup add beta
juliaup default beta
```

## SSH key generation

``` sh
ssh-keygen -t ed25519 -C ""
ssh-copy-id -i ~/.ssh/mykey user@host
```

## Alacritty

configuration dotfile needs to go in ~/.config/alacritty/alacritty.toml

## Fish

make sure you add the line /usr/local/bin/fish to /etc/shells

``` sh
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
fish_add_path /opt/homebrew/bin
chsh -s $(which fish)
```

## Zotero

install BetterBibtex for citations, ZotFile for sending data to tablet

## UV

``` sh
curl -LsSf https://astral.sh/uv/install.sh | sh
```
