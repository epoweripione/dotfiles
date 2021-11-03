# https://gist.github.com/josheinstein/9898245
#.SYNOPSIS
# Exports objects to an Excel spreadsheet by writing them to a temporary
# CSV file and using Excel automation model to import it into a workbook.
# This allows formatting to be applied to columns which would not otherwise
# be possible in a plain CSV export.
function Export-Excel {
    [CmdletBinding()]
    param(
        # The path to save the Excel spreadsheet to.
        [Parameter(Position=1)]
        [String]$Path,

        # An object or array of objects to write out to an Excel spreadsheet.
        # This parameter typically comes from pipeline input.
        [Parameter(ValueFromPipeline=$true)]
        [Object[]]$InputObject,

        # A hashtable that contains column headers as keys and
        # valid Excel format strings as values. The formats will
        # be applied to the columns after the worksheet is generated.
        [Parameter()]
        [Hashtable]$Format,

        # An array of column names to hide.
        # You should probably exclude them from the output by using the
        # Select-Object command earlier in the pipeline, but if you want them
        # to be in the spreadsheet, but simply hidden, use this parameter.
        [Parameter()]
        [String[]]$Hide,

        # Turns off column wrapping on all cells.
        [Parameter()]
        [Switch]$NoWrap,

        # Quits Excel after the spreadsheet is generated.
        # This parameter should be used with caution since Excel may already be
        # open prior to the command.
        [Parameter()]
        [Switch]$Quit
    )

    begin {
        if ($Path) {
            # If they supplied an output path, we will actually save the temp file
            # to the specified path in the format indicated by the extension. Since
            # the path will be given to Excel, we need to resolve the native path
            # in case a PowerShell path (like ~\Desktop\blah.xls) was used.
            $Path = $PSCmdlet.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

            # If the output file already exists, nuke it.
            if (Test-Path $Path -PathType Leaf) {
                Remove-Item $Path -Force
            }
        }

        # Excel VBA objects
        $Excel = $Null
        $Workbook = $Null
        $Sheet = $Null

        # Use a temporary file in the system temp directory to write the
        # results to. If it already exists, delete it.
        $ScratchName  = "Export-Excel.html"
        $ScratchPath  = "$ENV:TEMP\$ScratchName"

        Write-Verbose "Writing output to $ScratchPath"
        Remove-Item $ScratchPath -Force -ErrorAction 0

        # Create a wrapped pipeline that we can pass each input
        # object to as if it were piped directly to ConvertTo-Html.
        # We're using ConvertTo-Html because it produces a decent
        # table that Excel can open without worrying about newlines
        # in a CSV file.
        $ScriptBlock = { ConvertTo-Html -As Table -Title "Export-Excel" | Set-Content $ScratchPath -Encoding UTF8 -Force }
        $Pipeline = $ScriptBlock.GetSteppablePipeline($MyInvocation.CommandOrigin)

        $Pipeline.Begin($PSCmdlet)

        # Define some helper functions for modifying the worksheet
        # using the named column headers
        $Headers = @{}

        # Sets the display format string on columns with a given name
        function SetColumnFormat($Header, $Format) {
            if ($Headers[$Header]) {
                $Range = $Sheet.Cells.Item(1, $Headers[$Header]).EntireColumn
                try {
                    $Range.NumberFormat = $Format
                }
                catch {
                    Write-Warning "Column $Header has invalid format string: $Format ($_)"
                }
            }
        }


        # Hides columns with a given name
        function SetColumnHidden($Header) {
            if ($Headers[$Header]) {
                $Range = $Sheet.Cells.Item(1, $Headers[$Header]).EntireColumn
                try {
                    $Range.Hidden = $True
                }
                catch {
                    Write-Warning "Could not hide column $Header ($_)"
                }
            }
        }

    }

    process {
        # Not much to do here except pass the input object to the
        # wrapped pipeline which sends it to the output file.
        foreach ($o in $InputObject) {
            $Pipeline.Process($o)
        }
    }

    end {
        $Pipeline.End()
        $Pipeline.Dispose()

        # Figure out column headings and store them in a hashtable.
        # This makes it easier to refer to a column range by name.
        $i = 1
        foreach ($Match in [Regex]::Matches($(Get-Content $ScratchPath), '(?is)<TH>([^<]+)</TH>')) {
            $Headers[$Match.Groups[1].Value] = $i++
        }

        # Excel Automation
        try { 
            $Excel = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Excel.Application')
        }
        catch [System.Management.Automation.MethodInvocationException] {
            $Excel = New-Object -ComObject 'Excel.Application'
        }

        $Workbook = $Excel.Workbooks.Open($ScratchPath)
        $Sheet = $Workbook.Worksheets.Item(1)

        # Turn off cell wrapping
        if ($NoWrap) {
            $Sheet.UsedRange.WrapText = $False
        }

        # Set column formats
        foreach ($Key in $Format.Keys) {
            SetColumnFormat $Key $Format[$Key]
        }

        # Hide certain columns
        foreach ($Key in $Hide) {
            SetColumnHidden $Key
        }

        $Workbook.Activate()
        $Excel.ActiveWindow.DisplayGridlines = $true

        # Save As?
        if ($Path) {
            $FileFormat = 51
            switch ([IO.Path]::GetExtension($Path)) {
                '.xlsb' { $FileFormat = 50 } # Excel 12 Binary
                '.xlsx' { $FileFormat = 51 } # Excel 12 XML (No Macro)
                '.xlsm' { $FileFormat = 52 } # Excel 12 (With Macro)
                '.xls'  { $FileFormat = 56 } # Excel Classic
            }
            $Workbook.SaveAs($Path, $FileFormat)
        }

        if ($Quit) {
            $Excel.Quit()
        }
        else {
            $Excel.Visible = $true
            $Excel.ActiveWindow.Activate()
        }
        $Excel = $null
    }
}


# $ExcelArgs = @{
#     Verbose = $True
#     Path = "~\Desktop\EventLogs.xlsx"
#     Format = @{
#         InstanceId    = '#,##0'
#         TimeGenerated = 'm/d/yy h:mm AM/PM'
#         TimeWritten   = 'm/d/yy h:mm AM/PM'
#     }
#     Hide = ('Data','ReplacementStrings')
#     NoWrap = $True
#     Quit = $True
# }

# Get-EventLog Application -Newest 100 | Export-Excel @ExcelArgs