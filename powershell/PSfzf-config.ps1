# [The shell prompt get offsets every time an item was accepted](https://github.com/kelleyma49/PSFzf/issues/202)
# FZF Smart Completion with Auto-Repositioning
# This module provides intelligent (lol) cursor repositioning when FZF displaces terminal content

function Invoke-CursorRepositioning {
    param(
        [Parameter(Mandatory)]
        [int]$FzfHeight,
        [Parameter(Mandatory)]
        [int]$TerminalHeight,
        [Parameter(Mandatory)]
        [int]$TerminalWidth,
        [Parameter(Mandatory)]
        [System.Management.Automation.Host.PSHostRawUserInterface]$RawUI,
        [string]$LogPath = "$env:TEMP\fzf-debug.log",
        [bool]$EnableLogging = $true,
        [string]$OperationName = "FZF Operation"
    )

    $currentPosAfter = $RawUI.CursorPosition
    $threshold = $TerminalHeight - $FzfHeight

    if ($currentPosAfter.Y -gt $threshold) {
        $newPos = $currentPosAfter
        $moveAmount = $TerminalHeight - $currentPosAfter.Y - $FzfHeight
        $newPos.Y = [Math]::Max(0, $currentPosAfter.Y + $moveAmount - 2)

        $RawUI.CursorPosition = $newPos

        if ($EnableLogging) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            "[$timestamp] Repositioned cursor after $OperationName to Y=$($newPos.Y)" | Out-File -FilePath $LogPath -Append
        }

        # Clear remnants below new position
        for ($clearLine = $newPos.Y + 1; $clearLine -lt $TerminalHeight; $clearLine++) {
            $RawUI.CursorPosition = @{ X = 0; Y = $clearLine }
            Write-Host (" " * $TerminalWidth) -NoNewline
        }

        # Redraw prompt at new position
        $RawUI.CursorPosition = $newPos
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()

        return $true  # Indicate that repositioning occurred
    }

    return $false  # No repositioning needed
}

function Invoke-PatchedFzfWrapper {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$FzfFunction,
        [string]$LogPath = "$env:TEMP\fzf-debug.log",
        [bool]$EnableLogging = $true,
        [string]$OperationName = "FZF Operation"
    )

    if ($EnableLogging) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        "[$timestamp] Executing $OperationName" | Out-File -FilePath $LogPath -Append
    }

    $rawUI = (Get-Host).UI.RawUI
    $terminalHeight = $rawUI.WindowSize.Height
    $terminalWidth = $rawUI.WindowSize.Width

    # Parse FZF height from options
    $fzfOpts = $env:_PSFZF_FZF_DEFAULT_OPTS
    if ($fzfOpts -match '--height=(\d+)%') {
        $heightPercent = [int]$matches[1]
        $fzfHeight = [Math]::Floor($terminalHeight * $heightPercent / 100)
    }
    else {
        $fzfHeight = [Math]::Floor($terminalHeight / 2)  # Default to 50%
    }

    if ($EnableLogging) {
        "[$timestamp] Terminal size: $terminalWidth x $terminalHeight" | Out-File -FilePath $LogPath -Append
        "[$timestamp] FZF height option parsed as: $fzfHeight lines" | Out-File -FilePath $LogPath -Append
    }

    # Get current cursor position to identify prompt line
    $currentPosBefore = $rawUI.CursorPosition
    $promptLine = $currentPosBefore.Y

    # For tab completion, we need to capture content changes
    $needsContentCapture = $OperationName -eq "Tab Completion"

    if ($needsContentCapture) {
        # Define capture area - content that might be displaced by FZF
        $captureStart = [Math]::Max(0, $promptLine - $fzfHeight)
        $captureEnd = $promptLine - 1

        # Capture screen content before FZF
        $beforeContent = @()
        for ($i = $captureStart; $i -lt $captureEnd; $i++) {
            try {
                $bufferCell = $rawUI.GetBufferContents([System.Management.Automation.Host.Rectangle]::new(0, $i, $terminalWidth - 1, $i))
                $lineContent = ""
                foreach ($cell in $bufferCell) {
                    $lineContent += $cell.Character
                }
                $beforeContent += $lineContent.TrimEnd()
            }
            catch {
                $beforeContent += ""
            }
        }

        if ($EnableLogging) {
            "[$timestamp] Before FZF - Content above prompt (lines $captureStart to $($captureEnd-1)):" | Out-File -FilePath $LogPath -Append
            for ($i = 0; $i -lt $beforeContent.Count; $i++) {
                "Line $($captureStart + $i): '$($beforeContent[$i])'" | Out-File -FilePath $LogPath -Append
            }
        }
    }

    # Execute the FZF function
    & $FzfFunction

    if ($needsContentCapture) {
        # Capture screen content after FZF
        $afterContent = @()
        for ($i = $captureStart; $i -lt $captureEnd; $i++) {
            try {
                $bufferCell = $rawUI.GetBufferContents([System.Management.Automation.Host.Rectangle]::new(0, $i, $terminalWidth - 1, $i))
                $lineContent = ""
                foreach ($cell in $bufferCell) {
                    $lineContent += $cell.Character
                }
                $afterContent += $lineContent.TrimEnd()
            }
            catch {
                $afterContent += ""
            }
        }

        if ($EnableLogging) {
            "[$timestamp] After FZF - Content above prompt (lines $captureStart to $($captureEnd - 1)):" | Out-File -FilePath $LogPath -Append
            for ($i = 0; $i -lt $afterContent.Count; $i++) {
                "Line $($captureStart + $i): '$($afterContent[$i])'" | Out-File -FilePath $LogPath -Append
            }
        }

        # Analyze content changes to detect if FZF UI was displayed
        $contentChanged = $false
        $newEmptyLines = 0

        for ($i = 0; $i -lt [Math]::Min($beforeContent.Count, $afterContent.Count); $i++) {
            if ($beforeContent[$i] -ne $afterContent[$i]) {
                $contentChanged = $true
            }

            # Count new empty lines that appeared (indicates content displacement)
            if ($beforeContent[$i] -ne "" -and $afterContent[$i] -eq "") {
                $newEmptyLines++
            }
        }

        if ($EnableLogging) {
            "[$timestamp] Content changed: $contentChanged, New empty lines: $newEmptyLines" | Out-File -FilePath $LogPath -Append
        }

        # Handle repositioning if FZF UI was displayed
        if ($contentChanged -or $newEmptyLines -gt 0) {
            if ($EnableLogging) {
                "[$timestamp] FZF UI detected, checking for repositioning..." | Out-File -FilePath $LogPath -Append
            }

            $repositioned = Invoke-CursorRepositioning -FzfHeight $fzfHeight -TerminalHeight $terminalHeight -TerminalWidth $terminalWidth -RawUI $rawUI -LogPath $LogPath -EnableLogging $EnableLogging -OperationName $OperationName

            if (-not $repositioned) {
                if ($EnableLogging) {
                    "[$timestamp] No repositioning needed for $OperationName" | Out-File -FilePath $LogPath -Append
                }
            }
        }
        else {
            if ($EnableLogging) {
                "[$timestamp] No content changes detected, refreshing display" | Out-File -FilePath $LogPath -Append
            }
            # Fix input update bug after accepting completion without UI
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("")
        }
    }
    else {
        # For non-tab completion operations, use the common repositioning logic
        $repositioned = Invoke-CursorRepositioning -FzfHeight $fzfHeight -TerminalHeight $terminalHeight -TerminalWidth $terminalWidth -RawUI $rawUI -LogPath $LogPath -EnableLogging $EnableLogging -OperationName $OperationName

        if (-not $repositioned -and $EnableLogging) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            "[$timestamp] No repositioning needed for $OperationName" | Out-File -FilePath $LogPath -Append
        }
    }
}

