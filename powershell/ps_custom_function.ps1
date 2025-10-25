# New PSObject Template
if (-Not ('Windows.Media.Fonts' -as [Type])) {
    Add-Type -AssemblyName 'PresentationCore'
}

$DismObjT = New-Object -TypeName PSObject -Property @{
    "Feature" = ""
    "State" = ""
    "ComputerName" = ""
}

function isadmin() {
    # Returns true/false
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

# Add expiration timer for receiving the input to the built-in "read-host" cmdlet
# https://stackoverflow.com/questions/48261349/powershell-wait-for-specified-key-to-be-pressed-otherwise-timeout
# http://thecuriousgeek.org/2014/10/powershell-read-host-with-timeout/
# $answers = Read-Host-Timeout "Continue?[Y/n]" 5
function Read-Host-Timeout() {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [string]$prompt,
        
        [Parameter(Mandatory=$false,Position=2)]
        [int]$delayInSeconds
    )

    Write-host -nonewline "$($prompt):  "

    $sleep = 200
    $timeout = $delayInSeconds * 1000
    $charArray = New-Object System.Collections.ArrayList

    # While loop waits for the first key to be pressed for input and
    # then exits.  If the timer expires it returns null
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while (-not [Console]::KeyAvailable) {
        if ($stopwatch.ElapsedMilliseconds -gt $timeout) {
            return $null
        }

        Start-Sleep -Milliseconds $sleep
    }

    # Retrieve the key pressed, add it to the char array that is storing
    # all keys pressed and then write it to the same line as the prompt
    $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp").Character
    $charArray.Add($key) | out-null
    Write-host -nonewline $key

    # This block is where the script keeps reading for a key.  Every time
    # a key is pressed, it checks if it's a carriage return.  If so, it exits the
    # loop and returns the string.  If not it stores the key pressed and
    # then checks if it's a backspace and does the necessary cursor 
    # moving and blanking out of the backspaced character, then resumes 
    # writing. 
    $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
    While ($key.virtualKeyCode -ne 13) {
        If ($key.virtualKeycode -eq 8) {
            $charArray.Add($key.Character) | out-null
            Write-host -nonewline $key.Character
            $cursor = $host.ui.rawui.get_cursorPosition()
            write-host -nonewline " "
            $host.ui.rawui.set_cursorPosition($cursor)
            $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
        } else {
            $charArray.Add($key.Character) | out-null
            Write-host -nonewline $key.Character
            $key = $host.ui.rawui.readkey("NoEcho,IncludeKeyUp")
        }
    }

    ""
    $finalString = -join $charArray
    return $finalString
}

function CheckDownloadPWSHNewVersion {
    [Version]$ReleaseVersion = (Invoke-RestMethod 'https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/metadata.json').ReleaseTag -replace '^v'
    if ($PSVersionTable.PSEdition -like "Core" -and $ReleaseVersion -gt $PSVersionTable.PSVersion) {
        $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases" | Where-Object { $_.tag_name -eq "v$ReleaseVersion" }
        $downloadUrl = $latest.assets | Where-Object Name -like "*win-x64.msi" | Select-Object -ExpandProperty 'browser_download_url'
        Invoke-WebRequest -Uri $downloadUrl -OutFile "$PSScriptRoot\$(Split-Path $downloadUrl -Leaf)"
    }
    ## another method
    # $latest = Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
    # $downloadUrl = $latest.assets | Where-Object Name -like "*win-x64.msi" | Select-Object -ExpandProperty 'browser_download_url'
    # $fileName = Split-Path $downloadUrl -Leaf
    # $webClient = New-Object System.Net.WebClient
    # try {
    #     $webClient.DownloadFile($downloadUrl, "$PSScriptRoot\$fileName")
    # }
    # finally {
    #     $webClient.Dispose()
    # }
}

# https://gallery.technet.microsoft.com/scriptcenter/Parse-DISM-Get-Features-d25dde0a
# Must enable PSremoting on remote PC
# Enable-PSRemoting
function  GetDISMOnlineFeatures() {
    Param (
        # Set one or multiple computernames, also used for refering the logfile names with -UseLog. Default target is localhost computername, looks for\creates dism_<localhostname>.log
        [string[]]$Computers = $env:COMPUTERNAME
    )

    # Creating Blank array for holding the result
    $objResult = @()
    foreach ($Computer in $Computers) {
        # Read current values
        $List = Invoke-Command -ComputerName $Computer {Dism /online /English /Get-Features}
        # Use this if you get WinRM errors for above line, making the script local only
        # $List = Dism /online /Get-Features

        #Counter for getting alternate values
        $i = 1
        #Parsing the data
        #$List | Where-Object { $_.StartsWith("Feature Name :") -OR $_.StartsWith("State :") }| # where(43ms) is slower than Select-String(20ms)
        $List | Select-String -pattern "Feature Name :", "State :" | ForEach-Object {
            if ($i%2) {
                #Creating new object\Resetting for every item using template
                $TempObj = $DismObjT | Select-Object *
                #Assigning Value1
                $TempObj.Feature = ([string]$_).split(":")[1].trim() ;$i=0
            } else {
                #Assigning Value2
                $TempObj.State = ([string]$_).split(":")[1].trim() ;$i=1
                $TempObj.ComputerName = $Computer
                #Incrementing the object once both values filled
                $objResult+=$TempObj
            } 
        }
    }

    return $objResult
}

