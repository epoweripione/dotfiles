# Dotfiles & Scripts
A set of bash, zsh, tmux, powershell, wsl, nodejs, msys2 configuration and script files.


## How to
[zsh official website](http://zsh.sourceforge.net)  
[zsh install guide](https://github.com/robbyrussell/oh-my-zsh/wiki/Installing-ZSH)  
[oh-my-zsh](https://ohmyz.sh/)

### 1. Install `curl git`

### 2. Clone to `$HOME/.dotfiles`
`source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue)`

or

`curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue | bash "$HOME/.dotfiles"`

### 3. Install `ZSH` & `Oh My ZSH`
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_installer.sh`

### 4. Set `ZSH` as your login shell
`chsh -s $(which zsh)`

### 5. Init
`${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_init.sh`

## Update
`source <(curl -fsSL --connect-timeout 5 --max-time 15 https://git.io/JPSue) && ${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/zsh/zsh_upgrade_all_packages.sh`
