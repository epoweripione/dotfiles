#Requires -RunAsAdministrator

# pwsh.exe -Command "& {Start-Process pwsh.exe -ArgumentList '-NoProfile -Command ~\Documents\PowerShell\Scripts\wsl2-map-win-localhost.ps1 -PortForward -Ports 80,8080,443,10000,3000,5000' -WindowStyle Normal -Verb RunAs}"

Param (
    [Parameter(Mandatory = $false)]
    [Switch]$PortForward,

    [Parameter(Mandatory = $false)]
    [Switch]$FirewallRule,

    [Parameter(Mandatory = $false)]
    [Switch]$FirewallProfile,

    [Parameter(Mandatory = $false)]
    [Switch]$MapHosts,

	[Parameter(Mandatory = $false)]
	[string[]]$Ports=@()
)

# https://github.com/microsoft/WSL/issues/4139#issuecomment-646887016
# $wsl_ip = wsl.exe /bin/bash -c "ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"
$wsl_ip = (bash.exe -c "hostname -I | awk '{print `$1}'")
$win_ip = (bash.exe -c "ip route | grep default | awk '{print `$3}'")

$found1 = $wsl_ip -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
$found2 = $win_ip -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
if ( ! ($found1 -and $found2) ) {
    Write-Output "The Script Exited, the ip address of WSL 2 cannot be found!"
    exit
}


# Port forward
if ($PortForward) {
    # [Ports]
    # All the ports you want to forward separated by comma
    # $Ports=@(80,8080,443,10000,3000,5000)

    # [Static ip]
    # You can change the addr to your ip config to listen to a specific address
    $Addr='0.0.0.0'
    $Ports_a = $Ports -join ","

    # Remove Firewall Exception Rules
    Invoke-Expression "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' "

    # Adding Exception Rules for inbound and outbound Rules
    Invoke-Expression "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Outbound -LocalPort $Ports_a -Action Allow -Protocol TCP"
    Invoke-Expression "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -RemoteAddress $wsl_ip -Action Allow -Protocol TCP"

    for ( $i = 0; $i -lt $Ports.length; $i++ ) {
        $port = $Ports[$i]
        Invoke-Expression "netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$Addr"
        Invoke-Expression "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$Addr connectport=$port connectaddress=$wsl_ip"
    }
}


if ($FirewallRule) {
    # Enabling WSL2 Support in Firewall Settings
    # https://github.com/microsoft/WSL/issues/4585
    # https://docs.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule
    New-NetFirewallRule -DisplayName "WSL" -Direction Inbound -InterfaceAlias "vEthernet (WSL)" -Action Allow
    # Get-NetFirewallRule -Direction Inbound | Where-Object { $_.DisplayName -eq "WSL" }
    # Remove-NetFireWallRule -DisplayName "WSL"
}


if ($FirewallProfile) {
    # https://github.com/microsoft/WSL/issues/4139#issuecomment-704142482
    Set-NetFirewallProfile -Name $(Get-NetConnectionProfile).NetworkCategory -DisabledInterfaceAliases $(Get-NetAdapter | Where-Object Name -match 'WSL').Name
}


if ($MapHosts) {
    # Hosts
    $wsl_hosts = "wsl.local"
    $win_hosts = "win.local"
    $HOSTS_PATH = "$env:windir\System32\drivers\etc\hosts"

    $HOSTS_CONTENT = (Get-Content -Path $HOSTS_PATH) | Where-Object {$_.trim() -ne ""} | Select-String -Pattern '# w(sl)|(in)_hosts' -NotMatch
    $HOSTS_CONTENT = $HOSTS_CONTENT + "`n$wsl_ip $wsl_hosts # wsl_hosts`n$win_ip $win_hosts # win_hosts"
    Out-File -FilePath $HOSTS_PATH -InputObject $HOSTS_CONTENT -Encoding ASCII

    ipconfig /flushdns | Out-Null
}