function  GetDISMOnlineCapabilities() {
    Param (
        # Set one or multiple computernames, also used for refering the logfile names with -UseLog. Default target is localhost computername, looks for\creates dism_<localhostname>.log
        [string[]]$Computers = $env:COMPUTERNAME
    )

    # Creating Blank array for holding the result
    $objResult = @()
    foreach ($Computer in $Computers) {
        # Read current values
        $List = Invoke-Command -ComputerName $Computer {Dism /online /English /Get-Capabilities}

        #Counter for getting alternate values
        $i = 1
        #Parsing the data
        #$List | Where-Object { $_.StartsWith("Feature Name :") -OR $_.StartsWith("State :") }| # where(43ms) is slower than Select-String(20ms)
        $List | Select-String -pattern "Capability Identity :", "State :" | ForEach-Object {
            if ($i%2) {
                #Creating new object\Resetting for every item using template
                $TempObj = $DismObjT | Select-Object *
                #Assigning Value1
                $TempObj.Feature = ([string]$_).split(":")[1].trim() ;$i=0
            } else {
                #Assigning Value2
                $TempObj.State = ([string]$_).split(":")[1].trim() ;$i=1
                $TempObj.ComputerName = $Computer
                #Incrementing the object once both values filled
                $objResult+=$TempObj
            } 
        }
    }

    return $objResult
}

function GetIPGeolocation() {
    Param ($ipaddress)

    $resource = "http://ip-api.com/json/$ipaddress"
    try {
        $geoip = Invoke-RestMethod -Method Get -URI $resource
    } catch {
        Write-Verbose -Message "Catched an error"
        $PSCmdlet.ThrowTerminatingError($PSitem)
    }

    # $geoip | Get-Member
    $hash = @{
        IP = $geoip.query
        CountryCode = $geoip.countryCode
        Country = $geoip.country
        Region = $geoip.region
        RegionName = $geoip.regionName
        AS = $geoip.as
        ISP = $geoip.isp
        ORG = $geoip.org
        City = $geoip.city
        ZipCode = $geoip.zip
        TimeZone = $geoip.timezone
        Latitude = $geoip.lat
        Longitude = $geoip.lon
        }

    $result = New-Object PSObject -Property $hash

    return $result
}

function check_webservice_up() {
    param($webservice_url)

    if (($null -eq $webservice_url) -or ($webservice_url -eq "")) {
        $webservice_url = "www.google.com"
    }

    curl -fsL --connect-timeout 3 --max-time 5 --noproxy "*" -I "$webservice_url"
    if ($?) {
        return $true
    } else {
        return $false
    }
}

function check_socks5_proxy_up() {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $proxy_url,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $webservice_url
    )

    if (($null -eq $webservice_url) -or ($webservice_url -eq "")) {
        $webservice_url = "www.google.com"
    }

    curl -fsL --connect-timeout 3 --max-time 5 --socks5-hostname "$proxy_url" -I "$webservice_url"
    if ($?) {
        return $true
    } else {
        return $false
    }
}

function check_http_proxy_up() {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $proxy_url,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $webservice_url
    )

    if (($null -eq $webservice_url) -or ($webservice_url -eq "")) {
        $webservice_url = "www.google.com"
    }

    curl -fsL --connect-timeout 3 --max-time 5 --proxy "$proxy_url" -I "$webservice_url"
    if ($?) {
        return $true
    } else {
        return $false
    }
}

function Set-WinHTTP-Proxy {
    <#
    .Description
    This function will set the proxy server using netsh.
    .Example
    Setting proxy information
    Set-WinHTTP-Proxy -proxy "127.0.0.1:7890"
    Set-WinHTTP-Proxy -proxy "socks=127.0.0.1:7890" -Bypass "localhost"
    #>
    Param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $Proxy,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Bypass
    )

    # netsh winhttp set proxy proxy-server="socks=127.0.0.1:7890" bypass-list="localhost"
    if (($null -eq $Proxy) -or ($Proxy -eq "")) {
        netsh winhttp reset proxy
    } else {
        if ($Proxy -eq "ie") {
            netsh winhttp import proxy source=ie
        } else {
            if ($Bypass) {
                netsh winhttp set proxy proxy-server="$Proxy" bypass-list="$Bypass"
            } else {
                netsh winhttp set proxy "$Proxy"
            }
        }
    }
}

