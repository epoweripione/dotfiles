#!/usr/bin/env bash

# Load custom functions
if type 'colorEcho' 2>/dev/null | grep -q 'function'; then
    :
else
    if [[ -s "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh" ]]; then
        source "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh"
    else
        echo "${MY_SHELL_SCRIPTS:-$HOME/.dotfiles}/custom_functions.sh does not exist!"
        exit 0
    fi
fi


## Run .sh file by double clicking in XFCE
## make sure you have the proper #!/bin/bash/ shebang
## right click file-> permissions-> check "allow to run as program"
## in terminal run:
# xfconf-query --channel thunar --property /misc-exec-shell-scripts-by-default --create --type bool --set true


## launcher command to run .sh file
# /home/<username>/.dotfiles/vm/start_qemu_vm.sh [name_of_vm]
# xfce4-terminal -x /home/<username>/.dotfiles/vm/start_qemu_vm.sh [name_of_vm]


## Allow members of the group sudo to execute any command without password prompt
## sudo rm /etc/sudoers.d/10-installer
## echo "%wheel ALL=(ALL) ALL" | sudo tee "/etc/sudoers.d/10-installer" >/dev/null
# CommandList=(
#     virsh
#     virt-viewer
# )
# for TargetCommand in "${CommandList[@]}"; do
#     [[ -x "$(command -v "${TargetCommand}")" ]] && \
#         echo "$(whoami) ALL=(ALL) NOPASSWD: $(which "${TargetCommand}")" \
#             | sudo tee "/etc/sudoers.d/nopasswd_$(whoami)_${TargetCommand}" >/dev/null
# done


VM_NAME=${1:-""}
if [[ -z "${VM_NAME}" ]]; then
    colorEcho "${RED}Virtual machine name can't empty!"
    exit 1
fi

# colorEcho "${BLUE}Running ${FUCHSIA}network${BLUE}..."
## sudo virsh net-autostart default
# sudo virsh net-start default

if ! sudo virsh domstate "${VM_NAME}" 2>/dev/null | grep -i 'running' >/dev/null 2>&1; then
    colorEcho "${BLUE}Running virtual machine ${FUCHSIA}${VM_NAME}${BLUE}..."
    sudo virsh start "${VM_NAME}"
    # sleep 5
fi

sudo virt-viewer --domain-name "${VM_NAME}" --full-screen

# How to login automatically to Windows 11
# https://answers.microsoft.com/en-us/windows/forum/all/how-to-login-automatically-to-windows-11/c0e9301e-392e-445a-a5cb-f44d00289715
# 1. Windows+I > Accounts > Sign-in options:
# turn Off the For improved security, only allow Windows Hello sign-in for Microsoft accounts on this device option.
# If this option is greyed out, you can sign out and then sign in back to change it.
# 2. Windows + R > netplwiz or Windows + R > control userpasswords2
# uncheck option > Users must enter a user name and password to use this computer
