#Requires -RunAsAdministrator

## Usage:
## 1. Install PowerShell: https://github.com/PowerShell/PowerShell
## PowerShell 7.0+ with preinstalled .NET Core 3.1 SDK:
# dotnet tool install --global PowerShell
# dotnet tool update --global PowerShell
## 2. Run pwsh as Administrator
## 3. Download pwsh_script_download.ps1
## curl -fsSL --socks5-hostname 127.0.0.1:7890 -o ".\pwsh_script_download.ps1" "https://git.io/JPS2j"
# curl -fsSL -o ".\pwsh_script_download.ps1" "https://git.io/JPS2j"
## 4. Exec pwsh_script_download.ps1
# .\pwsh_script_download.ps1
## 5. Exec Powershell_init.ps1
# ~\Documents\PowerShell\Scripts\Powershell_init.ps1


## PowerShell Core Command-line options
## PowerShell Online Help: https://aka.ms/powershell-docs
# pwsh -h
# Usage: pwsh[.exe] [-Login] [[-File] <filePath> [args]]
#                   [-Command { - | <script-block> [-args <arg-array>]
#                                 | <string> [<CommandParameters>] } ]
#                   [-ConfigurationName <string>] [-CustomPipeName <string>]
#                   [-EncodedCommand <Base64EncodedCommand>]
#                   [-ExecutionPolicy <ExecutionPolicy>] [-InputFormat {Text | XML}]
#                   [-Interactive] [-MTA] [-NoExit] [-NoLogo] [-NonInteractive] [-NoProfile]
#                   [-OutputFormat {Text | XML}] [-SettingsFile <filePath>] [-SSHServerMode] [-STA]
#                   [-Version] [-WindowStyle <style>] [-WorkingDirectory <directoryPath>]
# example: pwsh -Command "& {suu}"


# Write-Host "Script:" $PSCommandPath
# Write-Host "Path:" $PSScriptRoot


## simple http server
# cd ~; python -m http.server 8080


## Get & Set user env
# $env:UserProfile
# $env:SystemRoot
# $env:SystemDrive
# $env:PROCESSOR_ARCHITECTURE
# $env:temp
# $systemenv = [System.Environment]::GetEnvironmentVariable("Path")
# $systemenv = $systemenv.TrimEnd(';')
# [System.Environment]::SetEnvironmentVariable("PATH", $systemenv + ";C:\Users\Administrator\Ubuntu", "Machine")

# $userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
## if ($userenv.Contains(";")) { $userenv = $userenv -replace '[;]' }
# $userenv = $userenv.TrimEnd(';')
# [System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\Users\Administrator\Ubuntu", "User")


## Get file hash
# Get-FileHash -Path <filename> -Algorithm <MD5,SHA1,SHA256,SHA384,SHA512>


## Gets all commands
# Get-Command -ListImported
# Get-Command -Type Cmdlet | Sort-Object -Property Noun | Format-Table -GroupBy Noun
# Get-Command -Module Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility


## Gets the basic network adapter properties
# Get-NetAdapter -Name * -Physical | Where-Object Status -eq 'up'
# Get-NetAdapter -Name "Ethernet" | Format-List -Property *


## Gets a connection profile
# Get-NetConnectionProfile -IPv4Connectivity "Internet" | Select-Object -Property Name,InterfaceIndex,InterfaceAlias
# Get-NetConnectionProfile -IPv4Connectivity "Internet" | Select-Object -ExpandProperty InterfaceIndex


## Forwarding to be enabled across the two v-Switches
# Get-NetIPInterface | Select-Object ifIndex,InterfaceAlias,AddressFamily,ConnectionState,Forwarding |
#     Where-Object {$_.InterfaceAlias -eq 'vEthernet (WSL)' -or $_.InterfaceAlias -eq 'vEthernet (Default Switch)'} |
#     Where-Object {$_.Forwarding -eq 'Disabled'} |
#     Set-NetIPInterface -Forwarding 'Enabled'


## Get adapter ipv4 adderss which connect to Internet
# Get-NetIPAddress -AddressFamily IPv4 |
#     Where-Object { $_.InterfaceIndex -eq (Get-NetConnectionProfile -IPv4Connectivity "Internet" | Select-Object -ExpandProperty InterfaceIndex) } |
#     Select-Object -ExpandProperty IPv4Address