function Set-InternetProxy {
    <#
    .Description
    This function will set the proxy server and (optinal) Automatic configuration script.
    .Example
    Setting proxy information
    Set-InternetProxy -proxy "127.0.0.1:7890"
    .Example
    Setting proxy information and (optinal) Automatic Configuration Script
    Set-InternetProxy -proxy "127.0.0.1:7890" -acs "http://127.0.0.1:7892"
    #>
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [String[]] $Proxy,

        [Parameter(Mandatory = $False, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [String[]] $acs
    )

    Begin {
        $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    }

    # Get-ItemProperty -Path $regKey | Select-Object ProxyServer, ProxyEnable, ProxyOverride
    Process {
        Set-ItemProperty -path $regKey -Name ProxyEnable -value 1
        Set-ItemProperty -path $regKey -Name ProxyServer -value $proxy
        Set-ItemProperty -Path $regKey -Name ProxyOverride -Value '<local>'
        if ($acs) {            
            Set-ItemProperty -path $regKey -Name AutoConfigURL -Value $acs          
        }

        [System.Environment]::SetEnvironmentVariable('http_proxy', $proxy, 'User')
        [System.Environment]::SetEnvironmentVariable('https_proxy', $proxy, 'User')
        [System.Environment]::SetEnvironmentVariable('HTTP_PROXY', $proxy, 'User')
        [System.Environment]::SetEnvironmentVariable('HTTPS_PROXY', $proxy, 'User')
    } 

    End {
        Write-Output "Proxy is now enabled, Proxy Server: $proxy"
        if ($acs) {
            Write-Output "Automatic Configuration Script: $acs"
        } else {
            Write-Output "Automatic Configuration Script: Not Defined"
        }
    }
}

function Clear-InternetProxy {
    Begin {
        $regKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    }

    Process {
        Set-ItemProperty -path $regKey -Name ProxyEnable -value 0
        Set-ItemProperty -path $regKey -Name ProxyServer -value ''
        Set-ItemProperty -Path $regKey -Name ProxyOverride -Value ''
        Set-ItemProperty -path $regKey -Name AutoConfigURL -Value ''

        [System.Environment]::SetEnvironmentVariable('http_proxy', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('https_proxy', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('HTTP_PROXY', $null, 'User')
        [System.Environment]::SetEnvironmentVariable('HTTPS_PROXY', $null, 'User')
    } 

    End {
        Write-Output "Proxy is now disabled!"
    }
}

function DownloadHosts() {
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $HostsURL,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $Proxy
    )

    if (-Not (isadmin)) {
        Write-Host "This script needs to be run As Admin!" -ForegroundColor Red
        return
    }

    if (($null -eq $HostsURL) -or ($HostsURL -eq "")) {
        $HostsURL = "https://raw.githubusercontent.com/googlehosts/hosts/master/hosts-files/hosts"
    }

    $Hostfile = "$env:windir\System32\drivers\etc\hosts"
    $HostOriginal = "$env:windir\System32\drivers\etc\hosts.original"
    $Hostbackup = "$env:windir\System32\drivers\etc\hosts.bak"
    $DOWNLOAD_TO = "$env:windir\System32\drivers\etc\hosts.download"

    if (-Not (Test-Path $HostOriginal)) {
        Copy-Item $Hostfile -Destination $HostOriginal
    }

    if (Test-Path $DOWNLOAD_TO) {
        Remove-Item $DOWNLOAD_TO
    }

    if (($null -eq $Proxy) -or ($Proxy -eq "")) {
        curl -fsL --connect-timeout 5 --ssl-no-revoke -o "$DOWNLOAD_TO" "$HostsURL"
    } else {
        curl -fsL --connect-timeout 5 --ssl-no-revoke --proxy "$Proxy" -o "$DOWNLOAD_TO" "$HostsURL"
    }

    if ($?) {
        if ((Test-Path $DOWNLOAD_TO) -and ((Get-Item $DOWNLOAD_TO).length -gt 0)) {
            Copy-Item $Hostfile -Destination $Hostbackup
            Copy-Item $DOWNLOAD_TO -Destination $Hostfile
        }
        # flush dns
        ipconfig -flushdns | Out-Null
    }
}

function RestartWSL {
    if (-Not (isadmin)) {
        Write-Host "This script needs to be run As Admin!" -ForegroundColor Red
        return
    }

    # Windows 10
    if (Get-Service -Name "LxssManager" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "LxssManager"
        Start-Service -Name "LxssManager"
    }

    # Windows 11
    if (Get-Service -Name "WslService" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "WslService"
        Start-Service -Name "WslService"
    }
}

function RestartWSA {
    if (-Not (isadmin)) {
        Write-Host "This script needs to be run As Admin!" -ForegroundColor Red
        return
    }

    if (Get-Service -Name "WsaService" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "WsaService"
        Start-Service -Name "WsaService"
    }
}

# https://www.powershellgallery.com/packages/RoughDraft/0.1/Content/Get-Font.ps1
function GetFonts() {
    <#
    .Synopsis
        Gets the fonts available
    .Description
        Gets the fonts available on the current installation
    .Example
        GetFonts
    .Example
        GetFonts -IncludeDetail
    #>
    # [OutputType([Windows.Media.FontFamily], [string])]
    param(
        # If set, finds finds with this name
        [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
        [string]$Name,
        # If set, will include all details of the font
        [switch]$IncludeDetail,
        # If set, will sort the results
        [Switch]$Sort
    )

    begin {
        $fontList = [Windows.Media.Fonts]::SystemFontFamilies
    }

    process {
        #region Filter Font List
        if ($Name.Trim()) {

            $currentFontList = foreach ($f in $fontList) {
                if ($f.Source -like "$name*") {
                    $f
                }
            }
        } else {
            $currentFontList = $fontList
        }
        #endregion Filter Font List

        if ($IncludeDetail) {
            if ($sort) {
                $currentFontList | 
                    Sort-Object Source | 
                    Add-Member ScriptProperty Name { $this.Source } -PassThru -Force
            } else {
                $currentFontList | 
                    Add-Member ScriptProperty Name { $this.Source } -PassThru -Force
            }

        } else {
            if ($sort) {
                $currentFontList | 
                    Sort-Object Source | 
                    Select-Object -ExpandProperty Source
            } else {
                $currentFontList | 
                    Select-Object -ExpandProperty Source
            }
        }
    }
}

function CheckSetGlobalProxy() {
    param (
        [string]$ProxyAddress = "127.0.0.1",
        [string]$ProxyMixedPort = "7890",
        [string]$ProxyHttpPort = "7890",
        [switch]$InputAddress,
        [string]$Msg = "Porxy address?"
    )

    # if ($env:GLOBAL_PROXY_IP) { return }

    if (!$ProxyHttpPort) {
        $ProxyHttpPort = $ProxyMixedPort
    }

    $Proxy = ""
    $ProxyProtocol = "http"
    $ProxyPort = "$ProxyHttpPort"
    if (-Not (check_webservice_up)) {
        $Proxy = "${ProxyAddress}:${ProxyMixedPort}"
        $ProxyPort = "$ProxyMixedPort"
        if (-Not (check_http_proxy_up $Proxy)) {
            if (check_socks5_proxy_up $Proxy) {
                $ProxyProtocol = "socks5"
            } else {
                $Proxy = ""
            }
        }

        if (!$Proxy) {
            $Proxy = "${ProxyAddress}:${ProxyHttpPort}"
            $ProxyPort = "$ProxyHttpPort"
            if (-Not (check_http_proxy_up $Proxy)) {
                $Proxy = ""
            }
        }

        if (!$Proxy -and $InputAddress) {
            if ($PROMPT_VALUE = Read-Host "$Msg[127.0.0.1:7890]") {
                $Proxy = $PROMPT_VALUE
                if (!$Proxy) {
                    $Proxy = "127.0.0.1:7890"
                }
                if (check_http_proxy_up $Proxy) {
                    if ($Proxy.Contains("://")) {
                        $ProxyProtocol = $Proxy.Split("://")[0]
                        $Proxy = $Proxy.Split("://")[1]
                    } else {
                        $ProxyProtocol = "http"
                    }
                    $ProxyAddress = $Proxy.Split(":")[0]
                    $ProxyPort = $Proxy.Split(":")[1]
                } else {
                    $Proxy = ""
                }
            } else {
                $Proxy = ""
            }
        }
    }

    if ($Proxy) {
        # User environment variables
        if (-Not ([Environment]::GetEnvironmentVariable("HTTP_PROXY") -eq "${ProxyProtocol}://${ProxyAddress}:${ProxyPort}")) {
            $PSCommand = @"
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_IP', '${ProxyAddress}', 'User');
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_MIXED_PORT', '${ProxyMixedPort}', 'User');
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_HTTP_PORT', '${ProxyHttpPort}', 'User');
[Environment]::SetEnvironmentVariable('HTTP_PROXY', '${ProxyProtocol}://${ProxyAddress}:${ProxyPort}', 'User');
[Environment]::SetEnvironmentVariable('HTTPS_PROXY', '${ProxyProtocol}://${ProxyAddress}:${ProxyPort}', 'User');
[Environment]::SetEnvironmentVariable('ALL_PROXY', '${ProxyProtocol}://${ProxyAddress}:${ProxyPort}', 'User');
[Environment]::SetEnvironmentVariable('NO_PROXY', 'localhost,127.0.0.1,::1', 'User')
"@
            $PSCommand = $PSCommand -Replace "`r`n"
            Start-Process powershell "$PSCommand" -WindowStyle Hidden -Verb RunAs
        }

        # Current session environment variables
        $env:GLOBAL_PROXY_IP = "${ProxyAddress}"
        $env:GLOBAL_PROXY_MIXED_PORT = "${ProxyMixedPort}"
        $env:GLOBAL_PROXY_HTTP_PORT = "${ProxyHttpPort}"

        $env:HTTP_PROXY = "${ProxyProtocol}://${ProxyAddress}:${ProxyPort}"
        $env:HTTPS_PROXY = "${ProxyProtocol}://${ProxyAddress}:${ProxyPort}"
        $env:ALL_PROXY = "${ProxyProtocol}://${ProxyAddress}:${ProxyPort}"
        $env:NO_PROXY = "localhost,127.0.0.1,::1"
    } else {
        # User environment variables
        $PSCommand = @"
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_IP', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_MIXED_PORT', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('GLOBAL_PROXY_HTTP_PORT', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('HTTP_PROXY', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('HTTPS_PROXY', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('ALL_PROXY', [NullString]::Value, 'User');
[Environment]::SetEnvironmentVariable('NO_PROXY', [NullString]::Value, 'User')
"@
        $PSCommand = $PSCommand -Replace "`r`n"
        Start-Process powershell "$PSCommand" -WindowStyle Hidden -Verb RunAs

        # Current session environment variables
        if ($env:GLOBAL_PROXY_IP) {Remove-Item "Env:\GLOBAL_PROXY_IP"}
        if ($env:GLOBAL_PROXY_MIXED_PORT) {Remove-Item "Env:\GLOBAL_PROXY_MIXED_PORT"}
        if ($env:GLOBAL_PROXY_HTTP_PORT) {Remove-Item "Env:\GLOBAL_PROXY_HTTP_PORT"}

        if ($env:HTTP_PROXY) {Remove-Item "Env:\HTTP_PROXY"}
        if ($env:HTTPS_PROXY) {Remove-Item "Env:\HTTPS_PROXY"}
        if ($env:ALL_PROXY) {Remove-Item "Env:\ALL_PROXY"}
        if ($env:NO_PROXY) {Remove-Item "Env:\NO_PROXY"}
    }

    # if (![string]::IsNullOrEmpty($Proxy)) {
    # if (![string]::IsNullOrWhiteSpace($Proxy)) {
    if ($Proxy) {
        # Write-Host "HTTP_PROXY=$env:HTTP_PROXY`nHTTPS_PROXY=$env:HTTPS_PROXY`nALL_PROXY=$env:ALL_PROXY`nNO_PROXY=$env:NO_PROXY`n" -ForegroundColor Yellow
        Write-Host "  ::" -ForegroundColor Green -NoNewline
        Write-Host " HTTP_PROXY" -ForegroundColor Magenta -NoNewline
        Write-Host "=" -ForegroundColor Cyan -NoNewline
        Write-Host "$env:HTTP_PROXY" -ForegroundColor Yellow -NoNewline

        Write-Host " HTTPS_PROXY" -ForegroundColor Magenta -NoNewline
        Write-Host "=" -ForegroundColor Cyan -NoNewline
        Write-Host "$env:HTTPS_PROXY" -ForegroundColor Yellow -NoNewline

        Write-Host " ALL_PROXY" -ForegroundColor Magenta -NoNewline
        Write-Host "=" -ForegroundColor Cyan -NoNewline
        Write-Host "$env:ALL_PROXY" -ForegroundColor Yellow -NoNewline

        Write-Host " NO_PROXY" -ForegroundColor Magenta -NoNewline
        Write-Host "=" -ForegroundColor Cyan -NoNewline
        Write-Host "$env:NO_PROXY" -ForegroundColor Yellow
    }
}

function setGlobalProxies {
    if ([Environment]::GetEnvironmentVariable("GLOBAL_PROXY_IP")) {
        $GLOBAL_PROXY_IP = [Environment]::GetEnvironmentVariable("GLOBAL_PROXY_IP")
        $GLOBAL_PROXY_MIXED_PORT = [Environment]::GetEnvironmentVariable("GLOBAL_PROXY_MIXED_PORT")
        $GLOBAL_PROXY_HTTP_PORT = [Environment]::GetEnvironmentVariable("GLOBAL_PROXY_HTTP_PORT")
    }

    if (!$GLOBAL_PROXY_IP) {$GLOBAL_PROXY_IP="127.0.0.1"}
    if (!$GLOBAL_PROXY_MIXED_PORT) {$GLOBAL_PROXY_MIXED_PORT="7890"}
    if (!$GLOBAL_PROXY_HTTP_PORT) {$GLOBAL_PROXY_HTTP_PORT="7890"}
    
    CheckSetGlobalProxy -ProxyAddress "$GLOBAL_PROXY_IP" -ProxyMixedPort "$GLOBAL_PROXY_MIXED_PORT" -ProxyHttpPort "$GLOBAL_PROXY_HTTP_PORT"
    
    if (!$env:GLOBAL_PROXY_IP) {
        $GLOBAL_PROXY_IP="127.0.0.1"
        $GLOBAL_PROXY_SECONDARY_MIXED_PORT="7960"
        $GLOBAL_PROXY_SECONDARY_HTTP_PORT="7960"
    
        CheckSetGlobalProxy -ProxyAddress "$GLOBAL_PROXY_IP" -ProxyMixedPort "$GLOBAL_PROXY_SECONDARY_MIXED_PORT" -ProxyHttpPort "$GLOBAL_PROXY_SECONDARY_HTTP_PORT"
    }
}

function RebuildFontCache {
    # https://eddiejackson.net/wp/?p=16137
    # https://www.isunshare.com/windows-10/how-to-delete-font-cache-in-windows-10.html
    if (-Not (isadmin)) {
        Write-Host "This script needs to be run As Admin!" -ForegroundColor Red
        return
    }

    Stop-Service -Name "FontCache"

    Remove-Item "$env:windir\ServiceProfiles\LocalService\AppData\Local\FontCache" -Recurse -Force -Confirm:$false -ErrorAction Stop
    Remove-Item "$env:windir\System32\FNTCACHE.DAT" -Force -Confirm:$false -ErrorAction Stop

    Start-Service -Name "FontCache"
}

function ConvertTo-HexString {
    <#
    .SYNOPSIS
        Convert to Hex String
    .DESCRIPTION
        Convert to Hex String
        https://www.powershellgallery.com/packages/Utility.PS/
    .EXAMPLE
        Convert string to hex byte string seperated by spaces.
        ConvertTo-HexString "What is a hex string?"
    .EXAMPLE
        Convert ASCII string to hex byte string with no seperation.
        "ASCII string to hex string" | ConvertTo-HexString -Delimiter "" -Encoding Ascii
    .INPUTS
        System.Object
    #>
    [CmdletBinding()]
    param (
        # Value to convert
        [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline=$true)]
        [object] $InputObjects,
        # Delimiter between Hex pairs
        [Parameter (Mandatory=$false)]
        [string] $Delimiter = ' ',
        # Encoding to use for text strings
        [Parameter (Mandatory=$false)]
        [ValidateSet('Ascii', 'UTF32', 'UTF7', 'UTF8', 'BigEndianUnicode', 'Unicode')]
        [string] $Encoding = 'Default'
    )

    begin {
        function Transform ([byte[]]$InputBytes) {
            [string[]] $outHexString = New-Object string[] $InputBytes.Count
            for ($iByte = 0; $iByte -lt $InputBytes.Count; $iByte++) {
                $outHexString[$iByte] = $InputBytes[$iByte].ToString('X2')
            }
            return $outHexString -join $Delimiter
        }

        ## Create list to capture byte stream from piped input.
        [System.Collections.Generic.List[byte]] $listBytes = New-Object System.Collections.Generic.List[byte]
    }

    process
    {
        if ($InputObjects -is [byte[]]) {
            Write-Output (Transform $InputObjects)
        } else {
            foreach ($InputObject in $InputObjects) {
                [byte[]] $InputBytes = $null
                if ($InputObject -is [byte]) {
                    ## Populate list with byte stream from piped input.
                    if ($listBytes.Count -eq 0) {
                        Write-Verbose 'Creating byte array from byte stream.'
                        Write-Warning ('For better performance when piping a single byte array, use "Write-Output $byteArray -NoEnumerate | {0}".' -f $MyInvocation.MyCommand)
                    }
                    $listBytes.Add($InputObject)
                } elseif ($InputObject -is [byte[]]) {
                    $InputBytes = $InputObject
                } elseif ($InputObject -is [string]) {
                    $InputBytes = [Text.Encoding]::$Encoding.GetBytes($InputObject)
                } elseif ($InputObject -is [bool] -or $InputObject -is [char] -or $InputObject -is [single] -or $InputObject -is [double] -or $InputObject -is [int16] -or $InputObject -is [int32] -or $InputObject -is [int64] -or $InputObject -is [uint16] -or $InputObject -is [uint32] -or $InputObject -is [uint64]) {
                    $InputBytes = [System.BitConverter]::GetBytes($InputObject)
                } elseif ($InputObject -is [guid]) {
                    $InputBytes = $InputObject.ToByteArray()
                } elseif ($InputObject -is [System.IO.FileSystemInfo]) {
                    if ($PSVersionTable.PSVersion -ge [version]'6.0') {
                        $InputBytes = Get-Content $InputObject.FullName -Raw -AsByteStream
                    } else {
                        $InputBytes = Get-Content $InputObject.FullName -Raw -Encoding Byte
                    }
                } else {
                    ## Non-Terminating Error
                    $Exception = New-Object ArgumentException -ArgumentList ('Cannot convert input of type {0} to Hex string.' -f $InputObject.GetType())
                    Write-Error -Exception $Exception -Category ([System.Management.Automation.ErrorCategory]::ParserError) -CategoryActivity $MyInvocation.MyCommand -ErrorId 'ConvertHexFailureTypeNotSupported' -TargetObject $InputObject
                }

                if ($null -ne $InputBytes -and $InputBytes.Count -gt 0) {
                    Write-Output (Transform $InputBytes)
                }
            }
        }
    }

    end {
        ## Output captured byte stream from piped input.
        if ($listBytes.Count -gt 0) {
            Write-Output (Transform $listBytes.ToArray())
        }
    }
}

function ConvertFrom-HexString {
    <#
    .SYNOPSIS
        Convert from Hex String
    .DESCRIPTION
        Convert from Hex String
        https://www.powershellgallery.com/packages/Utility.PS/
    .EXAMPLE
        ConvertFrom-HexString "68 65 6C 6C 6F 20 77 6F 72 6C 64" # hello world
    #>
    [CmdletBinding()]
    param (
        # Value to convert
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string[]] $InputObject,
        # Delimiter between Hex pairs
        [Parameter (Mandatory=$false)]
        [string] $Delimiter = " ",
        # Output raw byte array
        [Parameter (Mandatory=$false)]
        [switch] $RawBytes,
        # Encoding to use for text strings
        [Parameter (Mandatory=$false)]
        [ValidateSet("Ascii", "UTF32", "UTF7", "UTF8", "BigEndianUnicode", "Unicode")]
        [string] $Encoding = "Default"
    )

    process
    {
        $listBytes = New-Object object[] $InputObject.Count
        for ($iString = 0; $iString -lt $InputObject.Count; $iString++) {
            [string] $strHex = $InputObject[$iString]
            if ($strHex.Substring(2,1) -eq $Delimiter) {
                [string[]] $listHex = $strHex -split $Delimiter
            } else {
                [string[]] $listHex = New-Object string[] ($strHex.Length/2)
                for ($iByte = 0; $iByte -lt $strHex.Length; $iByte += 2) {
                    $listHex[[System.Math]::Truncate($iByte/2)] = $strHex.Substring($iByte, 2)
                }
            }

            [byte[]] $outBytes = New-Object byte[] $listHex.Count
            for ($iByte = 0; $iByte -lt $listHex.Count; $iByte++)
            {
                $outBytes[$iByte] = [byte]::Parse($listHex[$iByte],[System.Globalization.NumberStyles]::HexNumber)
            }

            if ($RawBytes) { $listBytes[$iString] = $outBytes } else {
                $outString = ([Text.Encoding]::$Encoding.GetString($outBytes))
                Write-Output $outString
            }
        }
        if ($RawBytes) {
            return $listBytes
        }
    }
}

# unix like `cut` command
function cut() {
    param (
        [Parameter(ValueFromPipeline = $True)]
        [string]$inputobject,

        [string]$delimiter='\s+',

        [string[]]$field
    )

    process {
        if ($null -eq $field) {
            $inputobject -split $delimiter
        } else {
            ($inputobject -split $delimiter)[$field]
        }
    }
}

# Finding Illegal Characters in Path
function findIllegalCharsInPath() {
    param (
        [string]$pathToCheck
    )

    # get invalid characters and escape them for use with RegEx
    $illegal = [Regex]::Escape(-join [Io.Path]::GetInvalidPathChars())
    $pattern = "[$illegal]"

    # find illegal characters
    $invalid = [regex]::Matches($pathToCheck, $pattern, 'IgnoreCase').Value | Sort-Object -Unique
    # $invalid | Format-Hex

    if ($null -ne $invalid) {
        Write-Host "Don't use these characters in path: $invalid" -ForegroundColor Red
    } else {
        Write-Host "No invalid path characters in: $pathToCheck" -ForegroundColor Blue
    }
}

# Finding Illegal Characters in Filename
function findIllegalCharsInFilename() {
    param (
        [string]$fileToCheck
    )

    # get invalid characters and escape them for use with RegEx
    $illegal = [Regex]::Escape(-join [Io.Path]::GetInvalidFileNameChars())
    $pattern = "[$illegal]"

    # find illegal characters
    $invalid = [regex]::Matches($fileToCheck, $pattern, 'IgnoreCase').Value | Sort-Object -Unique

    if ($null -ne $invalid) {
        Write-Host "Don't use these characters in path: $invalid" -ForegroundColor Red
    } else {
        Write-Host "No invalid file characters in: $fileToCheck" -ForegroundColor Blue
    }
}

## List firewall rules by description
# Get-FirewallRulesByDescription -FirewallRuleDescription "Clash Verge"
function Get-FirewallRulesByDescription {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $FirewallRuleDescription
    )

    Get-NetFirewallRule -Description "$FirewallRuleDescription" | `
        Format-Table -Property Name,DisplayName,`
            @{Name='Protocol';Expression={($PSItem | Get-NetFirewallPortFilter).Protocol}},`
            @{Name='LocalPort';Expression={($PSItem | Get-NetFirewallPortFilter).LocalPort}},`
            @{Name='RemotePort';Expression={($PSItem | Get-NetFirewallPortFilter).RemotePort}},`
            @{Name='RemoteAddress';Expression={($PSItem | Get-NetFirewallAddressFilter).RemoteAddress}},`
            Enabled,Profile,Direction,Action `
    -ErrorAction SilentlyContinue
}

## Add TCP/UDP firewall rules for executables (needs admin rights)
# Add-ExecutableTcpUdpFirewallRules -ExecutableFullPath "$env:ProgramFiles\Clash Verge\clash-verge.exe" -FirewallRuleDescription "Clash Verge" -FirewallRuleDisplayName "clash-verge"
# Add-ExecutableTcpUdpFirewallRules -ExecutableFullPath "$env:ProgramFiles\Clash Verge\verge-mihomo.exe" -FirewallRuleDescription "Clash Verge" -FirewallRuleDisplayName "clash-verge-mihomo"
function Add-ExecutableTcpUdpFirewallRules {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $ExecutableFullPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $FirewallRuleDescription,

        [Parameter(Mandatory = $false)]
        [string] $FirewallRuleDisplayName
    )

    if (-Not (isadmin)) {
        Write-Warning "This script needs to be run As Admin!"
        return
    }

    if (-Not (Test-Path $ExecutableFullPath)) {
        Write-Warning "$ExecutableFullPath Not found. No Firewall rules have been created."
        Read-Host "Press Enter to continue..."
        return
    }

	if (-Not $FirewallRuleDescription) {
		$FirewallRuleDescription = Read-Host "Enter firewall rule description"
	}

    if (-Not $FirewallRuleDescription) {
        Write-Warning "Firewall rule description can't empty. No Firewall rules have been created."
        Read-Host "Press Enter to continue..."
        return
    }

    $ExecutableFilename = Get-ChildItem "$ExecutableFullPath"
    if (-Not $FirewallRuleDisplayName) {
        $FirewallRuleDisplayName = $ExecutableFilename.Name
    }

    # Add TCP/UDP rules
    'TCP', 'UDP' | ForEach-Object {
        New-NetFirewallRule -DisplayName "$FirewallRuleDisplayName" `
            -Description "$FirewallRuleDescription" `
            -Profile "Private, Public" `
            -Direction Inbound `
            -Protocol $_ `
            -Action Allow `
            -Program "$ExecutableFilename" `
            -EdgeTraversalPolicy DeferToUser `
        | Out-Null
    }

    # List added rules
    Get-FirewallRulesByDescription -FirewallRuleDescription "$FirewallRuleDescription"

    # Remove-NetFirewallRule -Description "$FirewallRuleDescription" -ErrorAction SilentlyContinue
}

function fixIPv6PrefixPolicies() {
    if (-Not (isadmin)) {
        Write-Warning "This script needs to be run As Admin!"
        return
    }

    netsh interface ipv6 show prefixpolicies

    netsh int ipv6 set prefix ::/96 50 0
    netsh int ipv6 set prefix ::ffff:0:0/96 40 1
    netsh int ipv6 set prefix 2002::/16 35 2
    netsh int ipv6 set prefix 2001::/32 30 3
    netsh int ipv6 set prefix ::1/128 10 4
    netsh int ipv6 set prefix ::/0 5 5
    netsh int ipv6 set prefix fc00::/7 3 13
    netsh int ipv6 set prefix fec0::/10 1 11
    netsh int ipv6 set prefix 3ffe::/16 1 12

    netsh interface ipv6 show prefixpolicies
}
