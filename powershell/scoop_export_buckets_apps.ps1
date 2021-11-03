# https://dfinke.github.io/powershell/2019/07/31/Creating-beautiful-Powershell-Reports-in-Excel.html
# https://github.com/dfinke/ImportExcel

## To pull this together you need my PowerShell module from the PowerShell Gallery.
## If you want to view the results, you also need Microsoft Excel installed.
## Note:
## You can produce this same report with out having Excel installed.
## It’s a great feature if you want to run the data collection process unattended or on a server.
## Then you can email the result or store it on a file share.

## Install the PowerShell module from the gallery:
# Install-Module -Name ImportExcel

## Now you’re ready to run the script and get the results:
## The output of Get-Process, Get-Service, and Get-ChildItem are piped to Excel, 
## to the same workbook $xlfile.
## By not specifying a -WorkSheetName, Export-Excel will insert the data to the same sheet, 
## in this case the default Sheet1.

# $xlfile = "$env:TEMP\PSreports.xlsx"
# Remove-Item $xlfile -ErrorAction SilentlyContinue

## Get-Process
# Get-Process | Select -First 5 |
#     Export-Excel $xlfile -AutoSize -StartRow 2 -TableName ReportProcess

## Get-Service
# Get-Service | Select -First 5 |
#     Export-Excel $xlfile -AutoSize -StartRow 11 -TableName ReportService

## Directory Listing
# $excel = Get-ChildItem $env:HOMEPATH\Documents\WindowsPowerShell |
#     Select PSDRive, PSIsC*, FullName, *time* |
#     Export-Excel $xlfile -AutoSize -StartRow 20 -TableName ReportFiles -PassThru

## Get the sheet named Sheet1
# $ws = $excel.Workbook.Worksheets['Sheet1']

## Create a hashtable with a few properties
## that you'll splat on Set-Format
# $xlParams = @{WorkSheet=$ws;Bold=$true;FontSize=18;AutoSize=$true}

## Create the headings in the Excel worksheet
# Set-Format -Range A1  -Value "Report Process" @xlParams
# Set-Format -Range A10 -Value "Report Service" @xlParams
# Set-Format -Range A19 -Value "Report Files"   @xlParams

## Close and Save the changes to the Excel file
## Launch the Excel file using the -Show switch
# Close-ExcelPackage $excel -Show

if (-Not (Get-Module -ListAvailable -Name "ImportExcel")) {
    Install-Module -Name "ImportExcel" -AllowClobber
}

$xlfile = [Environment]::GetFolderPath("Desktop") + "\Scoop_All_Apps.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

$ScoopBucketPath = "$env:UserProfile\scoop\buckets"
# Get-ChildItem -Path $ScoopBucketPath -Recurse -Include "*.json" -Name |
#     Export-Excel $xlfile -AutoSize -StartRow 1 -TableName ScoopApps

$AllApps = Get-ChildItem -Path $ScoopBucketPath -Recurse `
    -Include "*.json" `
    -Exclude "package.json","extensions.json","settings.json" `
    -Depth 2 `
    -Name | Out-String
# $AllApps = $AllApps -replace "\\bucket","" -replace ".json",""

$UseJSONParser = $false
if ((Test-Path ".\json_parser.ps1") -and ((Get-Item ".\json_parser.ps1").length -gt 0)) {
    . ".\json_parser.ps1"
    $UseJSONParser = $true
}

