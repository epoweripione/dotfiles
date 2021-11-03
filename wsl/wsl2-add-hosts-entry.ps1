#Requires -RunAsAdministrator

# https://abdus.dev/posts/fixing-wsl2-localhost-access-issue/

## Get adapter ipv4 adderss which connect to Internet
# $connectIP = Get-NetIPAddress -AddressFamily IPv4 | `
#                 Where-Object { $_.InterfaceIndex -eq `
#                     (Get-NetConnectionProfile -IPv4Connectivity "Internet" | Select-Object -ExpandProperty InterfaceIndex) `
#                 } | Select-Object -ExpandProperty IPv4Address

# get the internal IP in WSL instance
$hostname = "wsl"
$ifconfig = (wsl -- ip -4 addr show eth0)
$ipPattern = "(\d{1,3}(\.\d{1,3}){3})"
$ip = ([regex]"inet $ipPattern").Match($ifconfig).Groups[1].Value
if (-Not $ip) {
    exit
}

$hostsPath = "$env:windir/system32/drivers/etc/hosts"
$hosts = (Get-Content -Path $hostsPath -Raw -ErrorAction Ignore)
if ($null -eq $hosts) {
    $hosts = ""
}
$hosts = $hosts.Trim()

# update or add wsl ip
$find = "$ipPattern\s+$hostname"
$entry = "$ip $hostname"

if ($hosts -match $find) {
    $hostPattern = [Regex]::new("\d{1,3}(\.\d{1,3}){3}\s+$hostname")
    $hostMatches = $hostPattern.Matches($hosts)
    foreach ($TargetEntry in $hostMatches.Value) {
        if (-Not ($TargetEntry -match [regex]::Escape('127.0.0.1'))) {
            $hosts = $hosts -replace $TargetEntry, $entry
        }
    }
} else {
    $hosts = "$hosts`n$entry".Trim()
}

try {
    $temp = "$hostsPath.new"
    New-Item -Path $temp -ItemType File -Force | Out-Null
    Set-Content -Path $temp $hosts

    Move-Item -Path $temp -Destination $hostsPath -Force
} catch {
    Write-Error "Can't update WSL ip!"
}