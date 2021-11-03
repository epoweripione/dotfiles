#Requires -RunAsAdministrator

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

# socks proxy
if (-Not (check_webservice_up)) {
    $SOCKS_PROXY_ADDR = "127.0.0.1:7890"
    if($PROMPT_VALUE = Read-Host "Scoks proxy address for github download?[$($SOCKS_PROXY_ADDR)]") {
        $SOCKS_PROXY_ADDR = $PROMPT_VALUE
    }
    if (-Not (check_socks5_proxy_up $SOCKS_PROXY_ADDR)) {
        $SOCKS_PROXY_ADDR = ""
    }
}


# A better way to add and remove Windows hosts file entries
# https://tomssl.com/2019/04/30/a-better-way-to-add-and-remove-windows-hosts-file-entries/
# .\AddToHosts.ps1 -Hostname tomssl.local -DesiredIP 127.0.0.1
# .\RemoveFromHosts.ps1 -Hostname tomssl.local
# .\UpdateMultipleHostsFiles.ps1 -ServerList @("192.168.1.49","192.168.1.50","192.168.1.51") -Timeout 7
$Hostfile = "$env:windir\System32\drivers\etc\hosts"
$Hostbackup = "$env:windir\System32\drivers\etc\hosts.bak"
# "192.168.1.1 bob" | Add-Content -PassThru $Hostfile
# "192.168.1.2 john" | Add-Content -PassThru $Hostfile

# download googlehosts file from github
Write-Host "Dowloading googlehosts..." -ForegroundColor Blue
$DOWNLOAD_HOST = "$env:windir\System32\drivers\etc\hosts.download"
$DOWNLOAD_URL = "https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts"
if (Test-Path $DOWNLOAD_HOST) {
    Remove-Item $DOWNLOAD_HOST
}

if (($null -eq $SOCKS_PROXY_ADDR) -or ($SOCKS_PROXY_ADDR -eq "")) {
    curl -fsL --connect-timeout 5 -o "$DOWNLOAD_HOST" "$DOWNLOAD_URL"
} else {
    curl -fsL --connect-timeout 5 --socks5-hostname "$SOCKS_PROXY_ADDR" -o "$DOWNLOAD_HOST" "$DOWNLOAD_URL"
}
# $p = New-Object System.Net.WebClient
# $p.DownloadFile($DOWNLOAD_URL, $Hostfile)
if ($?) {
    if ((Test-Path $DOWNLOAD_HOST) -and ((Get-Item $DOWNLOAD_HOST).length -gt 0)) {
        Copy-Item $Hostfile -Destination $Hostbackup
        Copy-Item $DOWNLOAD_HOST -Destination $Hostfile
    }
    # flush dns
    ipconfig -flushdns | Out-Null
}

# https://amazonaws.com.ipaddress.com/github-cloud.s3.amazonaws.com
# https://github.com.ipaddress.com/
# https://github.com.ipaddress.com/assets-cdn.github.com
# https://fastly.net.ipaddress.com/github.global.ssl.fastly.net
$HostListFile = ".\hosts_accelerate_cn.list"
if ((Test-Path $HostListFile) -and ((Get-Item $HostListFile).length -gt 0)) {
    [string[]]$HostsList = Get-Content $HostListFile
} else {
    $HostsList = @(
        "github.com"
        "www.github.com"
        "api.github.com"
        "gist.github.com"
        "codeload.github.com"
        "assets-cdn.github.com"
        "github.global.ssl.fastly.net"
        "github-cloud.s3.amazonaws.com"
        "github-production-release-asset-2e65be.s3.amazonaws.com"
        "github.githubassets.com"
        "raw.githubusercontent.com"
        "-gist.githubusercontent.com"
        "-cloud.githubusercontent.com"
        "-camo.githubusercontent.com"
        "-avatars0.githubusercontent.com"
        "-avatars1.githubusercontent.com"
        "-avatars2.githubusercontent.com"
        "-avatars3.githubusercontent.com"
        "-avatars4.githubusercontent.com"
        "-avatars5.githubusercontent.com"
        "-avatars6.githubusercontent.com"
        "-avatars7.githubusercontent.com"
        "-avatars8.githubusercontent.com"
    )
}