## Get TCP/UDP connections
## https://isc.sans.edu/forums/diary/Netstat+Local+and+Remote+new+and+improved+now+with+more+PowerShell/25058/
# netstat -an
# Get-NetTCPConnection -State Listen,Established |
#     Select-Object -Property LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess,
#         @{'Name' = 'ProcessName';'Expression'={(Get-Process -Id $_.OwningProcess).Name}},
#         @{'Name' = 'Path';'Expression'={(Get-Process -Id $_.OwningProcess).Path}} |
#     Sort-Object -Property ProcessName,LocalPort |
#     Format-Table
# Get-NetUDPEndpoint |
#     Select-Object -Property LocalAddress,LocalPort,OwningProcess,
#         @{'Name' = 'ProcessName';'Expression'={(Get-Process -Id $_.OwningProcess).Name}},
#         @{'Name' = 'Path';'Expression'={(Get-Process -Id $_.OwningProcess).Path}} |
#     Sort-Object -Property ProcessName,LocalPort |
#     Format-Table


## Gets the CIM instances of a class from a CIM server
# wmic nic where PhysicalAdapter=True get Index,MACAddress,NetConnectionStatus,PhysicalAdapter,InterfaceIndex,Name
# wmic nic where "PhysicalAdapter=True AND NetConnectionStatus=2" get Index,MACAddress,InterfaceIndex,Name
# wmic path win32_networkadapterconfiguration where "IPEnabled=True" get Index,InterfaceIndex,MACAddress,IPAddress,IPSubnet

# Get-CimClass -ClassName *disk*
# Get-CimClass -ClassName Win32* -PropertyName Handle
# Get-CimClass -ClassName *Network*
# Get-CimInstance -ClassName CIM_NetworkAdapter
# Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter=True"
# Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Select-Object -Property Index,Description,MACAddress,IPAddress
# Get-CimInstance -ClassName Win32_Process
# Get-CimInstance -ClassName Win32_Process -Filter "Name like 'P%'"
# Get-CimInstance -Query "SELECT * from Win32_Process WHERE name LIKE 'P%'"


## Gets the properties and methods of objects
# Get-Service | Get-Member
# $fontList = [Windows.Media.Fonts]::SystemFontFamilies
# $fontList | Get-Member


## Manage System Services
## https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service
# Get-Service -Name "win*" -Exclude "WinRM"
# Get-Service -Displayname "*network*"
# Get-Service | Where-Object {$_.Status -eq "Running"}
# Get-Service "BITS" | Select-Object -Property Name, StartType, Status
# Get-Service "WinRM" -RequiredServices
# Get-Service |
#   Where-Object {$_.DependentServices} |
#     Format-List -Property Name, DependentServices, @{
#       Label="NoOfDependentServices"; Expression={$_.dependentservices.count}
#     }
# Get-Service "s*" | Sort-Object status

## https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service
# Set-Service -Name "BITS" -StartupType Automatic
# Set-Service -Name "LanmanWorkstation" -DisplayName "LanMan Workstation"
# Get-CimInstance Win32_Service -Filter 'Name = "BITS"'  | Format-List  Name, Description
# Set-Service -Name BITS -Description "Transfers files in the background using idle network bandwidth."
# Set-Service -Name "WinRM" -Status Running -PassThru
# Get-Service -Name "Schedule" | Set-Service -Status Paused

## https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service
# Start-Service -Name "eventlog"
# Start-Service -DisplayName "*remote*" -WhatIf
# Get-Service "Wsearch" | Where-Object {$_.status -eq 'Stopped'} | Start-Service

## https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/stop-service
# Get-Service -Name "iisadmin" | Format-List -Property Name, DependentServices
# Stop-Service -Name "iisadmin" -Force -Confirm


## Windows Features: dism /online /Get-Features
# Get-WindowsOptionalFeature -Online | Select-Object FeatureName,State
# LIST All IIS FEATURES: 
# Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'IIS-*' | Select-Object FeatureName,State
## Check for Installed Features:
# Get-WindowsOptionalFeature -Online | Where-Object {$_.state -eq "Enabled"} | Format-Table -Property featurename
## Check for Features available but Not Installed
# Get-WindowsOptionalFeature -Online | Where-Object {$_.state -eq "Disabled"} | Format-Table -Property featurename
## Enable a Windows Feature
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
## Disable a Windows Feature
# Disable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing


