#Requires -RunAsAdministrator

## get a list of installed apps
# Get-AppXProvisionedPackage -Online | Select-object DisplayName | Out-File online_apps.txt
# Get-AppxPackage | Select Name, PackageFullName | Format-Table -AutoSize
# Get-AppxPackage | Select-object name | Out-File pre_installed_apps.txt

## remove pre-installed apps
# Get-AppXPackage -Name *solitairecollection* | Remove-AppXPackage


# Remove built in windows 10 apps
# https://adamtheautomator.com/remove-built-in-windows-10-apps-powershell/
Write-Host "Removing built in windows 10 apps..." -ForegroundColor Blue
$ProvisionedAppPackageNames = @(
    "Microsoft.BingFinance"
    "Microsoft.BingNews"
    "Microsoft.BingSports"
    "Microsoft.BingWeather"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.SkypeApp"
    "Microsoft.XboxApp"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.Messaging"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.Wallet"
    # "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsMaps"
)
# "Microsoft.GetHelp"
# "Microsoft.Getstarted"
# "Microsoft.Microsoft3DViewer"
# "Microsoft.MixedReality.Portal"
# "Microsoft.MSPaint"
# "Microsoft.MicrosoftStickyNotes"
# "Microsoft.Office.OneNote"
# "Microsoft.Print3D"
# "Microsoft.ScreenSketch"
# "Microsoft.Windows.Photos"
# "Microsoft.WindowsAlarms"
# "Microsoft.WindowsCalculator"
# "Microsoft.WindowsCamera"
# "Microsoft.WindowsFeedbackHub"
# "Microsoft.WindowsSoundRecorder"
# "Microsoft.YourPhone"
# "Microsoft.ZuneMusic"
# "Microsoft.ZuneVideo"
foreach ($ProvisionedAppName in $ProvisionedAppPackageNames) {
    # Write-Output "Uninstalling $ProvisionedAppName..."
    if (Get-AppxPackage -Name $ProvisionedAppName -AllUsers) {
        Write-Host "Uninstalling $ProvisionedAppName..." -ForegroundColor Blue
        Get-AppxPackage -Name $ProvisionedAppName -AllUsers | Remove-AppxPackage
        # This line removes it from being installed again
        Get-AppXProvisionedPackage -Online `
            | Where-Object DisplayName -EQ $ProvisionedAppName `
            | Remove-AppxProvisionedPackage -Online `
            | Out-Null
        # Remove app dir
        $appPath = "$Env:LOCALAPPDATA\Packages\$ProvisionedAppName*"
        Remove-Item $appPath -Recurse -Force -Confirm:$false -ErrorAction 0
    }
}

# OneDrive
function Remove_OneDrive() {
    $REMOVE_CONFIRM = "N"
    if($PROMPT_VALUE = Read-Host "Remove OneDrive?[y/N]") {
        $REMOVE_CONFIRM = $PROMPT_VALUE
    }

    if (-Not (($REMOVE_CONFIRM -eq "y") -or ($REMOVE_CONFIRM -eq "Y"))) {
        return $false
    }

    if (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe") {
        taskkill /f /im OneDrive.exe
        & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall

        # Take Ownsership of OneDriveSetup.exe
        $ACL = Get-ACL -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe
        $Group = New-Object System.Security.Principal.NTAccount("$env:UserName")
        $ACL.SetOwner($Group)
        Set-Acl -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe -AclObject $ACL

        # Assign Full R/W Permissions to $env:UserName (Administrator)
        $Acl = Get-Acl "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$env:UserName","FullControl","Allow")
        $Acl.SetAccessRule($Ar)
        Set-Acl "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" $Acl

        # Take Ownsership of OneDrive.ico
        $ACL = Get-ACL -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe
        $Group = New-Object System.Security.Principal.NTAccount("$env:UserName")
        $ACL.SetOwner($Group)
        Set-Acl -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe -AclObject $ACL

        # Assign Full R/W Permissions to $env:UserName (Administrator)
        $Acl = Get-Acl "$env:SystemRoot\SysWOW64\OneDrive.ico"
        $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$env:UserName","FullControl","Allow")
        $Acl.SetAccessRule($Ar)
        Set-Acl "$env:SystemRoot\SysWOW64\OneDrive.ico" $Acl

        REG Delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
        REG Delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f

        Remove-Item -Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue
        Write-Output "OneDriveSetup.exe Removed"
        Remove-Item -Path "$env:SystemRoot\SysWOW64\OneDrive.ico" -Force -ErrorAction SilentlyContinue
        Write-Output "OneDrive Icon Removed"
        Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "USERProfile\OneDrive Removed" 
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "LocalAppData\Microsoft\OneDrive Removed" 
        Remove-Item -Path "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "ProgramData\Microsoft OneDrive Removed" 
        Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "C:\OneDriveTemp Removed"
    }

    return $true
}

Remove_OneDrive