# local WAN ip
Write-Host "Getting Local WAN IP" -ForegroundColor Blue -NoNewline
$WANHostsList=@(
    "https://ifconfig.co/"
    "https://v4.ident.me/"
    "http://icanhazip.com/"
    "http://ipinfo.io/ip"
)
foreach ($TargetHost in $WANHostsList) {
    $LocalWANIP = curl -fsSL -4 "$TargetHost"
    $LocalWANIP = ($LocalWANIP | Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value
    $LocalWANIP = $LocalWANIP | Select-Object -first 1
    if (($null -eq $LocalWANIP) -or ($LocalWANIP -eq "")) {
        continue
    } else {
        Write-Host " $LocalWANIP"
        break
    }
}

# delete exist entry
Write-Host "Deleting exist entry in hosts..." -ForegroundColor Blue
$hostsContent = Get-Content $Hostfile
$hostExistCNT = 0
foreach ($TargetHost in $HostsList) {
    $TargetHost = $TargetHost.Trim()
    if (($null -eq $TargetHost) -or ($TargetHost -eq "")) {
        continue
    }
    # first char with `-`: Same IP as prior host
    if ($TargetHost.Substring(0,1) -eq "-") {
        $TargetHost = $TargetHost.Substring(1)
    }
    $escapedHostname = [Regex]::Escape($TargetHost)
    # $line = $hostsContent | Select-String -Pattern "[\s\t]$TargetHost$"
    # $lineNumber = $line.LineNumber
    # $hostsContent[$lineNumber - 1] = "$TargetIP $TargetHost"
    # $hostsContent[$lineNumber - 1] += "# $TargetHost"
    if ($TargetHost.Substring(0,1) -eq "#") {
        If ($hostsContent -match "$escapedHostname")  {
            $hostsContent = $hostsContent -notmatch "$escapedHostname"
            $hostExistCNT++
        }
    } else {
        If ($hostsContent -match "[\s\t]+$escapedHostname$")  {
            $hostsContent = $hostsContent -notmatch "[\s\t]+$escapedHostname$"
            $hostExistCNT++
        }
    }
}
if ($hostExistCNT -gt 0) {
    Set-Content $Hostfile $hostsContent
}

# get ip from ipaddress.com
Write-Host "Setting host entries..." -ForegroundColor Blue
$IP_HOSTS = ""
foreach ($TargetHost in $HostsList) {
    $TargetHost = $TargetHost.Trim()
    # empty line as newline
    if (($null -eq $TargetHost) -or ($TargetHost -eq "")) {
        $IP_HOSTS="$IP_HOSTS`n"
        continue
    }
    # comment
    if ($TargetHost.Substring(0,1) -eq "#") {
        $IP_HOSTS="$IP_HOSTS`n$TargetHost"
        continue
    }
    # first char with `-`: Same IP as prior host entry
    $SameIPPrior = "no"
    if ($TargetHost.Substring(0,1) -eq "-") {
        $SameIPPrior = "yes"
        $TargetHost = $TargetHost.Substring(1)
    }
    Write-Host "Checking $TargetHost" -ForegroundColor Blue -NoNewline
    # split domain
    $SplitHost = $TargetHost.Split('.')
    $TargetDomain = $SplitHost[-2] + "." + $SplitHost[-1]
    # if (($SplitHost).count -eq 2) {
    #     $TargetDomain = $TargetHost
    # } else {
    #     $TargetDomain = $SplitHost[-2] + "." + $SplitHost[-1]
    # }
    if ($TargetDomain -eq $TargetHost) {
        $TargetURL = "https://$TargetHost.ipaddress.com/"
    } else {
        $TargetURL = "https://$TargetDomain.ipaddress.com/$TargetHost"
    }
    # get ip use curl
    if ($SameIPPrior -eq "no") {
        $IPContent = curl -fsSL --connect-timeout 5 --max-time 15 $TargetURL
        $TargetIP = ($IPContent | Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" -AllMatches).Matches.Value
        $TargetIP = $TargetIP | Where-Object {$_ -NotContains $LocalWANIP} | Select-Object -first 1
    }
    # add host entry
    if (($null -eq $TargetIP) -or ($TargetIP -eq "")) {
        Write-Host " (Error)" -ForegroundColor Red
    } else {
        if ($SameIPPrior -eq "no") {
            # $IPGeo = curl -fsSL --connect-timeout 5 --max-time 15 https://ipinfo.io/$TargetIP/country
            $IPGeoURL = "http://ip-api.com/json/$TargetIP"
            try {
                $IPGeoRequest = Invoke-RestMethod -Method Get -URI $IPGeoURL  
            } catch {
                $IPGeoRequest = $null
            }
            $IPGeo = $IPGeoRequest.country
            # $IPGeo = $IPGeoRequest.countryCode
        }

        if (($null -eq $IPGeo) -or ($IPGeo = "")) {
            Write-Host " $TargetIP" -ForegroundColor Yellow
        } else {
            Write-Host " $TargetIP($IPGeo)" -ForegroundColor Yellow
        }
        $IP_HOSTS = "$IP_HOSTS`n$TargetIP $TargetHost"
    }
}

"$IP_HOSTS" | Add-Content -PassThru $Hostfile | Out-Null

# replace \r\n to \n
(Get-Content $Hostfile -Raw).Replace("`r`n","`n") | Set-Content $Hostfile -Force

# flush dns
ipconfig -flushdns | Out-Null

Write-Host "Done." -ForegroundColor Blue