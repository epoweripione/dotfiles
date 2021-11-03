# Access host ports from WSL 2.
# https://gist.github.com/vilic/0edcb3bec10339a3b633bc9305faa8b5

# Make sure WSL gets initialized.
bash.exe -c exit

# Record host name for /etc/hosts that points to host IP.
$HOST_NAME = "host.wsl";

# Ports listened on host localhost to forward, you don't need to add the port if it listens all addresses.
$HOST_LOCALHOST_PORTS = @(52698);

$FIREWALL_RULE_NAME = "wsl";
$FIREWALL_RULE_DISPLAY_NAME = "WSL";

Write-Output "Detecting WSL IP address...";

$hostIP = wsl -- bash -c "tail -1 /etc/resolv.conf | cut -d' ' -f2";
$wslIP = (wsl -- ip address show eth0 | Select-String -Pattern "inet ([\d.]+)").Matches.Groups[1].Value;

Write-Output "Host IP address: $hostIP";
Write-Output "WSL IP address: $wslIP";

Write-Output "Updating hosts record $HOST_NAME ($hostIP) for WSL...";

wsl --user root -- echo "$hostIP`t$HOST_NAME" ">>" /etc/hosts;

Write-Output "Updating firewall rule...";

Remove-NetFireWallRule -Name $FIREWALL_RULE_NAME -ErrorAction Ignore;

New-NetFireWallRule `
    -Name $FIREWALL_RULE_NAME `
    -DisplayName $FIREWALL_RULE_DISPLAY_NAME `
    -Direction Inbound `
    -LocalAddress @($hostIP)`
    -Action Allow;

Write-Output "Setting up localhost port proxies...";

foreach ($port in $HOST_LOCALHOST_PORTS) {
    $previousRecordGroups = (netsh interface portproxy show v4tov4 | Select-String "(\S+)\s+$port\s+127\.0\.0\.1\s+$port").Matches.Groups;

    if ($null -ne $previousRecordGroups) {
        $previousHostIP = $previousRecordGroups[1].Value;
        netsh interface portproxy delete v4tov4 listenport=$port listenaddress=$previousHostIP | Out-Null;
    }

    netsh interface portproxy add v4tov4 listenport=$port listenaddress=$hostIP connectport=$port connectaddress=127.0.0.1 | Out-Null;
}

Write-Output "Done.";