# Convenience functions for specific FZF operations
function Invoke-PatchedFzfCompletion {
    param(
        [bool]$EnableLogging = $true
    )

    Invoke-PatchedFzfWrapper -FzfFunction { Invoke-FzfTabCompletion } -EnableLogging $EnableLogging -OperationName "Tab Completion"
}

function Invoke-PatchedFzfReverseHistorySearch {
    param(
        [bool]$EnableLogging = $true
    )

    Invoke-PatchedFzfWrapper -FzfFunction { Invoke-FzfPSReadlineHandlerHistory } -EnableLogging $EnableLogging -OperationName "Reverse History Search"
}

function Invoke-PatchedFzfProviderSearch {
    param(
        [bool]$EnableLogging = $true
    )

    Invoke-PatchedFzfWrapper -FzfFunction { Invoke-FzfPSReadlineHandlerProvider } -EnableLogging $EnableLogging -OperationName "Provider Search"
}

function Invoke-PatchedFzfSetLocation {
    param(
        [bool]$EnableLogging = $true
    )

    Invoke-PatchedFzfWrapper -FzfFunction { Invoke-FzfPSReadlineHandlerSetLocation } -EnableLogging $EnableLogging -OperationName "Set Location"
}

# Register all PSFzf key handlers with smart repositioning
function Register-SmartPsFzfHandlers {
    param(
        [string]$PSReadlineChordProvider = 'Ctrl+t',
        [string]$PSReadlineChordReverseHistory = 'Ctrl+r',
        [string]$PSReadlineChordSetLocation = 'Alt+c',
        [string]$TabCompletionKey = 'Tab',
        [bool]$EnableLogging = $true
    )

    # Provider search (Ctrl+t)
    Set-PSReadLineKeyHandler -Key $PSReadlineChordProvider -ScriptBlock {
        Invoke-PatchedFzfProviderSearch -EnableLogging $EnableLogging
    }.GetNewClosure()

    # Reverse history search (Ctrl+r)
    Set-PSReadLineKeyHandler -Key $PSReadlineChordReverseHistory -ScriptBlock {
        Invoke-PatchedFzfReverseHistorySearch -EnableLogging $EnableLogging
    }.GetNewClosure()

    # Set location (Alt+c)
    Set-PSReadLineKeyHandler -Key $PSReadlineChordSetLocation -ScriptBlock {
        Invoke-PatchedFzfSetLocation -EnableLogging $EnableLogging
    }.GetNewClosure()

    # Tab completion
    Set-PSReadLineKeyHandler -Key $TabCompletionKey -ScriptBlock {
        Invoke-PatchedFzfCompletion -EnableLogging $EnableLogging
    }.GetNewClosure()
}