## Group Policy Management
## https://www.thewindowsclub.com/group-policy-settings-reference-windows
## Group Policy Settings Reference for Windows 10 (1703) and Windows Server
## https://www.microsoft.com/en-us/download/details.aspx?id=25250
## Group Policy Settings Reference Spreadsheet Windows 1803
## https://www.microsoft.com/en-us/download/details.aspx?id=56946
## Group Policy Settings Reference Spreadsheet Windows 1809
## https://www.microsoft.com/en-us/download/details.aspx?id=57464

## https://www.powershellgallery.com/packages/PolicyFileEditor/3.0.0
# Install-Module -Name PolicyFileEditor
# Get-Command -Module PolicyFileEditor
## PolicyFileEditor is a PowerShell module to manage local GPO registry.pol files.
## Usage:
# $RegPath = 'Software\Policies\Microsoft\Windows\Control Panel\Desktop'
# $RegName = 'ScreenSaverIsSecure'
# $RegData = '1'
# $RegType = 'String'
# Set-PolicyFileEntry -Path $UserDir -Key $RegPath -ValueName $RegName -Data $RegData -Type $RegType

## https://www.prajwaldesai.com/install-rsat-tools-on-windows-10-version-1809/
## https://blog.netwrix.com/2019/04/18/group-policy-management/
## https://blog.netwrix.com/2019/04/11/top-10-group-policy-powershell-commands/
## https://4sysops.com/archives/administering-group-policy-with-powershell/
# .  ".\ps_custom_function.ps1"
## $DISMFeature = GetDISMOnlineFeatures
## $DISMFeature | Where-Object {$_.feature -like "*iis*"} | Select-Object -ExpandProperty feature
## Dism /online /Get-FeatureInfo /FeatureName:IIS-WebServer
## Dism /online /Enable-Feature /FeatureName:IIS-WebServer /All
# $DISMCapabilities = GetDISMOnlineCapabilities
# $DISMCapabilities | Where-Object {$_.feature -like "*GroupPolicy*"} | ForEach-Object {
#     $DISMFeature = $_.feature
#     DISM /Online /add-capability /CapabilityName:$DISMFeature
# }


## WindowsCapability
# Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
# Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

## Scheduled tasks
## list scheduled task
# Get-ScheduledTask -TaskName "SystemScan"
# Get-ScheduledTask -TaskPath "\"
# Get-ScheduledTask -TaskPath "\UpdateTasks\*"

## Create schedule task
# $Action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-NonInteractive -NoLogo -NoProfile -WorkingDirectory "%USERPROFILE%" -WindowStyle "Hidden" -File "C:\MyScript.ps1"'
# $Trigger = New-ScheduledTaskTrigger -Once -At 3am
## To run every time during startup:
# $Trigger = New-ScheduledTaskTrigger -AtStartup
## To run when a user logs on:
# $Trigger = New-ScheduledTaskTrigger -AtLogon
# $Settings = New-ScheduledTaskSettingsSet
# $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings
# Register-ScheduledTask -TaskName 'My PowerShell Script' -InputObject $Task -User 'username' -Password 'passhere'

## Start scheduled task
# Start-ScheduledTask -TaskName "ScanSoftware"
# Get-ScheduledTask -TaskPath "\UpdateTasks\UpdateVirus\" | Start-ScheduledTask

## Stop scheduled task
# Stop-ScheduledTask -TaskName "ScanSoftware"

## Disable-ScheduledTask -TaskName "ScanSoftware"
## Enable-ScheduledTask -TaskName "ScanSoftware"

## Export a Scheduled Task into XML File
# Export-ScheduledTask "StartupScript_PS" | Out-File c:\tmp\StartupScript_PS.xml

## Import a Scheduled Task from XML File
# Register-ScheduledTask -Xml (Get-Content "\\Srv1\public\NewPsTask.xml" | Out-String) -TaskName "NewPsTask"