$AppContent = "Bucket,AppName,URL,URL1,URL2,URL3"
$ScoopApps = $AllApps -split "`r`n"
$AppsCount = $ScoopApps.count
foreach ($App in $ScoopApps) {
    $CurProgress++

    if (($null -eq $App) -or ($App -eq "")) {
        continue
    }

    $AppName = $App -replace "\\bucket","" -replace "\.json",""
    if (([regex]::Matches($AppName,"\\")).count -gt 1) {
        continue
    }

    Write-Progress -Activity "Exporting..." -Status "Progress -> $AppName" `
        -PercentComplete ($CurProgress/$AppsCount * 100)

    $AppName = $AppName -replace "\\",","

    $JSONFile = $ScoopBucketPath + "\" + $App

    if ($UseJSONParser) {
        $AppJSON = JSONParser -Path $JSONFile -FirstObjectType Dictionary 6>$null

        $AppVersion = ""
        if ($AppJSON.ContainsKey("version")) {
            $AppURL = $AppJSON.version
        }

        $AppURL = ""
        if ($AppJSON.ContainsKey("architecture")) {
            if ([Environment]::Is64BitOperatingSystem) {
                if ($AppJSON.architecture.ContainsKey("64bit")) {
                    $AppURL = $AppJSON.architecture["64bit"].url | Out-String
                }
            } else {
                if ($AppJSON.architecture.ContainsKey("32bit")) {
                    $AppURL = $AppJSON.architecture["32bit"].url | Out-String
                }
            }
        }

        if (($null -eq $AppURL) -or ($AppURL -eq "")) {
            if ($AppJSON.ContainsKey("url")) {
                $AppURL = $AppJSON.url | Out-String
            }
        }    
    } else {
        $AppJSON = Get-Content -Raw -Path $JSONFile
        $AppJSON = $AppJSON -replace '"',"" -replace " ","" -replace "`r`n",""

        $AppVersion = ""
        $URLIndex = $AppJSON.IndexOf("version:")
        if ($URLIndex -ge 0) {
            $SubIndex = $AppJSON.IndexOf(",",$URLIndex)
            if ($SubIndex -ge 0) {
                $AppVersion = $AppJSON.Substring($URLIndex + 8,$SubIndex - $URLIndex - 8)
            }
        }

        $AppURL = ""
        $SubIndex = -1
        $URLIndex = $AppJSON.IndexOf("architecture:")
        if ($URLIndex -ge 0) {
            if ([Environment]::Is64BitOperatingSystem) {
                $SubIndex = $AppJSON.IndexOf("64bit:",$URLIndex)
            } else {
                $SubIndex = $AppJSON.IndexOf("32bit:",$URLIndex)
            }

            if ($SubIndex -ge 0) {
                $SubEnd = $AppJSON.IndexOf("}",$SubIndex)
                $SubIndex = $AppJSON.IndexOf("url:",$SubIndex,$SubEnd - $SubIndex - 1)
            }
        }

        if ($SubIndex -lt 0) {
            $URLIndex = $AppJSON.IndexOf("license:{")
            if ($URLIndex -ge 0) {
                $SubIndex = $AppJSON.IndexOf("},",$URLIndex)
                if ($SubIndex -ge 0) {
                    $AppJSON = $AppJSON.SubString(0,$URLIndex) + $AppJSON.SubString($SubIndex + 2)
                }
            }
            $SubIndex = $AppJSON.IndexOf("url:")
        }

        if ($SubIndex -ge 0) {
            $AppJSON = $AppJSON.SubString($SubIndex)
            $URLStart = $AppJSON.IndexOf("url:[")
            if ($URLStart -ge 0) {
                $StartLength = 5
                $URLEnd = $AppJSON.IndexOf("]",$URLStart)
            } else {
                $StartLength = 4
                $URLStart = $AppJSON.IndexOf("url:")
                $URLEnd = $AppJSON.IndexOf(",")
                if ($URLEnd -lt 0) {
                    $URLEnd = $AppJSON.IndexOf("}")
                }
            }

            $URLLength = $URLEnd - $URLStart - $StartLength
            if (($URLStart -ge 0) -and ($URLEnd -ge 0) -and ($URLLength -gt 0)) {
                $AppURL = $AppJSON.Substring($URLStart + $StartLength,$URLLength)
            }
        }
    }

    $AppURL = $AppURL -replace "}","" -replace "`r`n","," `
        -replace "#/dl.7z","" -replace "#!/dl.7z","" -replace "#dl.7z","" `
        -replace '\$version',"$AppVersion"

    $AppContent = "$AppContent`n$AppName,$AppURL"
}

## export to CSV file
# $csvfile = [Environment]::GetFolderPath("Desktop") + "\Scoop_All_Apps.csv"
# $AppContent | Out-File $csvfile

$AppsObj = ConvertFrom-Csv -InputObject $AppContent -Delimiter ','
$AppsObj | Export-Excel $xlfile -AutoSize -StartRow 1 -TableName ScoopApps

Start-Process $xlfile