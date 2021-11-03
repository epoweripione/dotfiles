<#
.Synopsis
    Collect Windows Features Info using DISM and Parse the string data into filterable PS Object. Across multiple computers.
    Or Use existing DISM output to parse the data without collecting
.DESCRIPTION
    This is useful when we don't have Get-WindowsFeature available on older Windows but have PowerShell.
    The output is in PSObject format which can be formatted easily.
    It can be used to fetch local or remote computer data.
    It automatically copies a current DISM raw data in a logfile.
    Can be used to re-filter the data directly, without having to fetch the data again and again.

I have used the below script as a reference on the logic.
#Windows - Ensure Features Installed
#https://library.octopusdeploy.com/#!/step-template/actiontemplate-windows-ensure-features-installed

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1
.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 | ft -AutoSize

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 | ?{$_.State -eq 'Enabled'} | ft -AutoSize

Feature                                     State  
-------                                     -----  
WindowsRemoteManagement                     Enabled
TelnetClient                                Enabled
WindowsGadgetPlatform                       Enabled
MediaPlayback                               Enabled

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 -UseLog | ?{$_.State -eq 'Disabled'} | ft -AutoSize

This can be used as a second time re-run, which will result in faster execution as it will be refering to dism.log file.
Make sure script has run atleast once without this(-UseLog) switch.

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 | ?{$_.Feature -like "Tel*"}

Feature                                                                State                                                                
-------                                                                -----                                                                
TelnetClient                                                           Enabled                                                              
TelnetServer                                                           Disabled

Filtering the output using wildcards (*)

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 -Computers Server1,Server2 -UseLog | ft -AutoSize

Calling multiple computers at a time.
.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 -UseLog -Computers Server1,Server2 | ?{$_.Feature -like "Tel*"}

State                                   ComputerName                            Feature
-----                                   ------------                            -------
Enabled                                 Server1                              TelnetClient
Disabled                                Server1                              TelnetServer
Enabled                                 Server2                              TelnetClient
Disabled                                Server2                              TelnetServer

In this example, we are reading the logs Dism_Server1.log,Dism_Server2.log which was generated automatically.

.EXAMPLE
Parse existing logs\ DISM output it needs to be starting with 'Dism_'. Like 'Dism_Filename1.log','Dism_Filename2.log' can be parsed as below.
    .\Get-DISMRemoteFeatures.ps1 -UseLog -Computers FileName1,FileName2 | ?{$_.Feature -like "Tel*"}

State                                   ComputerName                            Feature
-----                                   ------------                            -------
Enabled                                 FileName1                               TelnetClient
Disabled                                FileName1                               TelnetServer
Enabled                                 FileName2                               TelnetClient
Disabled                                FileName2                               TelnetServer

.EXAMPLE
    .\Get-DISMRemoteFeatures.ps1 -Computers (Get-Content ComputerList.txt)

Use this to pass a list of Computers using a txt file.

ComputerList.txt
Server1
Server2

.EXAMPLE
Use this to list out all the examples and help information
    Get-Help .\Get-DISMRemoteFeatures.ps1 -Full

.EXAMPLE
Use this to auto direct to the online link for this script
    help .\Get-DISMRemoteFeatures.ps1 -Online

.LINK
Supporting Online Help
https://technet.microsoft.com/en-us/library/hh852737(v=vs.85).aspx

Script Download
https://gallery.technet.microsoft.com/scriptcenter/Parse-DISM-Get-Features-d25dde0a

#>
[CmdletBinding(HelpURI="https://gallery.technet.microsoft.com/scriptcenter/Parse-DISM-Get-Features-d25dde0a")]
[OutputType([int])]
Param (
    # Set this to refer to the log file instead of running the dism again, which helps in faster execution.
    [switch]$UseLog,

    # Set one or multiple computernames, also used for refering the logfile names with -UseLog. Default target is localhost computername, looks for\creates dism_<localhostname>.log
    [string[]]$Computers = $env:COMPUTERNAME
)

# New PSObject Template
$DismObjT = New-Object –TypeName PSObject -Property @{
    "Feature" = ""
    "State" = ""
    "ComputerName" = ""
    }

# Creating Blank array for holding the result
$objResult = @()

foreach ($Computer in $Computers) {
    $LogFile = "Dism_$Computer.log"
    if ($UseLog) {  
        # Values can be fetched from Logs also, if error make sure script has run atleast once without this switch
        $List = Get-Content $LogFile
    } else {
        # Read current values
        $List = Invoke-Command -ComputerName $Computer {Dism /online /Get-Features}
        # Use this if you get WinRM errors for above line, making the script local only
        # $List = Dism /online /Get-Features

        # Save it on log file for future usage, overwrites it.
        $List | Out-File $LogFile
    }
    # Counter for getting alternate values
    $i = 1
    # Parsing the data
    # $List | Where-Object { $_.StartsWith("Feature Name :") -OR $_.StartsWith("State :") }|  #where(43ms) is slower than Select-String(20ms)
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

$objResult

<#
#Parsing the data technique2
$allFeatures = $List | Where-Object { $_.StartsWith("Feature Name") -OR $_.StartsWith("State") } 
$features = new-object System.Collections.ArrayList
for($i = 0; $i -lt $allFeatures.length; $i=$i+2) {
    $feature = $allFeatures[$i]
    $state = $allFeatures[$i+1]
    $features.add(@{Feature=$feature.split(":")[1].trim();State=$state.split(":")[1].trim()}) | OUT-NULL
}


$features


#>