## Proxy settings (need admin privileges) 
# netsh winhttp show proxy
# use ie proxy settings:
# netsh winhttp import proxy source=ie
# or:
# netsh winhttp set proxy 127.0.0.1:55881
# reset:
# netsh winhttp reset proxy

if (-Not (Get-Command -Name "check_webservice_up" 2>$null)) {
    $CUSTOM_FUNCTION="$PSScriptRoot\ps_custom_function.ps1"
    if ((Test-Path "$CUSTOM_FUNCTION") -and ((Get-Item "$CUSTOM_FUNCTION").length -gt 0)) {
        . "$CUSTOM_FUNCTION"
    }
}

# Init profile
& "$PSScriptRoot\Powershell_profile_init.ps1"


# hosts
# & "$PSScriptRoot\hosts_accelerate_cn.ps1"


# Remove built in windows 10 apps
# & "$PSScriptRoot\Remove_built-in_apps.ps1"

# Chromium
[System.Environment]::SetEnvironmentVariable("GOOGLE_API_KEY", "no", "User")
[System.Environment]::SetEnvironmentVariable("GOOGLE_DEFAULT_CLIENT_ID", "no", "User")
[System.Environment]::SetEnvironmentVariable("GOOGLE_DEFAULT_CLIENT_SECRET", "no", "User")


# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy
# Get-ExecutionPolicy -List
# Set-ExecutionPolicy (AllSigned, Bypass, Default, RemoteSigned, Restricted, Undefined, Unrestricted)
# Set-ExecutionPolicy Bypass -Scope (CurrentUser, LocalMachine, MachinePolicy, Process, UserPolicy)
# Set-ExecutionPolicy AllSigned


## Chocolatey
## https://chocolatey.org/install
# Write-Host "Installing chocolatey..." -ForegroundColor Blue
# Set-ExecutionPolicy Bypass -Scope Process -Force
# iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# if (-Not ((Get-Command "choco" -ErrorAction SilentlyContinue) -eq $null)) {
#     Write-Host "chocolatey install failed!"
# }

# if (Get-Command "choco" -ErrorAction SilentlyContinue) {
#     # # Use proxy for choco, ie: http://127.0.0.1:55881
#     # $HTTP_PROXY_ADDR = Read-Host 'Proxy address for chocolatey?[http://127.0.0.1:55881] '
#     # # if ($HTTP_PROXY_ADDR -eq "") {
#     # #     # choco config unset proxy
#     # #     $HTTP_PROXY_ADDR = "http://127.0.0.1:55881"
#     # # }
#     # if (-Not ($HTTP_PROXY_ADDR -eq "")) {
#     #     choco config set proxy $HTTP_PROXY_ADDR
#     # }

#     Write-Host "Installing chocolatey apps..." -ForegroundColor Blue
#     choco install -y chocolateygui
#     # choco upgrade -y all
# }


# Winget
# & "$PSScriptRoot\winget_install_apps.ps1"


# Scoop
# & "$PSScriptRoot\scoop_install_apps.ps1"


## ColorTool
## https://github.com/microsoft/terminal/tree/master/src/tools/ColorTool
# Write-Host "Installing ColorTool..." -ForegroundColor Blue
# $HTTP_PROXY_ADDR = Read-Host 'Proxy address for github download?[127.0.0.1:55881] '
# if (-Not ($HTTP_PROXY_ADDR -eq "")) {
#     netsh winhttp set proxy $HTTP_PROXY_ADDR
# }
# $DST_DIR = "~\tools"
# if (-Not (Test-Path $DST_DIR)) {
#     # mkdir -p $DST_DIR
#     New-Item -path $DST_DIR -type Directory | Out-Null
# }
# cd ~\tools; `
#     curl -fsSL -o ColorTool.zip `
#         https://github.com/microsoft/terminal/releases/download/1904.29002/ColorTool.zip; `
#     Expand-Archive -LiteralPath ~\tools\ColorTool.zip `
#         -DestinationPath ~\tools\ColorTool -Verbose; `
#     Remove-Item ~\tools\ColorTool.zip
# if (-Not ($HTTP_PROXY_ADDR -eq "")) {
#     netsh winhttp reset proxy
# }
# ~\tools\ColorTool\ColorTool.exe -b OneHalfDark.itermcolors


Write-Host "Done." -ForegroundColor Blue