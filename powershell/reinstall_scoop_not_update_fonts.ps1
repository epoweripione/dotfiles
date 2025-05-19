#Requires -RunAsAdministrator

Param (
	[Parameter(Mandatory=$false,Position=1)]
	[string[]]$FontFilter
)

if (-Not ($FontFilter)) {
	$FontFilter = ('*lxgw*.ttf','*lxgw*.otf')
}

## colors
# [enum]::GetValues([System.ConsoleColor]) | Foreach-Object {Write-Color -Text $_ -ForegroundColor $_ }

# Install-Module -Name PSWriteColor
# Import-Module PSWriteColor
# Clear-Host

$WindowsFontDir = "$env:WINDIR\Fonts"

if($env:SCOOP_GLOBAL) {
	$ScoopInstallFontDir = "$env:SCOOP_GLOBAL"
} else {
	$ScoopInstallFontDir = "$env:ProgramData\scoop\apps"
}

$registryRoot = "HKLM"
$registryKey = "${registryRoot}:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts\"

$OldFile = "$env:TEMP\fonts_in_windows.xml"
$NewFile = "$env:TEMP\fonts_installed_by_scoop.xml"

# Compare fonts list
<#
Get-ChildItem -Recurse -Path "$WindowsFontDir" -Include $FontFilter -ErrorAction SilentlyContinue `
	| Select-Object -Property Name,FullName,Length,LastWriteTime `
	| Sort-Object -Unique Name,SideIndicator `
	| Export-Clixml "$OldFile"
#>

Get-ChildItem -Recurse -Path "$ScoopInstallFontDir" -Include $FontFilter -ErrorAction SilentlyContinue `
	| Select-Object -ExpandProperty Name `
	| ForEach-Object {
		Get-Item "$WindowsFontDir\$_" -ErrorAction SilentlyContinue | Select-Object -Property Name,FullName,Length,LastWriteTime
	} | Sort-Object -Unique Name,SideIndicator `
	| Export-Clixml "$OldFile"

Get-ChildItem -Recurse -Path "$ScoopInstallFontDir" -Include $FontFilter -ErrorAction SilentlyContinue `
	| Select-Object -Property Name,FullName,Length,LastWriteTime `
	| Sort-Object -Unique Name,SideIndicator `
	| Export-Clixml "$NewFile"

$Old = Import-Clixml "$OldFile"
$New = Import-Clixml "$NewFile"

# Compare-Object -Ref $Old -Dif $New -Property Name,Length,LastWriteTime | Sort-Object Name,SideIndicator | Format-Table -AutoSize

# Remove old fonts
Compare-Object -Ref $Old -Dif $New -Property Name,Length,LastWriteTime `
	| Select-Object -Property Name `
	| Sort-Object -Unique Name `
	| Select-Object -ExpandProperty Name `
	| ForEach-Object {
		Write-Color -Text "Removing ", "$WindowsFontDir\$_", "..." -Color Red,Yellow,Red
		$FontRegName = $_.split('.')[-2] + ' (TrueType)'
		# Write-Color -Text "Remove-ItemProperty -Path ""$registryKey"" -Name ""$FontRegName"" -Force" -Color Magenta
		Remove-ItemProperty -Path "$registryKey" -Name "$FontRegName" -Force | Out-Null
		Remove-Item "$WindowsFontDir\$_" -Force -ErrorAction SilentlyContinue
	}

# Install new fonts
Compare-Object -Ref $Old -Dif $New -Property Name,Length,LastWriteTime `
	| Select-Object -Property Name `
	| Sort-Object -Unique Name `
	| Select-Object -ExpandProperty Name `
	| ForEach-Object {
		Write-Color -Text "Copying ", "$_", " to ", "$WindowsFontDir", "..." -Color Blue,Yellow,Blue,Magenta,Blue
		$FontName = $_
		$FontRegName = $_.split('.')[-2] + ' (TrueType)'
		$FontSrc = (Get-ChildItem -Recurse -Path "$ScoopInstallFontDir" -Include "$FontName" -ErrorAction SilentlyContinue  | Select-Object -First 1).FullName
		if ($FontSrc) {
			# Write-Color -Text "New-ItemProperty -Path ""$registryKey"" -Name ""$FontRegName"" -Value ""$FontName"" -Force" -Color Magenta
			New-ItemProperty -Path "$registryKey" -Name "$FontRegName" -Value "$FontName" -Force | Out-Null
			# Write-Color -Text "Copy-Item -LiteralPath ""$FontSrc"" -Destination ""$WindowsFontDir"" -Force -ErrorAction SilentlyContinue" -Color Magenta
			Copy-Item -LiteralPath "$FontSrc" -Destination "$WindowsFontDir" -Force -ErrorAction SilentlyContinue
		}
	}

<#
Get-ChildItem -Recurse -Path "$ScoopInstallFontDir" -Include $FontFilter -ErrorAction SilentlyContinue `
	| Select-Object -Property Name,FullName,Length,LastWriteTime `
	| Sort-Object -Unique Name,SideIndicator `
	| Select-Object -ExpandProperty FullName `
	| ForEach-Object {
		Write-Color -Text "Copying ", "$_", " to ", "$WindowsFontDir", "..." -Color Blue,Yellow,Blue,Magenta,Blue
		$FontName = (Get-Item $_).Name
		$FontRegName = (Get-Item $_).Basename + ' (TrueType)'
		# Write-Color -Text "New-ItemProperty -Path ""$registryKey"" -Name ""$FontRegName"" -Value ""$FontName"" -Force" -Color Magenta
		New-ItemProperty -Path "$registryKey" -Name "$FontRegName" -Value "$FontName" -Force | Out-Null
		Copy-Item -LiteralPath "$_" -Destination "$WindowsFontDir" -Force -ErrorAction SilentlyContinue
	}
#>

Remove-Item -Path "$OldFile"
Remove-Item -Path "$NewFile"

# List installed fonts
Get-ChildItem -Recurse -Path "$WindowsFontDir" -Include $FontFilter -ErrorAction SilentlyContinue `
	| Select-Object -Property Name,FullName,Length,LastWriteTime `
	| Sort-Object -Unique Name,SideIndicator
