#Requires -RunAsAdministrator

# Scheduled Task info
$TaskName = "BypassGFWFirewall"
$TaskFile = "C:\Tools\BypassGFWFirewall.ps1"
$TaskWorkDir = "%USERPROFILE%"

$ProcessName = "naive"

$TaskTrigger = "logon" # logon, startup

# UserName & Password
$UserName = "$env:USERNAME"
$SecurePassword = Read-Host "Enter Password for ${UserName}" -AsSecureString
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
$Password = $Credentials.GetNetworkCredential().Password 

# Create schedule task
$ActionArgs = "-NonInteractive -NoLogo -NoProfile -WorkingDirectory ""${TaskWorkDir}"" -WindowStyle ""Hidden"" -File ""${TaskFile}"""
$Action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "${ActionArgs}"

# $Trigger = New-ScheduledTaskTrigger -Once -At 3am
if ($TaskTrigger -eq "logon") {
    $Trigger = New-ScheduledTaskTrigger -AtLogon
} elseif ($TaskTrigger -eq "startup") {
    $Trigger = New-ScheduledTaskTrigger -AtStartup
}

$Settings = New-ScheduledTaskSettingsSet

$Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings

Register-ScheduledTask -TaskName "${TaskName}" -InputObject $Task -User "${UserName}" -Password "${Password}"

Start-ScheduledTask -TaskName "${TaskName}"

# Get-ScheduledTask -TaskName "${TaskName}"
# Stop-ScheduledTask -TaskName "${TaskName}"
# Disable-ScheduledTask -TaskName "${TaskName}"
# Enable-ScheduledTask -TaskName "${TaskName}"


## Get a list of running processes
# tasklist | more
# Get-Process -ID <PID>
# Get-Process -Name <process-name>

## Kill a process with Taskkill
# taskkill /F /PID <PID>
# taskkill /IM <process-name> /F
# taskkill /IM naive.exe /F

## Kill a process with Stop-Process
# Stop-Process -ID <PID> -Force
# Stop-Process -Name <process-name> -Force
Get-Process -Name "${ProcessName}"
