#Requires -RunAsAdministrator

# Map host ip to localhost when Windows user login
# Create new schedule task at user logon
# Execute: pwsh.exe
# Argument: -Command "& {Start-Process pwsh.exe -ArgumentList '-NoProfile -Command ~\Documents\PowerShell\Scripts\wsl2-scheduled-task.ps1' -WindowStyle Hidden -Verb RunAs}"

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


$DefaultDistro = wsl --list --verbose | Where-Object {$_.trim() -Match "\*"}
# $DefaultDistro = $DefaultDistro | cut -f 1
$DefaultDistro = ($DefaultDistro -Split "\s+")[1]
$DefaultDistro = $DefaultDistro.Split([IO.Path]::GetInvalidPathChars()) -join ''

$WSLUserName = wsl -d ${DefaultDistro} /bin/bash -c "whoami"
$WSLUserName = $WSLUserName.Split([IO.Path]::GetInvalidPathChars()) -join ''


# $BashFileName="wsl2-map-win-localhost.sh"
# $BashFileName=$BashFileName.Split([IO.Path]::GetInvalidFileNameChars()) -join ''


$PhysicalAdapter = Get-NetAdapter -Name * -Physical | Where-Object Status -eq 'up' | Select-Object -ExpandProperty Name
$PhysicalAdapterIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "$PhysicalAdapter" } | Select-Object -ExpandProperty IPv4Address
if ($null -eq $PhysicalAdapterIP) {
    $PhysicalAdapter = Get-NetConnectionProfile | Where-Object { $_.IPv4Connectivity -eq "Internet" } | Select-Object -ExpandProperty InterfaceAlias
    $PhysicalAdapterIP = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -eq "$PhysicalAdapter" } | Select-Object -ExpandProperty IPv4Address
}

$BashFile = "\\wsl$\${DefaultDistro}\home\${WSLUserName}\.dotfiles\wsl\wsl2-map-win-localhost.sh"
if ($null -ne $PhysicalAdapterIP) {
    if (Test-Path "${BashFile}") {
        # wsl -d ${DefaultDistro} -u root /home/${WSLUserName}/.dotfiles/wsl/wsl2-map-win-localhost.sh ${PhysicalAdapterIP}
        wsl -d ${DefaultDistro} -u root /bin/bash -c "/home/${WSLUserName}/.dotfiles/wsl/wsl2-map-win-localhost.sh ${PhysicalAdapterIP}"
    } else {
        wsl -d ${DefaultDistro} -u root /bin/bash -c "echo """"${PhysicalAdapterIP} localhost"""" >>/etc/hosts"
    }
}
