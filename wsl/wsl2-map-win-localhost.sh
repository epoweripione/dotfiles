#!/usr/bin/env bash

# Colors
NOCOLOR='\033[0m'
RED='\033[0;31m'        # Error message
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'      # Success message
LIGHTGREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'     # Warning message
BLUE='\033[0;34m'       # Info message
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
FUCHSIA='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
DARKGRAY='\033[1;30m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

function colorEcho() {
    if [[ $# -gt 1 ]]; then
        local COLOR=$1
        echo -e "${COLOR}${@:2}${NOCOLOR}"
    else
        echo -e "${@:1}${NOCOLOR}"
    fi
}

WSL_HOST_IP=${1:-""}


## https://stackoverflow.com/questions/61002681/connecting-to-wsl2-server-via-local-network
## https://github.com/shayne/go-wsl2-host
## https://github.com/cascadium/wsl-windows-toolbar-launcher


## Enabling WSL2 Support in Firewall Settings
## https://github.com/microsoft/WSL/issues/4585
## https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule
## In the Administrative PowerShell Prompt run the following command:
# New-NetFirewallRule -DisplayName "WSL" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow
# Get-NetFirewallRule -Direction Inbound | Where-Object { $_.DisplayName -eq "WSL" }
# Remove-NetFireWallRule -DisplayName "WSL"

## https://github.com/microsoft/WSL/issues/4139#issuecomment-704142482
# Set-NetFirewallProfile Name $(Get-NetConnectionProfile).NetworkCategory DisabledInterfaceAliases $(Get-NetAdapter | Where-Object Name -match 'WSL').Name


## tunnel your port towards your IP address:
## https://github.com/microsoft/WSL/issues/5131
## In the Administrative PowerShell Prompt run the following command:
# $PhysicalAdapter = Get-NetAdapter -Name * -Physical | Where-Object Status -eq 'up' | Select-Object -ExpandProperty Name
# $PhysicalAdapterIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "$PhysicalAdapter" } | Select-Object -ExpandProperty IPv4Address

# # $PhysicalAdapterIP = (Test-Connection -IPv4 -ComputerName $env:COMPUTERNAME -Count 1).Address.toString()
# # $PhysicalAdapterIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -match 'wsl' } | Select-Object -ExpandProperty IPv4Address

# # netsh interface portproxy delete v4tov4 listenaddress=$env:PhysicalAdapterIP listenport=7890
# netsh interface portproxy add v4tov4 listenaddress=$env:PhysicalAdapterIP listenport=7890 connectaddress=localhost connectport=7890

# # netsh interface portproxy show all
# # netsh interface portproxy reset all


## https://github.com/microsoft/WSL/issues/4619#issuecomment-679000718
## http://www.dest-unreach.org/socat/
## https://github.com/StudioEtrange/socat-windows
## creating a powershell script containing:
# wsl -- socat tcp-listen:7890,fork exec:"/mnt/c/ProgramData/my-programs/socat/socat.exe - tcp\:localhost\:7890" "&"
## and add a shortcut to powershell.exe inside shell:startup folder (which you can access by Win+R and shell:startup) to run this script with -File argument.
## You can use -Command argument, too. If you experience execution policy issue, you can investigate -ExecutionPolicy argument.


## https://gist.github.com/toryano0820/6ee3bff2474cdf13e70d972da710996a
if [[ -z "${WSL_HOST_IP}" ]]; then
    if [[ -n "${GLOBAL_WSL2_HOST_IP}" ]]; then
        WSL_HOST_IP="${GLOBAL_WSL2_HOST_IP}"
    else
        WSL_HOST_IP=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}')
    fi
fi

if [[ -n "${WSL_HOST_IP}" ]]; then
    if ! grep -q "${WSL_HOST_IP} localhost" /etc/hosts 2>/dev/null; then
        colorEcho "${GREEN}  :: Mapping ${FUCHSIA}${WSL_HOST_IP}${GREEN} to ${YELLOW}localhost${GREEN}..."
        LOCALHOST_ENTRY=$(grep -v "127.0.0.1" /etc/hosts | grep "\slocalhost$")
        if [[ -n "${LOCALHOST_ENTRY}" ]]; then
            sudo sed -i "s/${LOCALHOST_ENTRY}/${WSL_HOST_IP} localhost/g" /etc/hosts
        else
            echo "${WSL_HOST_IP} localhost" | sudo tee -a /etc/hosts >/dev/null
        fi
    fi
fi

unset WSL_HOST_IP

# cat /etc/hosts
