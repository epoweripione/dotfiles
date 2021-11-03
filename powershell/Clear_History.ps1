# notepad (Get-PSReadlineOption).HistorySavePath
# "" > (Get-PSReadlineOption).HistorySavePath

<#
# .SYNOPSIS
#  Clears the command history, including the saved-to-file history, if applicable.
#>
function Clear-SavedHistory {
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param()

    # Debugging: For testing you can simulate not having PSReadline loaded with
    #            Remove-Module PSReadline -Force
    $havePSReadline = ($null -ne (Get-Module -EA SilentlyContinue PSReadline))

    Write-Verbose "PSReadline present: $havePSReadline"
    $target = if ($havePSReadline) {
        "entire command history, including from previous sessions"
    } else {
        "command history"
    } 

    if (-Not $pscmdlet.ShouldProcess($target)) {
        return
    }

    if ($havePSReadline) {
        Clear-Host

        # Remove PSReadline's saved-history file.
        if (Test-Path (Get-PSReadlineOption).HistorySavePath) { 
            # Abort, if the file for some reason cannot be removed.
            Remove-Item -EA Stop (Get-PSReadlineOption).HistorySavePath 
            # To be safe, we recreate the file (empty). 
            $null = New-Item -Type File -Path (Get-PSReadlineOption).HistorySavePath
        }

        # Clear PowerShell's own history 
        Clear-History

        # Clear PSReadline's *session* history.
        # General caveat (doesn't apply here, because we're removing the saved-history file):
        #   * By default (-HistorySaveStyle SaveIncrementally), if you use
        #    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory(), any sensitive
        #    commands *have already been saved to the history*, so they'll *reappear in the next session*. 
        #   * Placing `Set-PSReadlineOption -HistorySaveStyle SaveAtExit` in your profile 
        #     SHOULD help that, but as of PSReadline v1.2, this option is BROKEN (saves nothing). 
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    } else {
        # Without PSReadline, we only have a *session* history.
        Clear-Host

        # Clear the doskey library's buffer, used pre-PSReadline. 
        # !! Unfortunately, this requires sending key combination Alt+F7.
        # Thanks, https://stackoverflow.com/a/13257933/45375
        $null = [system.reflection.assembly]::loadwithpartialname("System.Windows.Forms")
        [System.Windows.Forms.SendKeys]::Sendwait('%{F7 2}')

        # Clear PowerShell's own history 
        Clear-History
    }
}