<#

MIT License

Copyright (c) 2020 Benjamin Turmo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


    .NOTES
    ===========================================================================
        FileName:     WinFormsCreator.ps1
        Author:       PSWinFormsCreator.com Admin
        Created On:   1/15/2020
        Last Updated: 6/13/2020
        Version:      v1.0.0.1
    ===========================================================================

    .DESCRIPTION
        Use this script in the creation of other WinForms PowerShell scripts.  Has the ability to
        Save/Open a project, modify most properties of any control, and generate a script
        file.  The resulting script file initializes the Form in a STA runspace.

    .DEPENDENCIES
        PowerShell 4.0+
        .Net

    .UPDATES
    1.0.0.1 - 06/13/2020 - Added MIT License
#>

# ScriptBlock to Execute in STA Runspace
$sbGUI = {
    param($BaseDir)

    #region Functions

    function Update-ErrorLog {
        param(
            [System.Management.Automation.ErrorRecord]$ErrorRecord,
            [string]$Message,
            [switch]$Promote
        )

        if ( $Message -ne '' ) {[void][System.Windows.Forms.MessageBox]::Show("$($Message)`r`n`r`nCheck '$($BaseDir)\exceptions.txt' for details.",'Exception Occurred')}

        $date = Get-Date -Format 'yyyyMMdd HH:mm:ss'
        $ErrorRecord | Out-File "$($BaseDir)\tmpError.txt"

        Add-Content -Path "$($BaseDir)\exceptions.txt" -Value "$($date): $($(Get-Content "$($BaseDir)\tmpError.txt") -replace "\s+"," ")"

        Remove-Item -Path "$($BaseDir)\tmpError.txt"

        if ( $Promote ) {throw $ErrorRecord}
    }

    function ConvertFrom-WinFormsXML {
        param(
            [Parameter(Mandatory=$true)]$Xml,
            [string]$Reference,
            $ParentControl,
            [switch]$Suppress
        )

        try {
            if ( $Xml.GetType().Name -eq 'String' ) {$Xml = ([xml]$Xml).ChildNodes}

            $newControl = New-Object System.Windows.Forms.$($Xml.ToString())

            if ( $ParentControl ) {
                if ( $Xml.ToString() -match "^ToolStrip" ) {
                    if ( $ParentControl.GetType().Name -match "^ToolStrip" ) {[void]$ParentControl.DropDownItems.Add($newControl)} else {[void]$ParentControl.Items.Add($newControl)}
                } elseif ( $Xml.ToString() -eq 'ContextMenuStrip' ) {$ParentControl.ContextMenuStrip = $newControl}
                else {$ParentControl.Controls.Add($newControl)}
            }

            $Xml.Attributes | ForEach-Object {
                if ( $null -ne $($newControl.$($_.ToString())) ) {
                    if ( $($newControl.$($_.ToString())).GetType().Name -eq 'Boolean' ) {
                        if ( $_.Value -eq 'True' ) {$value = $true} else {$value = $false}
                    } else {$value = $_.Value}
                } else {$value = $_.Value}
                $newControl.$($_.ToString()) = $value

                if (( $_.ToString() -eq 'Name' ) -and ( $Reference -ne '' )) {
                    try {$refHashTable = Get-Variable -Name $Reference -Scope Script -ErrorAction Stop}
                    catch {
                        New-Variable -Name $Reference -Scope Script -Value @{} | Out-Null
                        $refHashTable = Get-Variable -Name $Reference -Scope Script -ErrorAction SilentlyContinue
                    }

                    $refHashTable.Value.Add($_.Value,$newControl)
                }
            }

            if ( $Xml.ChildNodes ) {$Xml.ChildNodes | ForEach-Object {ConvertFrom-WinformsXML -Xml $_ -ParentControl $newControl -Reference $Reference -Suppress}}

            if ( $Suppress -eq $false ) {return $newControl}
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered adding $($Xml.ToString()) - $($Xml.Name)"}
    }

    function Get-SpecialControl {
        param(
            [Parameter(Mandatory=$true)][hashtable]$ControlInfo,
            [string]$Reference,
            [switch]$Suppress
        )

        try {
            $refGuid = [guid]::NewGuid()
            $control = ConvertFrom-WinFormsXML -Xml "$($ControlInfo.XMLText)" -Reference $refGuid
            $refControl = Get-Variable -Name $refGuid -ValueOnly

            if ( $ControlInfo.Events ) {$ControlInfo.Events.ForEach({$refControl[$_.Name]."add_$($_.EventType)"($_.ScriptBlock)})}

            if ( $Reference -ne '' ) {New-Variable -Name $Reference -Scope Script -Value $refControl}

            Remove-Variable -Name $refGuid -Scope Script

            if ( $Suppress -eq $false ) {return $control}
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered getting special control."}
    }

    function Convert-XmlToTreeView {
        param(
            [System.Xml.XmlLinkedNode]$Xml,
            $TreeObject,
            [switch]$IncrementName
        )

        try {
            $controlType = $Xml.ToString()
            $controlName = "$($Xml.Name)"

            if ( $IncrementName ) {
                $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode
                $returnObj = [pscustomobject]@{OldName=$controlName;NewName=""}
                $loop = 1

                while ( $objRef.Objects.Keys -contains $controlName ) {
                    if ( $controlName.Contains('_') ) {
                        $afterLastUnderscoreText = $controlName -replace "$($controlName.Substring(0,($controlName.LastIndexOf('_') + 1)))"

                        if ( $($afterLastUnderscoreText -replace "\D").Length -eq $afterLastUnderscoreText.Length ) {
                            $controlName = $controlName -replace "_$($afterLastUnderscoreText)$","_$([int]$afterLastUnderscoreText + 1)"
                        } else {$controlName = $controlName + '_1'}
                    } else {$controlName = $controlName + '_1' }

                        # Make sure does not cause infinite loop
                    if ( $loop -eq 1000 ) {throw "Unable to determine incremented control name."}
                    $loop++
                }

                $returnObj.NewName = $controlName
                $returnObj
            }

            Add-TreeNode -TreeObject $TreeObject -ControlType $controlType -ControlName $controlName

            $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

            $newControl = $objRef.Objects[$controlName]

            $Xml.Attributes.GetEnumerator().ForEach({
                if ( $_.ToString() -ne 'Name' ) {
                    if ( $null -eq $objRef.Changes[$controlName] ) {$objRef.Changes[$controlName] = @{}}

                    if ( $null -ne $($newControl.$($_.ToString())) ) {
                        if ( $($newControl.$($_.ToString())).GetType().Name -eq 'Boolean' ) {
                            if ( $_.Value -eq 'True' ) {$value = $true} else {$value = $false}
                        } else {$value = $_.Value}
                    } else {$value = $_.Value}

                    $newControl.$($_.ToString()) = $value

                    $objRef.Changes[$controlName][$_.ToString()] = $_.Value
                }
            })

            if ( $Xml.ChildNodes.Count -gt 0 ) {$Xml.ChildNodes.ForEach({Convert-XmlToTreeView -Xml $_ -TreeObject $objRef.TreeNodes[$controlName] -IncrementName})}
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered adding '$($Xml.ToString()) - $($Xml.Name)' to Treeview."}
    }

    function Add-TreeNode {
        param(
            $TreeObject,
            [string]$ControlType,
            [string]$ControlName
        )

        if ( $ControlName -eq '' ) {
            $userInput = Get-UserInputFromForm

            if ( $userInput.Result -eq 'OK' ) {$ControlName = $userInput.NewName}
        }

        try {
            if ( $TreeObject.GetType().Name -eq 'TreeView' ) {
                if ( $ControlType -eq 'Form' ) {
                    $Script:refsEvents['lst_AssignedEvents'].Items.Clear()
                    $Script:refsEvents['lst_AssignedEvents'].Items.Add('No Events')
                    $Script:refsEvents['lst_AssignedEvents'].Enabled = $false

                    $newTreeNode = $TreeObject.Nodes.Add($ControlName,"Form - $($ControlName)")

                    $form = New-Object System.Windows.Forms.Form
                    $form.Name = $ControlName
                    $form.Add_FormClosing($Script:reuseEvents.FormClosing)
                    $form.Add_ReSize({$refs['PropertyGrid'].Refresh()})
                    $form.Add_ReSizeEnd($Script:reuseEvents.ReSizeEnd)

                    $Script:objRefs = @{
                        Form = @{
                            TreeNodes=@{"$($ControlName)" = $newTreeNode}
                            Objects=@{"$($ControlName)" = $form}
                            Changes=@{}
                            Events=@{}
                        }
                        ContextMenuStrip = @{}
                        Timer = @{}
                    }
                } elseif ( @('ContextMenuStrip','Timer') -contains $ControlType ) {
                    $newTreeNode = $refs['TreeView'].Nodes.Add($ControlName,"$($ControlType) - $($ControlName)")

                    $Script:objRefs[$ControlType][$ControlName] = @{
                        TreeNodes = @{"$($ControlName)" = $newTreeNode}
                        Objects = @{"$($ControlName)" = New-Object System.Windows.Forms.$ControlType}
                        Changes = @{}
                        Events = @{}
                    }
                }
            } else {
                if ( $ControlName -ne '' ) {
                    $objRef = Get-RootNodeObjRef -TreeNode $TreeObject

                    if ( $objRef.Success -ne $false ) {
                        if ( $ControlType -match "^ToolStrip" ) {
                            $newControl = New-Object System.Windows.Forms.ToolStripMenuItem
                            $newControl.Name = $ControlName

                            if ( $objRef.Objects[$TreeObject.Name].GetType().Name -match "^ToolStrip" ) {
                                [void]$objRef.Objects[$TreeObject.Name].DropDownItems.Add($newControl)
                            } else {
                                [void]$objRef.Objects[$TreeObject.Name].Items.Add($newControl)
                            }
                        } elseif ( $ControlType -eq 'ContextMenuStrip' ) {
                            $newControl = New-Object System.Windows.Forms.ContextMenuStrip
                            $newControl.Name = $ControlName
                            $refs['PropertyGrid'].SelectedObject.ContextMenuStrip = $newControl
                        } else {
                            $newControl = New-Object System.Windows.Forms.$ControlType
                            $newControl.Name = $ControlName
                            $objRef.Objects[$TreeObject.Name].Controls.Add($newControl)
                        }

                        if ( @('Form','ToolStripMenuItem','ToolStripComboBox','ToolStripTextBox','ToolStripSeparator','ContextMenuStrip') -notcontains $ControlType ) {
                            $newControl.Add_MouseDown($Script:reuseEvents.MouseDown)
                            $newControl.Add_MouseMove($Script:reuseEvents.MouseMove)
                            $newControl.Add_MouseUp($Script:reuseEvents.MouseUp)
                            $newControl.Add_MouseLeave($Script:reuseEvents.MouseLeave)
                        }

                        $newTreeNode = $TreeObject.Nodes.Add($ControlName,"$($ControlType) - $($ControlName)")
                        $objRef.TreeNodes[$ControlName] = $newTreeNode
                        $objRef.Objects[$ControlName] = $newControl
                    }
                }
            }

            if ( $newTreeNode ) {
                $newTreeNode.ContextMenuStrip = $Script:reuseContext['TreeNode']
                $Script:refs['TreeView'].SelectedNode = $newTreeNode
            }
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered adding TreeNode ($($ControlType) - $($ControlName))."}
    }

    function Get-UserInputFromForm {
        param([switch]$SetCurrent)
        try {
            $inputForm = Get-SpecialControl -ControlInfo $Script:subFormInfo['NameInput']

            if ( $inputForm ) {
                $inputForm.AcceptButton = $inputForm.Controls['StopDingOnEnter']

                if ( $SetCurrent ) {$inputForm.Controls['UserInput'].Text = $refs['TreeView'].SelectedNode.Name}

                [void]$inputForm.ShowDialog()

                $returnVal = [pscustomobject]@{
                    Result = $inputForm.DialogResult
                    NewName = $inputForm.Controls['UserInput'].Text
                }

                return $returnVal
            }
        } catch {
            Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered getting new control name."
        } finally {
            try {$inputForm.Dispose()}
            catch {if ( $_.Exception.Message -ne "You cannot call a method on a null-valued expression." ) {throw $_}}
        }
    }

    function Get-ChildNodeList {
        param(
            $TreeNode,
            [switch]$Level
        )

        $returnVal = @()

        if ( $TreeNode.Nodes.Count -gt 0 ) {
            try {
                $TreeNode.Nodes.ForEach({
                    $returnVal += $(if ( $Level ) { "$($_.Level):$($_.Name)" } else {$_.Name})
                    $returnVal += $(if ( $Level ) { Get-ChildNodeList -TreeNode $_ -Level } else { Get-ChildNodeList -TreeNode $_ })
                })
            } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered building Treenode list."}
        }

        return $returnVal
    }

    function Get-RootNodeObjRef {
        param([System.Windows.Forms.TreeNode]$TreeNode)

        try {
            if ( $TreeNode.Level -gt 0 ) {while ( $TreeNode.Parent ) {$TreeNode = $TreeNode.Parent}}

            $type = $TreeNode.Text -replace " - .*$"

            $returnVal = [pscustomobject]@{
                Success = $true
                RootType = $type
                TreeNodes = ''
                Objects = ''
                Changes = ''
                Events = ''
            }

            if ( $type -eq 'Form' ) {
                $returnVal.TreeNodes = $Script:objRefs[$type].TreeNodes
                $returnVal.Objects = $Script:objRefs[$type].Objects
                $returnVal.Changes = $Script:objRefs[$type].Changes
                $returnVal.Events = $Script:objRefs[$type].Events
            } elseif ( @('ContextMenuStrip','Timer') -contains $type ) {
                $name = $TreeNode.Text -replace "^.* - "

                $returnVal.TreeNodes = $Script:objRefs[$type][$name].TreeNodes
                $returnVal.Objects = $Script:objRefs[$type][$name].Objects
                $returnVal.Changes = $Script:objRefs[$type][$name].Changes
                $returnVal.Events = $Script:objRefs[$type][$name].Events
            } else {$returnVal.Success = $false}

            return $returnVal
        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered determining root node object reference."}
    }

    function Save-Project {
        param(
            [switch]$SaveAs,
            [switch]$Suppress,
            [switch]$ReturnXML
        )

        $projectName = $Script:refs['lbl_FormLayout'].Text

        if (( $ReturnXML -eq $false ) -and ( $SaveAs ) -or ( $projectName -eq 'NewProject.fbs' )) {
            $saveDialog = ConvertFrom-WinFormsXML -Xml @"
<SaveFileDialog InitialDirectory="$($BaseDir)\SavedProjects" AddExtension="True" DefaultExt="fbs" Filter="fbs files (*.fbs)|*.fbs" FileName="$($projectName)" OverwritePrompt="True" ValidateNames="True" RestoreDirectory="True" />
"@
            $saveDialog.Add_FileOK({
                param($Sender,$e)

                if ( $($this.FileName | Split-Path -Leaf) -eq 'NewProject.fbs' ) {
                    [void][System.Windows.Forms.MessageBox]::Show("You cannot save a project with the file name 'NewProject.fbs'",'Validation Error')
                    $e.Cancel = $true
                }
            })

            try {
                [void]$saveDialog.ShowDialog()

                if (( $saveDialog.FileName -ne '' ) -and ( $saveDialog.FileName -ne 'NewProject.fbs' )) {$projectName = $saveDialog.FileName | Split-Path -Leaf} else {$projectName = ''}
            } catch {
                Update-ErrorLog -ErrorRecord $_ -Message 'Exception encountered while selecting Save file name.'
                $projectName = ''
            }
            finally {
                $saveDialog.Dispose()
                Remove-Variable -Name saveDialog
            }
        }

        if ( $projectName -ne '' ) {
            try {
                $xml = New-Object -TypeName XML
                $xml.LoadXml('<Data><Items Desc="For any control that has Items collection"></Items><Events Desc="Events associated with controls"></Events></Data>')

                $Script:objRefs.Form.Objects.GetEnumerator() | ForEach-Object {
                    $name = $_.Name
                    $type = $_.Value.GetType().Name

                    if ( $null -eq $Script:objRefs.Form.Changes[$name] ) {$Script:objRefs.Form.Changes[$name] = @{}}

                    $defaultControl = $Script:supportedControls.Where({ $_.Name -eq $type }).DefaultObject

                    $defaultSize = "$($defaultControl.Size.Width), $($defaultControl.Size.Height)"
                    $currentSize = "$($Script:objRefs.Form.Objects[$name].Size.Width), $($Script:objRefs.Form.Objects[$name].Size.Height)"
                    if ( $objRefs.Form.Changes[$name].Size ) {$oldSize = $objRefs.Form.Changes[$name].Size} else {$oldSize = $defaultSize}

                    if ( $currentSize -ne $oldSize ) {
                        if ( $currentSize -ne $defaultSize ) {
                            if ( ( $Script:objRefs.Form.Objects[$name].AutoSize -eq $false ) -or
                                 ( $null -eq $Script:objRefs.Form.Objects[$name].AutoSize ) -or
                                 ( $Script:objRefs.Form.Objects[$name].Dock -ne 'Fill' ) ) {

                                $Script:objRefs.Form.Changes[$name].Size = $currentSize
                            } else {
                                if ( $Script:objRefs.Form.Changes[$name].Size ) {$Script:objRefs.Form.Changes[$name].Remove('Size')}
                            }
                        } else {
                            if ( $Script:objRefs.Form.Changes[$name].Size ) {$Script:objRefs.Form.Changes[$name].Remove('Size')}
                        }
                    }

                    $defaultLocation = "$($defaultControl.Location.X), $($defaultControl.Location.Y)"
                    $currentLocation = "$($Script:objRefs.Form.Objects[$name].Location.X), $($Script:objRefs.Form.Objects[$name].Location.Y)"
                    if ( $objRefs.Form.Changes[$name].Location ) {$oldLocation = $objRefs.Form.Changes[$name].Location} else {$oldLocation = $defaultLocation}

                    if ( $currentLocation -ne $oldLocation ) {
                        if ( $currentLocation -ne $defaultLocation ) {
                            if (( $Script:objRefs.Form.Objects[$name].Dock -eq 'None' ) -or ( $null -eq $Script:objRefs.Form.Objects[$name].Dock )) {
                                if (( $type -eq 'Form' ) -and ( $Script:objRefs.Form.Objects[$name].StartPosition -ne 'Manual' )) {
                                    if ( $Script:objRefs.Form.Changes[$name].Location ) {$Script:objRefs.Form.Changes[$name].Remove('Location')}
                                } else {
                                    $Script:objRefs.Form.Changes[$name].Location = $currentLocation
                                }
                            }
                        } else {
                            if ( $Script:objRefs.Form.Changes[$name].Location ) {$Script:objRefs.Form.Changes[$name].Remove('Location')}
                        }
                    }

                    if ( $Script:objRefs.Form.Changes[$name].Count -eq 0 ) {$Script:objRefs.Form.Changes.Remove($name)}
                }

                $refs['TreeView'].Nodes.ForEach({
                    $currentNode = $xml.Data
                    $rootControlType = $_.Text -replace " - .*$"
                    $rootControlName = $_.Name

                    $objRef = Get-RootNodeObjRef -TreeNode $($refs['TreeView'].Nodes | Where-Object { $_.Name -eq $rootControlName -and $_.Text -match "^$($rootControlType)" })

                    $nodeIndex = @("0:$($rootControlName)")
                    $nodeIndex += @(Get-ChildNodeList -TreeNode $objRef.TreeNodes[$rootControlName] -Level)

                    @(0..($nodeIndex.Count-1)).ForEach({
                        $nodeName = $nodeIndex[$_] -replace "^\d+:"
                        $newElementType = $objRef.TreeNodes[$nodeName].Text -replace " - .*$"
                        [int]$nodeDepth = $nodeIndex[$_] -replace ":.*$"
                        $newElement = $xml.CreateElement($newElementType)
                        $newElement.SetAttribute("Name",$nodeName)

                        if ( $objRef.Changes[$nodeName] ) {
                            $objRef.Changes[$nodeName].GetEnumerator().Name | ForEach-Object {
                                $newElement.SetAttribute("$($_)",$objRef.Changes[$nodeName][$_])
                            }
                        }

                        [void]$currentNode.AppendChild($newElement)

                        if ( $objRef.Events[$nodeName] ) {
                            $newEventElement = $xml.CreateElement($newElementType)
                            $newEventElement.SetAttribute('Name',$nodeName)
                            $newEventElement.SetAttribute('Root',"$($objRef.RootType)|$rootControlName")

                            $eventString = ''
                            $objRef.Events[$nodeName].ForEach({$eventString += "$($_) "})

                            $newEventElement.SetAttribute('Events',$($eventString -replace " $"))

                            [void]$xml.Data.Events.AppendChild($newEventElement)
                        }

                        if ( $objRef.Objects[$nodeName].Items.Count -gt 0 ) {
                            if ( @('ListBox','ComboBox','ToolStripComboBox') -contains $newElementType ) {
                                $newItems = $xml.CreateElement($newElementType)
                                $newItems.SetAttribute('Name',$nodeName)
                                $newItems.SetAttribute('Root',"$($objRef.RootType)|$rootControlName")

                                $objRef.Objects[$nodeName].Items.ForEach({
                                    $item = $xml.CreateElement("$($newElementType)Item")
                                    $item.SetAttribute('Text',"$($_)")
                                    [void]$newItems.AppendChild($item)
                                })

                                [void]$xml.Data.Items.AppendChild($newItems)
                            } else {
                                switch ($newElementType) {
                                    'MenuStrip' {}
                                    'ContextMenuStrip' {}
                                    default {[void][System.Windows.Forms.MessageBox]::Show("$($newElementType) items will not save",'Notification')}
                                }
                            }
                        }

                        if ( $_ -lt ($nodeIndex.Count-1) ) {
                            [int]$nextNodeDepth = "$($nodeIndex[($_+1)] -replace ":.*$")"

                            if ( $nextNodeDepth -gt $nodeDepth ) {$currentNode = $newElement}
                            elseif ( $nextNodeDepth -lt $nodeDepth ) {@(($nodeDepth-1)..$nextNodeDepth).ForEach({$currentNode = $currentNode.ParentNode})}
                        }
                    })
                })

                if ( $ReturnXML ) {return $xml}
                else {
                    $xml.Save("$($Script:projectsDir)\$($projectName)")

                    $Script:refs['lbl_FormLayout'].Text = $projectName

                    if ( $Suppress -eq $false ) {[void][System.Windows.Forms.MessageBox]::Show('Successfully Saved!','Success')}
                }
            } catch {
                if ( $ReturnXML ) {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while generating Form XML."}
                else {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while saving project."}
            }
        } else {throw 'SaveCancelled'}
    }

    #endregion

    #region Event ScriptBlocks

    $eventSB = @{
        'MainForm' = @{
            Activated = {
                if ( $Script:formActivated -eq $false ) {
                    $Script:formActivated = $true
                    $Script:refsTools['Toolbox'].Visible = $true
                    $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($this.Location.X - 334),$this.Location.Y)
                    $Script:refsEvents['Events'].Visible = $true
                    $refs['TreeView'].Focus()
                }
            }
            FormClosing = {
                try {
                    $Script:refs['TreeView'].Nodes.ForEach({
                        $controlName = $_.Name
                        $controlType = $_.Text -replace " - .*$"

                        if ( $controlType -eq 'Form' ) {$Script:objRefs.Form.Objects[$controlName].Dispose()}
                        else {$Script:objRefs[$controlType][$controlName].Objects[$controlName].Dispose()}
                    })

                    $Script:refsTools['Toolbox'].Dispose()
                    $Script:refsEvents['Events'].Dispose()
                    if ( $Script:refsGenerate ) {$Script:refsGenerate['Generate'].Dispose()}
                } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Form closure."}
            }
            Resize = {
                $Script:refsTools['Toolbox'].Size = New-Object System.Drawing.Size($Script:refsTools['Toolbox'].Size.Width,$($Script:refs['MainForm'].Size.Height - 8))
                $Script:refsEvents['Events'].Size = New-Object System.Drawing.Size($Script:refsEvents['Events'].Size.Width,$($Script:refs['MainForm'].Size.Height - 8))
            }
            LocationChanged = {
                $Script:refsTools['Toolbox'].Location = New-Object System.Drawing.Size(($Script:refs['MainForm'].Location.X - 167),$Script:refs['MainForm'].Location.Y)

                if ( $Script:refsTools['Toolbox'].Visible -eq $true ) {$xPos = 334} else {$xPos = 167}
                $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($Script:refs['MainForm'].Location.X - $xPos),$Script:refs['MainForm'].Location.Y)
            }
        }
        'New' = @{
            Click = {
                try {
                    if ( [System.Windows.Forms.MessageBox]::Show("Unsaved changes to the current project will be lost.  Are you sure you want to start a new project?", 'Confirm', 4) -eq 'Yes' ) {
                        $Script:refs['TreeView'].Nodes.ForEach({
                            $controlName = $_.Name
                            $controlType = $_.Text -replace " - .*$"

                            if ( $controlType -eq 'Form' ) {$Script:objRefs.Form.Objects[$controlName].Dispose()}
                            else {$Script:objRefs[$controlType][$controlName].Objects[$ControlName].Dispose()}
                        })

                        $Script:refs['TreeView'].Nodes.Clear()
                        $Script:refs['lbl_FormLayout'].Text = 'NewProject.fbs'

                        Add-TreeNode -TreeObject $Script:refs['TreeView'] -ControlType Form -ControlName MainForm

                        $refs['FormPreview'].Checked = $false
                    }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during start of New Project."}
            }
        }
        'Open' = @{
            Click = {
                if ( [System.Windows.Forms.MessageBox]::Show("You will lose all changes to the current project.  Are you sure?", 'Confirm', 4) -eq 'Yes' ) {
                    $openDialog = ConvertFrom-WinFormsXML -Xml @"
<OpenFileDialog InitialDirectory="$($Script:projectsDir)" AddExtension="True" DefaultExt="fbs" Filter="fbs files (*.fbs)|*.fbs" FilterIndex="1" ValidateNames="True" CheckFileExists="True" RestoreDirectory="True" />
"@
                    try {
                        $Script:openingProject = $true

                        if ( $openDialog.ShowDialog() -eq 'OK' ) {
                            $fileName = $openDialog.FileName

                            New-Object -TypeName XML | ForEach-Object {
                                $_.Load("$($fileName)")

                                $Script:refs['TreeView'].BeginUpdate()

                                $Script:refs['TreeView'].Nodes.ForEach({
                                    $controlName = $_.Name
                                    $controlType = $_.Text -replace " - .*$"

                                    if ( $controlType -eq 'Form' ) {$Script:objRefs.Form.Objects[$controlName].Dispose()}
                                    else {$Script:objRefs[$controlType][$controlName].Objects[$ControlName].Dispose()}
                                })

                                $Script:refs['TreeView'].Nodes.Clear()
                                $Script:refs['lbl_FormLayout'].Text = "$($fileName|Split-Path -Leaf)"

                                Convert-XmlToTreeView -XML $_.Data.Form -TreeObject $Script:refs['TreeView']

                                if ( $_.Data.ContextMenuStrip ) {
                                    $_.Data.ChildNodes | Where-Object { $_.ToString() -eq 'ContextMenuStrip' } | ForEach-Object {
                                        Convert-XmlToTreeView -XML $_ -TreeObject $Script:refs['TreeView']
                                    }
                                }

                                if ( $_.Data.Timer ) {
                                    $_.Data.ChildNodes | Where-Object { $_.ToString() -eq 'Timer' } | ForEach-Object {
                                        Convert-XmlToTreeView -XML $_ -TreeObject $Script:refs['TreeView']
                                    }
                                }

                                $Script:refs['TreeView'].EndUpdate()

                                if ( $_.Data.Events.ChildNodes.Count -gt 0 ) {
                                    $_.Data.Events.ChildNodes | ForEach-Object {
                                        $rootControlType = $_.Root.Split('|')[0]
                                        $rootControlName = $_.Root.Split('|')[1]
                                        $controlName = $_.Name

                                        if ( $rootControlType -eq 'Form' ) {
                                            $Script:objRefs.Form.Events[$controlName] = @()
                                            $_.Events.Split(' ') | ForEach-Object {$Script:objRefs.Form.Events[$controlName] += $_}
                                        } else {
                                            $Script:objRefs[$rootControlType][$rootControlName].Events[$controlName] = @()
                                            $_.Events.Split(' ') | ForEach-Object {$Script:objRefs[$rootControlType][$rootControlName].Events[$controlName] += $_}
                                        }
                                    }
                                }
                            }

                            $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                            if ( $objRef.Events[$refs['TreeView'].SelectedNode.Name] ) {
                                $Script:refsEvents['lst_AssignedEvents'].BeginUpdate()
                                $Script:refsEvents['lst_AssignedEvents'].Items.Clear()

                                [void]$Script:refsEvents['lst_AssignedEvents'].Items.AddRange($objRef.Events[$refs['TreeView'].SelectedNode.Name])

                                $Script:refsEvents['lst_AssignedEvents'].EndUpdate()

                                $Script:refsEvents['lst_AssignedEvents'].Enabled = $true
                            }
                        }

                        $refs['TreeView'].SelectedNode = $refs['TreeView'].Nodes | Where-Object { $_.Text -match "^Form - " }
                        $refs['FormPreview'].Checked = $false
                    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while opening $($fileName)."}
                    finally {
                        $Script:openingProject = $false

                        $openDialog.Dispose()
                        Remove-Variable -Name openDialog

                        $refs['TreeView'].Focus()
                    }
                }
            }
        }
        'Move Up' = @{
            Click = {
                try {
                    $selectedNode = $Script:refs['TreeView'].SelectedNode
                    $objRef = Get-RootNodeObjRef -TreeNode $selectedNode
                    $nodeName = $selectedNode.Name
                    $nodeIndex = $selectedNode.Index

                    if ( $nodeIndex -gt 0 ) {
                        $parentNode = $selectedNode.Parent
                        $clone = $selectedNode.Clone()

                        $parentNode.Nodes.Remove($selectedNode)
                        $parentNode.Nodes.Insert($($nodeIndex-1),$clone)

                        $objRef.TreeNodes[$nodeName] = $parentNode.Nodes[$($nodeIndex-1)]
                        $Script:refs['TreeView'].SelectedNode = $objRef.TreeNodes[$nodeName]
                    }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message 'Exception encountered increasing index of TreeNode.'}
            }
        }
        'Move Down' = @{
            Click = {
                try {
                    $selectedNode = $Script:refs['TreeView'].SelectedNode
                    $objRef = Get-RootNodeObjRef -TreeNode $selectedNode
                    $nodeName = $selectedNode.Name
                    $nodeIndex = $selectedNode.Index

                                                    if ( $nodeIndex -lt $($selectedNode.Parent.Nodes.Count - 1) ) {
                    $parentNode = $selectedNode.Parent
                    $clone = $selectedNode.Clone()

                    $parentNode.Nodes.Remove($selectedNode)
                    if ( $nodeIndex -eq $($parentNode.Nodes.Count - 1) ) {$parentNode.Nodes.Add($clone)}
                    else {$parentNode.Nodes.Insert($($nodeIndex+1),$clone)}

                    $objRef.TreeNodes[$nodeName] = $parentNode.Nodes[$($nodeIndex+1)]
                    $Script:refs['TreeView'].SelectedNode = $objRef.TreeNodes[$nodeName]
                }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message 'Exception encountered decreasing index of TreeNode.'}
            }
        }
        'CopyNode' = @{
            # Make sure that removed from $nodeClipboard if deleted
            Click = {
                if ( $Script:refs['TreeView'].SelectedNode.Level -gt 0 ) {
                    $Script:nodeClipboard = @{
                        ObjRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode
                        Node = $refs['TreeView'].SelectedNode
                    }
                } else {[void][System.Windows.Forms.MessageBox]::Show('You cannot copy a root node.  It will be necessary to copy each individual subnode separately after creating the root node manually, if not a Form.')}
            }
        }
        'PasteNode' = @{
            Click = {
                try {
                    if ( $Script:nodeClipboard ) {
                        $pastedType = $Script:nodeClipboard.Node.Text -replace " - .*$"
                        $controlType = $refs['TreeView'].SelectedNode.Text -replace " - .*$"

                        if ( $Script:supportedControls.Where({$_.Name -eq $controlType}).ChildTypes -contains $Script:supportedControls.Where({$_.Name -eq $pastedType}).Type ) {
                            $pastedName = $Script:nodeClipboard.Node.Name
                            $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                            $rootNode = $refs['TreeView'].SelectedNode
                            while ( $rootNode.Level -gt 0 ) {$rootNode = $rootNode.Parent}
                            $rootNodeType = $rootNode.Text -replace " - .*$"

                            $xml = Save-Project -ReturnXML
                            $rootXml = $xml.Data.ChildNodes.Where({$_.ToString() -eq "$($rootNodeType)" -and $_.Name -eq "$($rootNode.Name)"})
                            $pasteXml = Select-Xml -Xml $rootXml -XPath "//$($pastedType)[@Name=`"$($pastedName)`"]"

                            $Script:refs['TreeView'].BeginUpdate()

                            [array]$newNodeNames = Convert-XmlToTreeView -TreeObject $refs['TreeView'].SelectedNode -Xml $pasteXml.Node -IncrementName

                            $Script:refs['TreeView'].EndUpdate()

                            $newNodeNames.ForEach({if ( $Script:nodeClipboard.ObjRef.Events["$($_.OldName)"] ) {$objRef.Events["$($_.NewName)"] = $Script:nodeClipboard.ObjRef.Events["$($_.OldName)"]}})
                        } else {[void][System.Windows.Forms.MessageBox]::Show("You cannot paste a $($pastedType) control to the selected control type $($controlType).")}
                    }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message 'Exception encountered while pasting node from clipboard.'}
            }
        }
        'Rename' = @{
            Click = {
                $userInput = Get-UserInputFromForm -SetCurrent

                if ( $userInput.Result -eq 'OK' ) {
                    try {
                        $currentName = $Script:refs['TreeView'].SelectedNode.Name
                        $newName = $userInput.NewName

                        $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                        $objRef.Objects[$currentName].Name = $newName
                        $objRef.Objects[$newName] = $objRef.Objects[$currentName]
                        $objRef.Objects.Remove($currentName)

                        if ( $objRef.Changes[$currentName] ) {
                            $objRef.Changes[$newName] = $objRef.Changes[$currentName]
                            $objRef.Changes.Remove($currentName)
                        }

                        if ( $objRef.Events[$currentName] ) {
                            $objRef.Events[$newName] = $objRef.Events[$currentName]
                            $objRef.Events.Remove($currentName)
                        }

                        $objRef.TreeNodes[$currentName].Name = $newName
                        $objRef.TreeNodes[$currentName].Text = $Script:refs['TreeView'].SelectedNode.Text -replace "-.*$","- $($newName)"
                        $objRef.TreeNodes[$newName] = $objRef.TreeNodes[$currentName]
                        $objRef.TreeNodes.Remove($currentName)
                    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered renaming '$($refs['TreeView'].SelectedNode.Text)'."}
                }
            }
        }
        'Delete' = @{
            Click = {
                try {
                    $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                    if (( $objRef.Success -eq $true ) -and ( $Script:refs['TreeView'].SelectedNode.Level -ne 0 ) -or ( $objRef.RootType -ne 'Form' )) {
                        if ( [System.Windows.Forms.MessageBox]::Show("Are you sure you wish to remove the selected node and all child nodes? This cannot be undone." ,"Confirm Removal" , 4) -eq 'Yes' ) {
                            $nodesToDelete = @($($Script:refs['TreeView'].SelectedNode).Name)
                            $nodesToDelete += Get-ChildNodeList -TreeNode $Script:refs['TreeView'].SelectedNode

                            (($nodesToDelete.Count-1)..0).ForEach({
                                $objRef.Objects[$nodesToDelete[$_]].Dispose()
                                $objRef.Objects.Remove($nodesToDelete[$_])

                                $objRef.TreeNodes[$nodesToDelete[$_]].Remove()
                                $objRef.TreeNodes.Remove($nodesToDelete[$_])

                                if ( $objRef.Changes[$nodesToDelete[$_]] ) {$objRef.Changes.Remove($nodesToDelete[$_])}
                                if ( $objRef.Events[$nodesToDelete[$_]] ) {$objRef.Events.Remove($nodesToDelete[$_])}
                            })
                        }
                    } else {[void][System.Windows.Forms.MessageBox]::Show('Cannot delete the root Form.  Start a New Project instead.')}
                } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered deleting '$($refs['TreeView'].SelectedNode.Text)'."}
            }
        }
        'Toolbox' = @{
            Click = {
                $refForm = $Script:refs['MainForm']

                if ( $Script:refsTools['Toolbox'].Visible -eq $false ) {
                    $this.Checked = $true

                    $Script:refsTools['Toolbox'].Location = New-Object System.Drawing.Size(($refForm.Location.X - 167),$refForm.Location.Y)
                    $Script:refsTools['Toolbox'].Size = New-Object System.Drawing.Size($Script:refsTools['Toolbox'].Size.Width,($refForm.Size.Height-8))

                    if ( $Script:refsEvents['Events'].Visible -eq $true ) {
                        $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($refForm.Location.X - 334),$refForm.Location.Y)
                    }

                    $Script:refsTools['Toolbox'].Visible = $true

                    $Script:refs['MainForm'].Activate()
                } else {
                    if ( $Script:refsEvents['Events'].Visible -eq $true ) {
                        $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($refForm.Location.X - 167),$refForm.Location.Y)
                    }

                    $this.Checked = $false
                    $Script:refsTools['Toolbox'].Visible = $false
                }
            }
        }
        'Events' = @{
            Click = {
                if ( $Script:refsEvents['Events'].Visible -eq $false ) {
                    $this.Checked = $true
                    $refForm = $Script:refs['MainForm']

                    if ( $Script:refsTools['Toolbox'].Visible -eq $true ) {$xPos = 334} else {$xPos = 167}
                    $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($refForm.Location.X - $xPos),$refForm.Location.Y)
                    $Script:refsEvents['Events'].Size = New-Object System.Drawing.Size($Script:refsEvents['Events'].Size.Width,($refForm.Size.Height-8))

                    $Script:refsEvents['Events'].Visible = $true

                    $Script:refs['MainForm'].Activate()
                } else {
                    $this.Checked = $false
                    $Script:refsEvents['Events'].Visible = $false
                }
            }
        }
        'FormPreview' = @{
            Click = {
                $form = $Script:objRefs.Form.Objects[$($Script:refs['TreeView'].Nodes | Where-Object { $_.Text -match "^Form - " }).Name]

                if ( $form.Visible -eq $false ) {
                    $this.Checked = $true
                    $form.Visible = $true
                } else {
                    $this.Checked = $false
                    $form.Visible = $false
                }
            }
        }
        'Generate Script File' = @{
            Click = {
                if ( [System.Windows.Forms.MessageBox]::Show('Before generating the script file changes will need to be saved.  Would you like to continue?', 'Confirm', 4) -eq 'Yes' ) {
                    try {
                        Save-Project -Suppress

                        if ( $null -eq $Script:refsGenerate ) {
                            Get-SpecialControl -ControlInfo $Script:subFormInfo['Generate'] -Reference refsGenerate
                            $Script:subFormInfo.Remove('Generate')
                        }

                        $Script:refsGenerate['Generate'].DialogResult = 'Cancel'
                        $Script:refsGenerate['Generate'].AcceptButton = $Script:refsGenerate['btn_Generate']

                        $projectName = $Script:refs['lbl_FormLayout'].Text -replace "^Form Layout - "
                        $projectFilePath = "$($Script:projectsDir)\$($projectName)"
                        $generationPath = "$($Script:projectsDir)\$($projectName -replace "\..*$")"

                        $xmlText = Get-Content -Path "$($projectFilePath)"
                        [xml]$xml = $xmlText

                        if ( $xml.Data.Events.ChildNodes.Count -gt 0 ) {$Script:refsGenerate['cbx_Events'].Enabled = $true} else {$Script:refsGenerate['cbx_Events'].Enabled = $false}
                        if ( $Script:refsGenerate['gbx_SubForms'].Controls.Count -gt 2 ) {$Script:refsGenerate['cbx_Subforms'].Enabled = $true} else {$Script:refsGenerate['cbx_Subforms'].Enabled = $false}
                        if ( $xml.Data.ContextMenuStrip ) {$Script:refsGenerate['cbx_ReuseContext'].Enabled = $true} else {$Script:refsGenerate['cbx_ReuseContext'].Enabled = $false}
                        if ( $xml.Data.Timer ) {$Script:refsGenerate['cbx_Timers'].Enabled = $true} else {$Script:refsGenerate['cbx_Timers'].Enabled = $false}

                        if ( $Script:refsGenerate['Generate'].ShowDialog() -eq 'OK' ) {
                            if ( (Test-Path -Path "$($generationPath)" -PathType Container) -eq $false ) {New-Item -Path "$($generationPath)" -ItemType Directory | Out-Null}

                            $indexFormStart = [array]::IndexOf($xmlText,$xmlText -match "^  <Form ")
                            $indexFormEnd = [array]::IndexOf($xmlText,"  </Form>")
                            $formText = $xmlText[$($indexFormStart)..$($indexFormEnd)]

                                # Start script generation
                            $scriptText = New-Object System.Collections.Generic.List[String]

                            $scriptText += $Script:templateText.First

                            $scriptText[3] = $scriptText[3] -replace 'FNAME',"$($projectName -replace "fbs$","ps1")"
                            $scriptText[4] = $scriptText[4] -replace 'NETNAME',"$($env:USERNAME)"
                            $scriptText[5] = $scriptText[5] -replace "  DATE","  $(Get-Date -Format 'yyyy/MM/dd')"
                            $scriptText[6] = $scriptText[6] -replace "  DATE","  $(Get-Date -Format 'yyyy/MM/dd')"

                                # Functions
                            $scriptText += $Script:templateText.StartRegion_Functions

                            if (( $Script:refsGenerate['gbx_SubForms'].Controls.Count -gt 2 ) -or ( $xml.Data.ChildNodes.Count -gt 3 )) {$scriptText += $Script:templateText.Function_GetSpecialControl}

                            $scriptText += $Script:templateText.EndRegion_Functions

                                # Event Scriptblocks
                            if ( $($xml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" }) ) {
                                $scriptText += $Script:templateText.StartRegion_Events

                                $xml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" } | ForEach-Object {
                                    $name = $_.Name

                                    $scriptText += "        '$name' = @{"

                                    $_.Events -Split ' ' | ForEach-Object {
                                        $scriptText += @(
                                            "            $_ = {",
                                            "",
                                            "            }"
                                        )
                                    }

                                    $scriptText += "        }"
                                }

                                $scriptText += $Script:templateText.EndRegion_Events
                            }

                                # Sub Forms
                            if ( $Script:refsGenerate['gbx_SubForms'].Controls.Count -gt 2 ) {
                                $scriptText += $Script:templateText.StartRegion_SubForms

                                (1..$(($Script:refsGenerate['gbx_SubForms'].Controls | Where-Object { $_.Name -match "tbx_SubForm" }).Count - 1)).ForEach({
                                    $controlName = "tbx_SubForm$($_)"

                                    $subXmlText = Get-Content -Path "$($($Script:refsGenerate['gbx_SubForms'].Controls[$controlName]).Tag)"

                                    $indexFormStart = [array]::IndexOf($subXmlText,$subXmlText -match "^  <Form ")
                                    $indexFormEnd = [array]::IndexOf($subXmlText,"  </Form>")
                                    $subFormText = $subXmlText[$($indexFormStart)..$($indexFormEnd)]

                                    $subXml = New-Object -TypeName Xml
                                    $subXml.LoadXml($subXmlText)

                                    $subFormName = $subXml.Data.Form.Name

                                    $scriptText += @(
                                        "        '$subFormName' = @{",
                                        "            XMLText = @`""
                                    )

                                    $scriptText += $subFormText

                                    $scriptText += "`"@"

                                    if ( ($subXml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" }) ) {
                                        $scriptText += '            Events = @('

                                        $subXml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" } | ForEach-Object {
                                            $name = $_.Name

                                            $_.Events -Split ' ' | ForEach-Object {
                                                $scriptText += @(
                                                    "                [pscustomobject]@{",
                                                    "                    Name = '$($name)'",
                                                    "                    EventType = '$($_)'",
                                                    "                    ScriptBlock = {",
                                                    "",
                                                    "                    }",
                                                    "                },"
                                                )
                                            }
                                        }

                                        $scriptText[-1] = $scriptText[-1] -replace ","

                                        $scriptText += "            )`n        }"
                                    }
                                })

                                $scriptText += $Script:templateText.EndRegion_SubForms
                            }

                                # Timers / Reusable ContextMenuStrips
                            @('Timer','ContextMenuStrip').ForEach({
                                $childTypeName = $_

                                if ( $xml.Data.$childTypeName ) {
                                    $scriptText += $Script:templateText."StartRegion_$($childTypeName)s"

                                    $xml.Data.$childTypeName | ForEach-Object {
                                        $controlName = $_.Name
                                        $startIndex = [array]::IndexOf($xmlText,$xmlText -match "^  <$($childTypeName) Name=`"$($controlName)`"")
                                        $keepProcessing = $true
                                        $controlText = @()

                                        ($startIndex..$($xmlText.Count - 2)).ForEach({
                                            if ( $keepProcessing ) {
                                                if (( $xmlText[$_] -eq "  </$($childTypeName)>" ) -or ( $xmlText[$_] -match "^  <$($childTypeName).*/>$" )) {$keepProcessing = $false}

                                                $controlText += $xmlText[$_]
                                            }
                                        })

                                        $scriptText += @("        '$controlName' = @{","            XMLText = @`"")

                                        $scriptText += $controlText

                                        $scriptText += "`"@"

                                        if ( $xml.Data.Events.ChildNodes | Where-Object { $_.Root -eq "$($childTypeName)|$($controlName)" } ) {
                                            $scriptText += '            Events = @('

                                            $xml.Data.Events.ChildNodes | Where-Object { $_.Root -match "$($childTypeName)|$($controlName)" } | ForEach-Object {
                                                $name = $_.Name

                                                $_.Events -Split ' ' | ForEach-Object {
                                                    $scriptText += @(
                                                        "                [pscustomobject]@{",
                                                        "                    Name = '$($name)'",
                                                        "                    EventType = '$($_)'",
                                                        "                    ScriptBlock = {",
                                                        "",
                                                        "                    }",
                                                        "                },"
                                                    )
                                                }
                                            }

                                            $scriptText[-1] = $scriptText[-1] -replace ","

                                            $scriptText += "            )`n        }"
                                        }
                                    }

                                    $scriptText += $Script:templateText."EndRegion_$($childTypeName)s"
                                }
                            })

                                # Environment Setup
                            $scriptText += $Script:templateText.Region_EnvSetup

                                # Insert Dot Sourcing of files (make sure EnvSetup is before Timers
                            if ( $Script:refsGenerate['gbx_DotSource'].Controls.Checked -contains $true ) {
                                $scriptText += @(
                                    "    #region Dot Sourcing of files",
                                    "",
                                    "    `$dotSourceDir = `$BaseDir",
                                    ""
                                )

                                if ( $Script:refsGenerate['cbx_Functions'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['tbx_Functions'].Text)`""}
                                if ( $Script:refsGenerate['cbx_Events'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['tbx_Events'].Text)`""}
                                if ( $Script:refsGenerate['cbx_SubForms'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['tbx_SubForms'].Text)`""}
                                if ( $Script:refsGenerate['cbx_ReuseContext'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['tbx_ReuseContext'].Text)`""}
                                if ( $Script:refsGenerate['cbx_EnvSetup'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['tbx_EnvSetup'].Text)`""}
                                if ( $Script:refsGenerate['cbx_Timers'].Checked ) {$scriptText += "    . `"`$(`$dotSourceDir)\$($refsGenerate['cbx_Timers'].Text)`""}

                                $scriptText += @(
                                    "",
                                    "    #endregion Dot Sourcing of files",
                                    ""
                                )
                            }

                                # Form Initialization
                            $scriptText += @(
                                "    #region Form Initialization",
                                "",
                                "    try {",
                                "        ConvertFrom-WinFormsXML -Reference refs -Suppress -Xml @`""
                            )

                            $scriptText += $formText

                            $scriptText += @("`"@","    } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered during Form Initialization.`"}","","    #endregion Form Initialization","")

                                # Event Assignment
                            if ( $xml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" } ) {
                                $scriptText += $Script:templateText.StartRegion_EventAssignment

                                $xml.Data.Events.ChildNodes | Where-Object { $_.Root -match "^Form" } | ForEach-Object {
                                    $name = $_.Name

                                    $_.Events -Split ' ' | ForEach-Object {
                                        $scriptText += "        `$refs['$($name)'].Add_$($_)(`$eventSB['$($name)'].$($_))"
                                    }
                                }

                                $scriptText += $Script:templateText.endRegion_EventAssignment
                            }

                                # Other Actions Before ShowDialog
                            $scriptText += $Script:templateText.Region_OtherActionsAndShow
                            $scriptText += @(
                                "    try {[void]`$Script:refs['$($xml.Data.Form.Name)'].ShowDialog()} catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered unexpectedly during form operation.`"}",
                                ""
                            )

                                # Actions After Form Closed
                            $scriptText += $Script:templateText.Region_AfterClose

                                # Start Point of Execution (Runspace Setup)
                            $scriptText += $Script:templateText.Last

                                # Split Dot Sourced code to separate files
                            if ( $Script:refsGenerate['gbx_DotSource'].Controls.Checked -contains $true ) {
                                $Script:refsGenerate['gbx_DotSource'].Controls.Where({$_.Checked -eq $true}) | ForEach-Object {
                                    $regionName = switch ($_.Name) {
                                        cbx_Functions       {'Functions'}
                                        cbx_Events          {'Event ScriptBlocks'}
                                        cbx_SubForms        {'Sub Forms'}
                                        cbx_ReuseContext    {'Reusable ContextMenuStrips'}
                                        cbx_EnvSetup        {'Environment Setup'}
                                        cbx_Timers          {'Timers'}
                                    }

                                    $startIndex = [array]::IndexOf($scriptText,"    #region $($regionName)")
                                    $endIndex = [array]::IndexOf($scriptText,"    #endregion $($regionName)")

                                    $scriptText[$startIndex..$endIndex] | Out-File "$($generationPath)\$($Script:refsGenerate['gbx_DotSource'].Controls[$($_.Name -replace "^c",'t')].Text)"

                                    $afterText = $scriptText[($endIndex + 2)..($scriptText.Count - 1)]
                                    $scriptText = $scriptText[0..($startIndex - 1)]
                                    $scriptText += $afterText
                                }
                            }

                            $scriptText | Out-File "$($generationPath)\$($projectName -replace "fbs$","ps1")" -Encoding ascii -Force

                            [void][System.Windows.Forms.MessageBox]::Show('Script file successfully generated!','Success')
                        }
                    } catch {
                        if ( $_.Exception.Message -ne 'SaveCancelled' ) {
                            [void][System.Windows.Forms.MessageBox]::Show('There was an issue generating the script file.','Error')
                            Update-ErrorLog -ErrorRecord $_
                        }
                    }
                }
            }
        }
        'AddSpecialControl' = @{
            Click = {
                param($Sender)

                try {
                    $controlType = $Sender.Text -replace ".* "

                    $Script:newNameCheck = $false
                    $userInput = Get-UserInputFromForm
                    $Script:newNameCheck = $true

                    if ( $userInput.Result -eq 'OK' ) {
                        if ( $refs['TreeView'].Nodes.Text -match "$($controlType) - $($userInput.NewName)" ) {
                            [void][System.Windows.Forms.MessageBox]::Show("A $($controlType) with the Name '$($userInput.NewName)' already exists.",'Error')
                        } else {
                            $newTreeNode = $refs['TreeView'].Nodes.Add($userInput.NewName,"$($controlType) - $($userInput.NewName)")
                            $Script:objRefs[$controlType][$newTreeNode.Name] = @{
                                TreeNodes = @{"$($newTreeNode.Name)" = $newTreeNode}
                                Objects = @{"$($newTreeNode.Name)" = New-Object System.Windows.Forms.$controlType}
                                Changes = @{}
                                Events = @{}
                            }
                            $Script:refs['TreeView'].SelectedNode = $newTreeNode
                        }
                    }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while adding '$($Sender.Text)'."}
            }
        }
        'TreeView' = @{
            AfterSelect = {
                if ( $Script:openingProject -eq $false ) {
                    try {
                        $objRef = Get-RootNodeObjRef -TreeNode $this.SelectedNode
                        $nodeName = $this.SelectedNode.Name
                        $nodeType = $this.SelectedNode.Text -replace " - .*$"

                        $Script:refs['PropertyGrid'].SelectedObject = $objRef.Objects[$nodeName]
                        $Script:refs['lbl_PropertyGrid'].Text = $this.SelectedNode.Text

                        $Script:refsEvents['lst_AssignedEvents'].Items.Clear()

                        if ( $objRef.Events[$this.SelectedNode.Name] ) {
                            $refsEvents['lst_AssignedEvents'].BeginUpdate()
                            $objRef.Events[$nodeName].ForEach({[void]$refsEvents['lst_AssignedEvents'].Items.Add($_)})
                            $refsEvents['lst_AssignedEvents'].EndUpdate()

                            $refsEvents['lst_AssignedEvents'].Enabled = $true
                        } else {
                            $refsEvents['lst_AssignedEvents'].Items.Add('No Events')
                            $refsEvents['lst_AssignedEvents'].Enabled = $false
                        }

                        $eventTypes = $($Script:refs['PropertyGrid'].SelectedObject | Get-Member -Force).Name -match "^add_"

                        $Script:refsEvents['lst_AvailableEvents'].Items.Clear()
                        $Script:refsEvents['lst_AvailableEvents'].BeginUpdate()

                        if ( $eventTypes.Count -gt 0 ) {
                            $eventTypes | ForEach-Object {[void]$Script:refsEvents['lst_AvailableEvents'].Items.Add("$($_ -replace "^add_")")}}
                        else {
                            [void]$Script:refsEvents['lst_AvailableEvents'].Items.Add('No Events Found on Selected Object')
                            $Script:refsEvents['lst_AvailableEvents'].Enabled = $false
                        }

                        $Script:refsEvents['lst_AvailableEvents'].EndUpdate()

                        $Script:refsTools['trv_Controls'].Nodes.ForEach({
                            $_.Nodes.ForEach({
                                $controlName = $_.Name
                                $controlObjectType = $Script:supportedControls.Where({$_.Name -eq $controlName}).Type

                                if ( $Script:supportedControls.Where({$_.Name -eq $nodeType}).ChildTypes -contains $controlObjectType ) {$_.ForeColor = '0, 64, 0'}
                                else {$_.ForeColor = '64, 0, 0'}
                            })
                        })
                    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered after selecting TreeNode."}
                }
            }
        }
        'PropertyGrid' = @{
            PropertyValueChanged = {
                param($Sender,$e)

                try {
                    $changedProperty = $e.ChangedItem

                    if ( $e.ChangedItem.PropertyDepth -gt 0 ) {@(($e.ChangedItem.PropertyDepth)..0).ForEach({$changedProperty = $changedProperty.ParentGridEntry})}

                    $changedControl = $Sender.SelectedObject
                    $controlType = $Script:refs['TreeView'].SelectedNode.Text -replace " - .*$"
                    $controlName = $Script:refs['TreeView'].SelectedNode.Name

                    $defaultControl = $Script:supportedControls.Where({ $_.Name -eq $controlType }).DefaultObject

                    $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                    if ( $changedControl.$($changedProperty.PropertyName) -ne $defaultControl.$($changedProperty.PropertyName) ) {
                        switch ($changedProperty.PropertyType) {
                            'System.Drawing.Image' {[void][System.Windows.Forms.MessageBox]::Show('While the image will display on the preview of this form, you will need to add the image manually in the generated code.','Notification')}
                            default {
                                if ( $null -eq $objRef.Changes[$controlName] ) {$objRef.Changes[$controlName] = @{}}
                                $objRef.Changes[$controlName][$changedProperty.PropertyName] = $changedProperty.GetPropertyTextValue()
                            }
                        }
                    } elseif ( $objRef.Changes[$controlName] ) {
                        if ( $objRef.Changes[$controlName][$changedProperty.PropertyName] ) {
                            $objRef.Changes[$controlName].Remove($changedProperty.PropertyName)
                            if ( $objRef.Changes[$controlName].Count -eq 0 ) {$objRef.Changes.Remove($controlName)}
                        }
                    }
                    if ( $changedControl.GetType().Name -eq 'Form' ) {
                        if ( $null -eq $objRef.Changes[$controlName] ) {$objRef.Changes[$controlName] = @{}}

                        if (( $changedProperty.PropertyName -eq 'ControlBox' ) -and ( $changedControl.Text -eq '' )) {
                            if ( $changedProperty.GetPropertyTextValue() -eq 'True' ) {$changedControl.Size = New-Object System.Drawing.Size($changedControl.Size.Width,($changedControl.Size.Height-23))}
                            else {$changedControl.Size = New-Object System.Drawing.Size($changedControl.Size.Width,($changedControl.Size.Height+23))}
                        } elseif ( $changedProperty.PropertyName -eq 'Text' ) {
                            if (( $e.OldValue -eq '' ) -and ( $changedProperty.PropertyValue -ne '' ) -and ( $changedControl.ControlBox -eq $false )) {
                                $changedControl.Size = New-Object System.Drawing.Size($changedControl.Size.Width,($changedControl.Size.Height-23))
                            } elseif (( $e.OldValue -ne '' ) -and ( $changedProperty.PropertyValue -eq '' ) -and ( $changedControl.ControlBox -eq $false )) {
                                $changedControl.Size = New-Object System.Drawing.Size($changedControl.Size.Width,($changedControl.Size.Height+23))
                            }
                        }

                        if ( $objRef.Changes[$controlName].Count -eq 0 ) {$objRef.Changes.Remove($controlName)}
                    }
                } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered after changing property value ($($controlType) - $($controlName))."}
            }
        }
    }

    $Script:reuseEvents = @{
        ReSizeEnd = {$refs['PropertyGrid'].Refresh()}
        FormClosing = {
            param($Sender,$e)

            $e.Cancel = $true
            $this.Visible = $false
            $refs['FormPreview'].Checked = $false
        }
        MouseDown = {
            if (( $Script:refs['PropertyGrid'].SelectedObject -ne $this ) -and ( $args[1].Button -eq 'Left' )) {
                $Script:refs['TreeView'].SelectedNode = $Script:objRefs.Form.TreeNodes[$this.Name]
            }

            $Script:oldMousePos = @([System.Windows.Forms.Cursor]::Position.X,[System.Windows.Forms.Cursor]::Position.Y)
        }
        MouseMove = {
            if ( $Script:refs['PropertyGrid'].SelectedObject -eq $this ) {
                $curentPOS = [System.Windows.Forms.Cursor]::Position

                if ( $Script:oldMousePOS -notcontains 0 ) {
                    if ( $this.Cursor -eq 'SizeAll' ) {
                        $this.Left = $this.Left + $curentPOS.X - $Script:oldMousePOS[0]
                        $this.Top = $this.Top + $curentPOS.Y - $Script:oldMousePOS[1]
                    } else {
                        $ctlOffset = $this.PointToClient($curentPOS)

                        if ( $this.Cursor -eq 'SizeNS' ) {
                            if ( $ctlOffset.Y -le 10 ) {
                                $this.Size = New-Object System.Drawing.Size($this.Size.Width,($this.Size.Height + $Script:oldMousePOS[1] - $curentPOS.Y))
                                $this.Location = New-Object System.Drawing.Size($this.Location.X,($this.Location.Y + $curentPOS.Y - $Script:oldMousePOS[1]))
                            } else {$this.Size = New-Object System.Drawing.Size($this.Size.Width,($this.Size.Height + $curentPOS.Y - $Script:oldMousePOS[1]))}
                        } elseif ( $this.Cursor -eq 'SizeWE' ) {
                            if ( $ctlOffset.X -le 10 ) {
                                $this.Size = New-Object System.Drawing.Size(($this.Size.Width + $Script:oldMousePOS[0] - $curentPOS.X),$this.Size.Height)
                                $this.Location = New-Object System.Drawing.Size(($this.Location.X + $curentPOS.X - $Script:oldMousePOS[0]),$this.Location.Y)
                            } else {$this.Size = New-Object System.Drawing.Size(($this.Size.Width + $curentPOS.X - $Script:oldMousePOS[0]),$this.Size.Height)}
                        } elseif ( $this.Cursor -eq 'SizeNWSE' ) {
                            if ( $ctlOffset.Y -le 10 ) {
                                $this.Size = New-Object System.Drawing.Size(($this.Size.Width + $Script:oldMousePOS[0] - $curentPOS.X),($this.Size.Height + $Script:oldMousePOS[1] - $curentPOS.Y))
                                $this.Location = New-Object System.Drawing.Size(($this.Location.X + $curentPOS.X - $Script:oldMousePOS[0]),($this.Location.Y + $curentPOS.Y - $Script:oldMousePOS[1]))
                            } else {$this.Size = New-Object System.Drawing.Size(($this.Size.Width + $curentPOS.X - $Script:oldMousePOS[0]),($this.Size.Height + $curentPOS.Y - $Script:oldMousePOS[1]))}
                        } elseif ( $this.Cursor -eq 'SizeNESW' ) {
                            if ( $ctlOffset.X -le 10 ) {
                                $this.Size = New-Object System.Drawing.Size(($this.Size.Width + $Script:oldMousePOS[0] - $curentPOS.X),($this.Size.Height + $curentPOS.Y - $Script:oldMousePOS[1]))
                                $this.Location = New-Object System.Drawing.Size(($this.Location.X + $curentPOS.X - $Script:oldMousePOS[0]),$this.Location.Y)
                            } else {
                                $this.Size = New-Object System.Drawing.Size(($this.Size.Width + $curentPOS.X - $Script:oldMousePOS[0]),($this.Size.Height + $Script:oldMousePOS[1] - $curentPOS.Y))
                                $this.Location = New-Object System.Drawing.Size($this.Location.X,($this.Location.Y + $curentPOS.Y - $Script:oldMousePOS[1]))
                            }
                        }
                    }

                    $refs['PropertyGrid'].Refresh()
                    $Script:oldMousePos = @($curentPOS.X,$curentPOS.Y)
                } else {
                    $ctlOffset = $this.PointToClient($curentPOS)
                    $top = $false
                    $bottom = $false
                    $right = $false
                    $left = $false

                    if ( $ctlOffset.X -lt 5 ) {$right = $true} elseif ( $ctlOffset.X -gt $this.Size.Width - 5 ) {$left = $true}

                    if ( $ctlOffset.Y -lt 5 ) {$top = $true} elseif ( $ctlOffset.Y -gt $this.Size.Height - 5 ) {$bottom = $true}

                    if ( @($top,$bottom,$left,$right) -notcontains $true ) {$this.Cursor = 'SizeAll'}
                    elseif (( @($top,$bottom) -contains $true ) -and ( @($right,$left) -notcontains $true )) {$this.Cursor = 'SizeNS'}
                    elseif (( @($right,$left) -contains $true ) -and ( @($top,$bottom) -notcontains $true )) {$this.Cursor = 'SizeWE'}
                    elseif (( @($top,$right) -notcontains $false ) -or ( @($bottom,$left) -notcontains $false )) {$this.Cursor = 'SizeNWSE'}
                    elseif (( @($top,$left) -notcontains $false ) -or ( @($bottom,$right) -notcontains $false )) {$this.Cursor = 'SizeNESW'}
                    else {$this.Cursor = 'Default'}
                }
            }
        }
        MouseUp = {
            $Script:oldMousePOS = @(0,0)

            $refs['PropertyGrid'].Refresh()
        }
        MouseLeave = {
            if ( $Script:oldMousePOS -eq @(0,0) ) {
                $this.Cursor = 'Default'
            }
        }
        GenerateCBs = {
            $name = $this.Name -replace "^cbx","tbx"

            if ( $this.Checked -eq $true ) {$this.Parent.Controls[$name].Enabled = $true} else {$this.Parent.Controls[$name].Enabled = $false}

            $this.Parent.Controls[$name].Focus()
        }
    }

    #endregion

    #region Sub Forms

    $Script:subFormInfo = @{
        'NameInput' = @{
            XMLText = @"
  <Form Name="NameInput" ShowInTaskbar="False" MaximizeBox="False" Text="Enter Name" Size="700, 125" StartPosition="CenterParent" Font="Arial, 18pt" BackColor="171, 171, 171" FormBorderStyle="FixedDialog" MinimizeBox="False">
    <Label Name="label" TextAlign="MiddleCenter" Location="25, 25" Size="170, 40" Text="Control Name:" />
    <TextBox Name="UserInput" Location="210, 25" Size="425, 20" />
    <Button Name="StopDingOnEnter" Visible="False" />
  </Form>
"@
            Events = @(
                [pscustomobject]@{
                    Name = 'NameInput'
                    EventType = 'Activated'
                    ScriptBlock = {$this.Controls['UserInput'].Focus()}
                }
                [pscustomobject]@{
                    Name = 'UserInput'
                    EventType = 'KeyUp'
                    ScriptBlock = {
                        if ( $_.KeyCode -eq 'Return' ) {
                            $objRef = Get-RootNodeObjRef -TreeNode $refs['TreeView'].SelectedNode

                            if ( $((Get-Date)-$($Script:lastErrorTime)).TotalMilliseconds -lt 250 ) {
                            } elseif ( $this.Text -match "(\||<|>|&|\$|'|`")" ) {
                                [void][System.Windows.Forms.MessageBox]::Show("Names cannot contain any of the following characters: `"|<'>`"&`$`".", 'Error')
                            } elseif (( $objref.TreeNodes[$($this.Text.Trim())] ) -and ( $Script:newNameCheck -eq $true )) {
                                [void][System.Windows.Forms.MessageBox]::Show("All elements must have unique names for this application to function as intended. The name '$($this.Text.Trim())' is already assigned to another element.", 'Error')
                            } elseif ( $($this.Text -replace "\s") -eq '' ) {
                                [void][System.Windows.Forms.MessageBox]::Show("All elements must have names for this application to function as intended.", 'Error')
                                $this.Text = ''
                            } else {
                                $this.Parent.DialogResult = 'OK'
                                $this.Text = $this.Text.Trim()
                                $this.Parent.Close()
                            }

                            $Script:lastErrorTime = Get-Date
                        }
                    }
                }
            )
        }
        'Toolbox' = @{
            XMLText = @"
  <Form Name="Toolbox" FormBorderStyle="None" ControlBox="False" StartPosition="Manual" ShowInTaskBar="False" Size="175, 429" BackColor="171, 171, 171">
    <Button Name="btn_Close" Location="136, 1" Size="21, 21" Text="X" />
    <Label Name="lbl_Controls" Text="Toolbox" Size="137, 23" Font="Arial, 12pt" BackColor="197, 223, 235" Dock="Top" TextAlign="MiddleCenter" />
    <TreeView Name="trv_Controls" Anchor="Top, Bottom, Left" Location="5, 30" Size="160, 390" />
  </Form>
"@
            Events = @(
                [pscustomobject]@{
                    Name = 'trv_Controls'
                    EventType = 'DoubleClick'
                    ScriptBlock = {
                        $controlType = $refsTools['trv_Controls'].SelectedNode.Name

                        if ( @('All Controls','Common','Containers', 'Menus and ToolStrips') -notcontains $controlType ) {
                            if ( $this.SelectedNode.ForeColor.G -eq 64 ) {
                                Add-TreeNode -TreeObject $Script:refs['TreeView'].SelectedNode -ControlType $controlType
                            }
                        }

                        $Script:refs['MainForm'].Activate()
                    }
                },
                [pscustomobject]@{
                    Name = 'Toolbox'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'lbl_Controls'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'btn_Close'
                    EventType = 'Click'
                    ScriptBlock = {
                        $Script:refsEvents['Events'].Location = New-Object System.Drawing.Size(($Script:refs['MainForm'].Location.X - 167),$Script:refs['MainForm'].Location.Y)

                        $refs['Toolbox'].Checked = $false
                        $this.Parent.Visible = $false
                    }
                }
            )
        }
        'Events' = @{
            XMLText = @"
  <Form Name="Events" StartPosition="Manual" FormBorderStyle="None" ControlBox="False" ShowInTaskBar="False" BackColor="171, 171, 171" Size="175, 429">
    <Button Name="btn_Close" Location="136, 1" Size="21, 21" Text="X" />
    <Label Name="lbl_Events" TextAlign="MiddleCenter" Text="Events" Size="175, 23" BackColor="197, 223, 235" Dock="Top" Font="Arial, 12pt" />
    <Label Name="lbl_AvailableEvents" TextAlign="MiddleCenter" Location="0, 34" Size="175, 23" Text="Available Events" />
    <ListBox Name="lst_AvailableEvents" Size="160, 160" Location="5, 57" Anchor="Top, Bottom, Left" />
    <Label Name="lbl_AssignedEvents" Anchor="Bottom" TextAlign="MiddleCenter" Location="0, 234" Size="175, 23" Text="Assigned Events" />
    <ListBox Name="lst_AssignedEvents" Anchor="Bottom" Size="160, 160" Location="5, 259" Sorted="True" />
  </Form>
"@
            Events = (
                [pscustomobject]@{
                    Name = 'Events'
                    EventType = 'Shown'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'Events'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'lbl_Events'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'lbl_AvailableEvents'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'lst_AvailableEvents'
                    EventType = 'DoubleClick'
                    ScriptBlock = {
                        $controlName = $Script:refs['TreeView'].SelectedNode.Name
                        $objRef = Get-RootNodeObjRef -TreeNode $Script:refs['TreeView'].SelectedNode

                        if ( $Script:refsEvents['lst_AssignedEvents'].Items -notcontains $this.SelectedItem ) {
                            if ( $Script:refsEvents['lst_AssignedEvents'].Items -contains 'No Events' ) {$Script:refsEvents['lst_AssignedEvents'].Items.Clear()}
                            [void]$Script:refsEvents['lst_AssignedEvents'].Items.Add($this.SelectedItem)
                            $Script:refsEvents['lst_AssignedEvents'].Enabled = $true

                            $objRef.Events[$controlName] = @($Script:refsEvents['lst_AssignedEvents'].Items)
                        }

                        $Script:refs['MainForm'].Activate()
                    }
                },
                [pscustomobject]@{
                    Name = 'lbl_AssignedEvents'
                    EventType = 'Click'
                    ScriptBlock = {$Script:refs['MainForm'].Activate()}
                },
                [pscustomobject]@{
                    Name = 'lst_AssignedEvents'
                    EventType = 'DoubleClick'
                    ScriptBlock = {
                        $controlName = $Script:refs['TreeView'].SelectedNode.Name
                        $objRef = Get-RootNodeObjRef -TreeNode $Script:refs['TreeView'].SelectedNode

                        $Script:refsEvents['lst_AssignedEvents'].Items.Remove($this.SelectedItem)

                        if ( $Script:refsEvents['lst_AssignedEvents'].Items.Count -eq 0 ) {
                            $Script:refsEvents['lst_AssignedEvents'].Items.Add('No Events')
                            $Script:refsEvents['lst_AssignedEvents'].Enabled = $false
                        }

                        if ( $Script:refsEvents['lst_AssignedEvents'].Items[0] -ne 'No Events' ) {
                            $objRef.Events[$controlName] = @($Script:refsEvents['lst_AssignedEvents'].Items)
                        } else {
                            if ( $objRef.Events[$controlName] ) {
                                $objRef.Events.Remove($controlName)
                            }
                        }

                        $Script:refs['MainForm'].Activate()
                    }
                },
                [pscustomobject]@{
                    Name = 'btn_Close'
                    EventType = 'Click'
                    ScriptBlock = {
                        $refs['Events'].Checked = $false
                        $this.Parent.Visible = $false
                    }
                }
            )
        }
        'Generate' = @{
            XMLText = @"
  <Form Name="Generate" ShowInTaskbar="False" MaximizeBox="False" Text="Generate Script File(s)" Size="410, 420" StartPosition="CenterParent" FormBorderStyle="FixedDialog" MinimizeBox="False" ShowIcon="False">
    <GroupBox Name="gbx_DotSource" Location="25, 115" Size="345, 219" Text="Dot Sourcing">
      <CheckBox Name="cbx_Functions" Text="Functions" Location="25, 25" />
      <TextBox Name="tbx_Functions" Size="150, 20" Location="165, 25" Text="Functions.ps1" Enabled="False" />
      <CheckBox Name="cbx_Events" Text="Events" Location="25, 55" />
      <TextBox Name="tbx_Events" Size="150, 20" Location="165, 55" Text="Events.ps1" Enabled="False" />
      <CheckBox Name="cbx_SubForms" Text="Sub Forms" Location="25, 85" />
      <TextBox Name="tbx_SubForms" Size="150, 20" Location="165, 85" Text="SubForms.ps1" Enabled="False" />
      <CheckBox Name="cbx_Timers" Location="25, 115" Text="Timers" />
      <TextBox Name="tbx_Timers" Size="150, 20" Location="165, 115" Text="Timers.ps1" Enabled="False" />
      <CheckBox Name="cbx_ReuseContext" Location="25, 145" Size="135, 24" Text="Reuse Context Menus" />
      <TextBox Name="tbx_ReuseContext" Size="150, 20" Location="165, 145" Text="Context.ps1" Enabled="False" />
      <CheckBox Name="cbx_EnvSetup" Location="25, 175" Size="120, 24" Text="Environment Setup" />
      <TextBox Name="tbx_EnvSetup" Size="150, 20" Location="165, 175" Text="EnvSetup.ps1" Enabled="False" />
    </GroupBox>
    <GroupBox Name="gbx_SubForms" Location="25, 25" Size="345, 65" Text="Sub Forms">
      <Button Name="btn_Add" Font="Microsoft Sans Serif, 14.25pt, style=Bold" FlatStyle="System" Location="25, 25" Size="21, 19" Text="+" />
      <TextBox Name="tbx_SubForm1" Location="62, 25" Size="252, 20" Enabled="False" />
    </GroupBox>
    <Button Name="btn_Generate" FlatStyle="Flat" Location="104, 346" Size="178, 23" Text="Generate Script File(s)" />
  </Form>
"@
            Events = @(
                [pscustomobject]@{
                    Name = 'cbx_Functions'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'cbx_Events'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'cbx_SubForms'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'cbx_ReuseContext'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'cbx_EnvSetup'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'cbx_Timers'
                    EventType = 'CheckedChanged'
                    ScriptBlock = $Script:reuseEvents.GenerateCBs
                },
                [pscustomobject]@{
                    Name = 'btn_Generate'
                    EventType = 'Click'
                    ScriptBlock = {
                        $fileError = 0
                        [array]$checked = $Script:refsGenerate['gbx_DotSource'].Controls.Where({$_.Checked -eq $true})

                        if ( $checked.Count -gt 0 ) {
                            $checked.ForEach({
                                $fileName = $($Script:refsGenerate[$($_.Name -replace "^cbx","tbx")]).Text
                                if ( $($fileName -match ".*\...") -eq $false ) {
                                    [void][System.Windows.Forms.MessageBox]::Show("Filename not valid for the dot sourcing of $($_.Name -replace "^cbx_")")
                                    $fileError++
                                }
                            })
                        }

                        if ( $fileError -eq 0 ) {
                            $Script:refsGenerate['Generate'].DialogResult = 'OK'
                            $refsGenerate['Generate'].Visible = $false
                        }
                    }
                },
                [pscustomobject]@{
                    Name = 'btn_Add'
                    EventType = 'Click'
                    ScriptBlock = {
                        $openDialog = ConvertFrom-WinFormsXML -Xml @"
<OpenFileDialog InitialDirectory="$($Script:projectsDir)" AddExtension="True" DefaultExt="fbs" Filter="fbs files (*.fbs)|*.fbs" FilterIndex="1" ValidateNames="True" CheckFileExists="True" RestoreDirectory="True" />
"@
                        $openDialog.Add_FileOK({
                            param($Sender,$e)

                            if ( $Script:refsGenerate['gbx_SubForms'].Controls.Tag -contains $this.FileName ) {
                                [void][System.Windows.Forms.MessageBox]::Show("The project '$($this.FileName | Split-Path -Leaf)' has already been added as a subform of this project.",'Validation Error')
                                $e.Cancel = $true
                            }
                        })

                        try {
                            if ( $openDialog.ShowDialog() -eq 'OK' ) {
                                $fileName = $openDialog.FileName

                                $subFormCount = $Script:refsGenerate['gbx_SubForms'].Controls.Where({ $_.Name -match 'tbx_' }).Count

                                @('Generate','gbx_SubForms').ForEach({
                                    $Script:refsGenerate[$_].Size = New-Object System.Drawing.Size($Script:refsGenerate[$_].Size.Width,($Script:refsGenerate[$_].Size.Height + 40))
                                })

                                @('btn_Add','gbx_DotSource','btn_Generate').ForEach({
                                    $Script:refsGenerate[$_].Location = New-Object System.Drawing.Size($Script:refsGenerate[$_].Location.X,($Script:refsGenerate[$_].Location.Y + 40))
                                })

                                $Script:refsGenerate['Generate'].Location = New-Object System.Drawing.Size($Script:refsGenerate['Generate'].Location.X,($Script:refsGenerate['Generate'].Location.Y - 20))

                                $defaultTextBox = $Script:refsGenerate['gbx_SubForms'].Controls["tbx_SubForm$($subFormCount)"]
                                $defaultTextBox.Location = New-Object System.Drawing.Size($defaultTextBox.Location.X,($defaultTextBox.Location.Y + 40))
                                $defaultTextBox.Name = "tbx_SubForm$($subFormCount + 1)"

                                $button = ConvertFrom-WinFormsXML -ParentControl $Script:refsGenerate['gbx_SubForms'] -Xml @"
<Button Name="btn_Minus$($subFormCount)" Font="Microsoft Sans Serif, 14.25pt, style=Bold" FlatStyle="System" Location="25, $(25 + ($subFormCount - 1) * 40)" Size="21, 19" Text="-" />
"@
                                $button.Add_Click({
                                    try {
                                        [int]$btnIndex = $this.Name -replace "\D"
                                        $subFormCount = $Script:refsGenerate['gbx_SubForms'].Controls.Where({ $_.Name -match 'tbx_' }).Count

                                        $($Script:refsGenerate['gbx_SubForms'].Controls["tbx_SubForm$($btnIndex)"]).Dispose()
                                        $this.Dispose()

                                        @(($btnIndex + 1)..$subFormCount).ForEach({
                                            if ( $null -eq $Script:refsGenerate['gbx_SubForms'].Controls["btn_Minus$($_)"] ) {$btnName = 'btn_Add'} else {$btnName = "btn_Minus$($_)"}

                                            $btnLocX = $Script:refsGenerate['gbx_SubForms'].Controls[$btnName].Location.X
                                            $btnLocY = $Script:refsGenerate['gbx_SubForms'].Controls[$btnName].Location.Y

                                            $Script:refsGenerate['gbx_SubForms'].Controls[$btnName].Location = New-Object System.Drawing.Size($btnLocX,($btnLocY - 40))

                                            $tbxName = "tbx_SubForm$($_)"

                                            $tbxLocX = $Script:refsGenerate['gbx_SubForms'].Controls[$tbxName].Location.X
                                            $tbxLocY = $Script:refsGenerate['gbx_SubForms'].Controls[$tbxName].Location.Y
                                            $Script:refsGenerate['gbx_SubForms'].Controls[$tbxName].Location = New-Object System.Drawing.Size($tbxLocX,($tbxLocY - 40))

                                            if ( $btnName -ne 'btn_Add' ) {$Script:refsGenerate['gbx_SubForms'].Controls[$btnName].Name = "btn_Minus$($_ - 1)"}
                                            $Script:refsGenerate['gbx_SubForms'].Controls[$tbxName].Name = "tbx_SubForm$($_ - 1)"
                                        })

                                        @('Generate','gbx_SubForms').ForEach({
                                            $Script:refsGenerate[$_].Size = New-Object System.Drawing.Size($Script:refsGenerate[$_].Size.Width,($Script:refsGenerate[$_].Size.Height - 40))
                                        })

                                        @('gbx_DotSource','btn_Generate').ForEach({
                                            $Script:refsGenerate[$_].Location = New-Object System.Drawing.Size($Script:refsGenerate[$_].Location.X,($Script:refsGenerate[$_].Location.Y - 40))
                                        })

                                        $Script:refsGenerate['Generate'].Location = New-Object System.Drawing.Size($Script:refsGenerate['Generate'].Location.X,($Script:refsGenerate['Generate'].Location.Y + 20))

                                        if ( $Script:refsGenerate['gbx_SubForms'].Controls.Count -le 2 ) {
                                            $Script:refsGenerate['cbx_SubForms'].Checked = $false
                                            $Script:refsGenerate['cbx_SubForms'].Enabled = $false
                                        }

                                        Remove-Variable -Name btnIndex, subFormCount, btnName, btnLocX, btnLocY, tbxName, tbxLocX, tbxLocY
                                    } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while removing sub-form."}
                                })

                                ConvertFrom-WinFormsXML -ParentControl $Script:refsGenerate['gbx_SubForms'] -Suppress -Xml @"
<TextBox Name="tbx_SubForm$($subFormCount)" Location="62, $(25 + ($subFormCount - 1) * 40)" Size="252, 20" Text="...\$($fileName | Split-Path -Leaf)" Tag="$fileName" Enabled="False" />
"@
                                $Script:refsGenerate['cbx_SubForms'].Enabled = $true
                                Remove-Variable -Name button, fileName, subFormCount, defaultTextBox
                            }
                        } catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered while adding sub-form."}
                        finally {
                            $openDialog.Dispose()
                            Remove-Variable -Name openDialog
                        }
                    }
                }
            )
        }
    }

    #endregion Sub Forms

    #region Reusable ContextMenuStrips

    $reuseContextInfo = @{
        'TreeNode' = @{
            XMLText = @"
  <ContextMenuStrip Name="TreeNode">
    <ToolStripMenuItem Name="MoveUp" ShortcutKeys="F5" Text="Move Up" ShortcutKeyDisplayString="F5" />
    <ToolStripMenuItem Name="MoveDown" ShortcutKeys="F6" ShortcutKeyDisplayString="F6" Text="Move Down" />
    <ToolStripSeparator Name="Sep1" />
    <ToolStripMenuItem Name="CopyNode" ShortcutKeys="Ctrl+C" Text="Copy" ShortcutKeyDisplayString="Ctrl+C" />
    <ToolStripMenuItem Name="PasteNode" ShortcutKeys="Ctrl+P" Text="Paste" ShortcutKeyDisplayString="Ctrl+P" />
    <ToolStripSeparator Name="Sep2" />
    <ToolStripMenuItem Name="Rename" ShortcutKeys="Ctrl+R" Text="Rename" ShortcutKeyDisplayString="Ctrl+R" />
    <ToolStripMenuItem Name="Delete" ShortcutKeys="Ctrl+D" Text="Delete" ShortcutKeyDisplayString="Ctrl+D" />
  </ContextMenuStrip>
"@
            Events = @(
                [pscustomobject]@{
                    Name = 'TreeNode'
                    EventType = 'Opening'
                    ScriptBlock = {
                        $parentType = $refs['TreeView'].SelectedNode.Text -replace " - .*$"

                        if ( $parentType -eq 'Form' ) {
                            $this.Items['Delete'].Visible = $false
                            $this.Items['CopyNode'].Visible = $false
                            $isCopyVisible = $false
                        } else {
                            $this.Items['Delete'].Visible = $true
                            $this.Items['CopyNode'].Visible = $true
                            $isCopyVisible = $true
                        }

                        if ( $Script:nodeClipboard ) {
                            $this.Items['PasteNode'].Visible = $true
                            $this.Items['Sep2'].Visible = $true
                        } else {
                            $this.Items['PasteNode'].Visible = $false
                            $this.Items['Sep2'].Visible = $isCopyVisible
                        }
                    }
                },
                [pscustomobject]@{
                    Name = 'MoveUp'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['Move Up'].Click
                },
                [pscustomobject]@{
                    Name = 'MoveDown'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['Move Down'].Click
                },
                [pscustomobject]@{
                    Name = 'CopyNode'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['CopyNode'].Click
                },
                [pscustomobject]@{
                    Name = 'PasteNode'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['PasteNode'].Click
                },
                [pscustomobject]@{
                    Name = 'Rename'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['Rename'].Click
                },
                [pscustomobject]@{
                    Name = 'Delete'
                    EventType = 'Click'
                    ScriptBlock = $eventSB['Delete'].Click
                }
            )
        }
    }

    #endregion

    #region Environment Setup

    $noIssues = $true

    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

            # Confirm SavedProjects directory exists and set SavedProjects directory
        $Script:projectsDir = "$($env:UserProfile)\Documents\WinFormsCreator"
        if ( (Test-Path -Path "$($Script:projectsDir)") -eq $false ) {New-Item -Path "$($Script:projectsDir)" -ItemType Directory | Out-Null}

            # Set Misc Variables
        $Script:lastErrorTime = Get-Date
        $Script:formActivated = $false
        $Script:newNameCheck = $true
        $Script:oldMousePOS = @(0,0)
        $Script:openingProject = $false

        $Script:supportedControls = @(
            [pscustomobject]@{Name='Button';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.Button},
            [pscustomobject]@{Name='CheckBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.CheckBox},
            [pscustomobject]@{Name='CheckedListBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.CheckedListBox},
            [pscustomobject]@{Name='ComboBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.ComboBox},
            [pscustomobject]@{Name='ContextMenuStrip';Type='Context';ChildTypes=@('MenuStrip-Root','MenuStrip-Child');DefaultObject=New-Object System.Windows.Forms.ContextMenuStrip},
            [pscustomobject]@{Name='DateTimePicker';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.DateTimePicker},
            [pscustomobject]@{Name='FlowLayoutPanel';Type='Container';ChildTypes=@('Common','Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.FlowLayoutPanel},
            [pscustomobject]@{Name='GroupBox';Type='Container';ChildTypes=@('Common','Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.GroupBox},
            [pscustomobject]@{Name='Label';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.Label},
            [pscustomobject]@{Name='LinkLabel';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.LinkLabel},
            [pscustomobject]@{Name='ListBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.ListBox},
            [pscustomobject]@{Name='ListView';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.ListView},
            [pscustomobject]@{Name='MaskedTextBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.MaskedTextBox},
            [pscustomobject]@{Name='MenuStrip';Type='MenuStrip';ChildTypes=@('MenuStrip-Root');DefaultObject=New-Object System.Windows.Forms.MenuStrip},
            [pscustomobject]@{Name='MonthCalendar';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.MonthCalendar},
            [pscustomobject]@{Name='NumericUpDown';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.NumericUpDown},
            [pscustomobject]@{Name='Panel';Type='Container';ChildTypes=@('Common','Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.Panel},
            [pscustomobject]@{Name='PictureBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.PictureBox},
            [pscustomobject]@{Name='ProgressBar';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.ProgressBar},
            [pscustomobject]@{Name='PropertyGrid';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.PropertyGrid},
            [pscustomobject]@{Name='RadioButton';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.RadioButton},
            [pscustomobject]@{Name='RichTextBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.RichTextBox},
            [pscustomobject]@{Name='SplitContainer';Type='Container';ChildTypes=@('Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.SplitContainer},
            [pscustomobject]@{Name='TabControl';Type='Container';ChildTypes=@('Common','Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.TabControl},
            [pscustomobject]@{Name='TableLayoutPanel';Type='Container';ChildTypes=@('Common','Container','MenuStrip','Context');DefaultObject=New-Object System.Windows.Forms.TableLayoutPanel},
            [pscustomobject]@{Name='TextBox';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.TextBox},
            [pscustomobject]@{Name='TreeView';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.TreeView},
            [pscustomobject]@{Name='WebBrowser';Type='Common';ChildTypes=@('Context');DefaultObject=New-Object System.Windows.Forms.WebBrowser},
            [pscustomobject]@{Name='ToolStripMenuItem';Type='MenuStrip-Root';ChildTypes=@('MenuStrip-Root','MenuStrip-Child');DefaultObject=New-Object System.Windows.Forms.ToolStripMenuItem},
            [pscustomobject]@{Name='ToolStripComboBox';Type='MenuStrip-Root';ChildTypes=@();DefaultObject=New-Object System.Windows.Forms.ToolStripComboBox},
            [pscustomobject]@{Name='ToolStripTextBox';Type='MenuStrip-Root';ChildTypes=@();DefaultObject=New-Object System.Windows.Forms.ToolStripTextBox},
            [pscustomobject]@{Name='ToolStripSeparator';Type='MenuStrip-Child';ChildTypes=@();DefaultObject=New-Object System.Windows.Forms.ToolStripSeparator},
            [pscustomobject]@{Name='Form';Type='Special';ChildTypes=@('Common','Container','MenuStrip');DefaultObject=New-Object System.Windows.Forms.Form},
            [pscustomobject]@{Name='Timer';Type='Special';ChildTypes=@();DefaultObject=New-Object System.Windows.Forms.Timer}
        )

    } catch {
        Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Environment Setup."
        $noIssues = $false
    }

    #endregion

    #region Sub-Form/Reuse ContextMenuStrip Initialization

    if ( $noIssues ) {
        try {
            Get-SpecialControl -ControlInfo $Script:subFormInfo['Toolbox'] -Reference refsTools -Suppress

            @('All Controls','Common','Containers', 'Menus and ToolStrips').ForEach({
                $treeNode = $Script:refsTools['trv_Controls'].Nodes.Add($_,$_)

                switch ($_) {
                    'All Controls'         {$Script:supportedControls.Where({ $_.Type -ne 'Special' }).Name.ForEach({$treeNode.Nodes.Add($_,$_)})}
                    'Common'               {$Script:supportedControls.Where({ $_.Type -eq 'Common' }).Name.ForEach({$treeNode.Nodes.Add($_,$_)})}
                    'Containers'           {$Script:supportedControls.Where({ $_.Type -eq 'Container' }).Name.ForEach({$treeNode.Nodes.Add($_,$_)})}
                    'Menus and ToolStrips' {$Script:supportedControls.Where({ $_.Type -eq 'Context' -or $_.Type -match "^MenuStrip" }).Name.ForEach({$treeNode.Nodes.Add($_,$_)})}
                }
            })

            $Script:refsTools['trv_Controls'].Nodes.Where({$_.Name -eq 'All Controls'}).Expand()

            Get-SpecialControl -ControlInfo $Script:subFormInfo['Events'] -Reference refsEvents -Suppress

            $Script:subFormInfo.Remove('Events')
            $Script:subFormInfo.Remove('Toolbox')

            Get-SpecialControl -ControlInfo $reuseContextInfo['TreeNode'] -Reference reuseContext -Suppress
        } catch {
            Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Sub Form Initialization."
            $noIssues = $false
        }
    }

    #endregion

    #region Form Initialization

    if ( $noIssues ) {
        try {
            ConvertFrom-WinFormsXML -Reference refs -Suppress -Xml @"
  <Form Name="MainForm" Text="PowerShell Winforms Creator" Size="623, 434" MaximizeBox="False" StartPosition="CenterScreen" BackColor="171, 171, 171" MinimumSize="623, 434">
    <MenuStrip Name="MenuStrip" RenderMode="System">
      <ToolStripMenuItem Name="ts_File" Text="File" DisplayStyle="Text">
        <ToolStripMenuItem Name="New" Text="New" ShortcutKeys="Ctrl+N" DisplayStyle="Text" ShortcutKeyDisplayString="Ctrl+N" />
        <ToolStripMenuItem Name="Open" Text="Open" ShortcutKeys="Ctrl+O" DisplayStyle="Text" ShortcutKeyDisplayString="Ctrl+O" />
        <ToolStripMenuItem Name="Save" Text="Save" ShortcutKeys="Ctrl+S" DisplayStyle="Text" ShortcutKeyDisplayString="Ctrl+S" />
        <ToolStripMenuItem Name="Save As" Text="Save As" ShortcutKeys="Ctrl+Alt+S" DisplayStyle="Text" ShortcutKeyDisplayString="Ctrl+Alt+S" />
        <ToolStripSeparator Name="FileSep" DisplayStyle="Text" />
        <ToolStripMenuItem Name="Exit" Text="Exit" ShortcutKeys="Ctrl+Alt+X" DisplayStyle="Text" ShortcutKeyDisplayString="Ctrl+Alt+X" />
      </ToolStripMenuItem>
      <ToolStripMenuItem Name="ts_Edit" Text="Edit">
        <ToolStripMenuItem Name="Rename" ShortcutKeys="Ctrl+R" Text="Rename" ShortcutKeyDisplayString="Ctrl+R" />
        <ToolStripMenuItem Name="Delete" ShortcutKeys="Ctrl+D" Text="Delete" ShortcutKeyDisplayString="Ctrl+D" />
        <ToolStripSeparator Name="EditSep1" />
        <ToolStripMenuItem Name="CopyNode" ShortcutKeys="Ctrl+C" Text="Copy" ShortcutKeyDisplayString="Ctrl+C" />
        <ToolStripMenuItem Name="PasteNode" ShortcutKeys="Ctrl+P" Text="Paste" ShortcutKeyDisplayString="Ctrl+P" />
        <ToolStripSeparator Name="EditSep2" />
        <ToolStripMenuItem Name="Move Up" ShortcutKeys="F5" Text="Move Up" ShortcutKeyDisplayString="F5" />
        <ToolStripMenuItem Name="Move Down" ShortcutKeys="F6" Text="Move Down" ShortcutKeyDisplayString="F6" />
      </ToolStripMenuItem>
      <ToolStripMenuItem Name="ts_View" Text="View">
        <ToolStripMenuItem Name="Toolbox" Checked="True" ShortcutKeys="F1" Text="Toolbox" ShortcutKeyDisplayString="F1" />
        <ToolStripMenuItem Name="Events" Checked="True" ShortcutKeys="F2" Text="Events" ShortcutKeyDisplayString="F2" />
        <ToolStripSeparator Name="ViewSep" DisplayStyle="Text" />
        <ToolStripMenuItem Name="FormPreview" ShortcutKeyDisplayString="F3" ShortcutKeys="F3" DisplayStyle="Text" Text="Form Preview" />
      </ToolStripMenuItem>
      <ToolStripMenuItem Name="ts_Tools" Text="Tools" DisplayStyle="Text">
        <ToolStripMenuItem Name="AddTimer" Text="Add Timer" DisplayStyle="Text" />
        <ToolStripMenuItem Name="AddReuseContext" Text="Add Reuse ContextMenuStrip" DisplayStyle="Text" />
        <ToolStripSeparator Name="ToolsSep" DisplayStyle="Text" />
        <ToolStripMenuItem Name="Generate Script File" Text="Generate Script File" DisplayStyle="Text" />
      </ToolStripMenuItem>
    </MenuStrip>
    <Label Name="lbl_FormLayout" TextAlign="MiddleCenter" AutoEllipsis="True" Text="NewProject.fbs" Size="196, 24" BackColor="Azure" Anchor="Top, Left, Right" Location="5, 25" Font="Arial, 9.75pt, style=Bold" />
    <TreeView Name="TreeView" Location="5, 50" HideSelection="False" Anchor="Top, Bottom, Left, Right" Size="196, 339" Font="Arial, 9.75pt" DrawMode="OwnerDrawText" />
    <Label Name="lbl_PropertyGrid" Anchor="Top, Right" Size="400, 24" BackColor="Azure" Location="202, 25" TextAlign="MiddleCenter" Font="Arial, 9.75pt, style=Bold" />
    <PropertyGrid Name="PropertyGrid" Font="Arial, 9.75pt" Anchor="Top, Bottom, Right" Location="202, 50" Size="400, 339" />
  </Form>
"@

            $refs['MainForm'].AddOwnedForm($refsTools['Toolbox'])
            $refs['MainForm'].AddOwnedForm($refsEvents['Events'])
        } catch {
            Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Form Initialization."
            $noIssues = $false
        }
    }

    #endregion

    #region Event Assignment

    if ( $noIssues ) {
        try {
                # ScriptBlock Here
            $refs['Save'].Add_Click({ try {Save-Project} catch {if ( $_.Exception.Message -ne 'SaveCancelled' ) {throw $_}} })
            $refs['Save As'].Add_Click({ try {Save-Project -SaveAs} catch {if ( $_.Exception.Message -ne 'SaveCancelled' ) {throw $_}} })
            $refs['Exit'].Add_Click({$Script:refs['MainForm'].Close()})
            $refs['TreeView'].Add_NodeMouseClick({$this.SelectedNode = $_.Node})
            $refs['TreeView'].Add_DrawNode({$args[1].DrawDefault = $true})

                # Call to ScriptBlock
            $refs['MainForm'].Add_Activated($eventSB['MainForm'].Activated)
            $refs['MainForm'].Add_FormClosing($eventSB['MainForm'].FormClosing)
            $refs['MainForm'].Add_Resize($eventSB['MainForm'].Resize)
            $refs['MainForm'].Add_LocationChanged($eventSB['MainForm'].LocationChanged)
            $refs['New'].Add_Click($eventSB['New'].Click)
            $refs['Open'].Add_Click($eventSB['Open'].Click)
            $refs['Move Up'].Add_Click($eventSB['Move Up'].Click)
            $refs['Move Down'].Add_Click($eventSB['Move Down'].Click)
            $refs['Rename'].Add_Click($eventSB['Rename'].Click)
            $refs['Delete'].Add_Click($eventSB['Delete'].Click)
            $refs['Toolbox'].Add_Click($eventSB['Toolbox'].Click)
            $refs['Events'].Add_Click($eventSB['Events'].Click)
            $refs['FormPreview'].Add_Click($eventSB['FormPreview'].Click)
            $refs['Generate Script File'].Add_Click($eventSB['Generate Script File'].Click)
            $refs['AddReuseContext'].Add_Click($eventSB['AddSpecialControl'].Click)
            $refs['AddTimer'].Add_Click($eventSB['AddSpecialControl'].Click)
            $refs['TreeView'].Add_AfterSelect($eventSB['TreeView'].AfterSelect)
            $refs['TreeView'].Add_KeyUp($eventSB['TreeView'].KeyUp)
            $refs['PropertyGrid'].Add_PropertyValueChanged($eventSB['PropertyGrid'].PropertyValueChanged)
        } catch {
            Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered during Event Assignment."
            $noIssues = $false
        }
    }

    #endregion

    #region Other Actions Before ShowDialog

    if ( $noIssues ) {
        try {
            [void]$refsEvents['lst_AssignedEvents'].Items.Add('No Events')
            $refsEvents['lst_AssignedEvents'].Enabled = $false

                # Add the Initial Form TreeNode
            Add-TreeNode -TreeObject $Script:refs['TreeView'] -ControlType Form -ControlName MainForm

            Remove-Variable -Name eventSB,reuseContextInfo

                # Strings Used During Script File Generation
            $Script:templateText = @(
                [pscustomobject]@{First = @(
                    "<#",
                    "    .NOTES",
                    "    ===========================================================================",
                    "        FileName:  FNAME",
                    "        Author:  NETNAME",
                    "        Created On:  DATE",
                    "        Last Updated:  DATE",
                    "        Organization:",
                    "        Version:      v0.1",
                    "    ===========================================================================",
                    "",
                    "    .DESCRIPTION",
                    "",
                    "    .DEPENDENCIES",
                    "#>",
                    "",
                    "# ScriptBlock to Execute in STA Runspace",
                    "`$sbGUI = {",
                    "    param(`$BaseDir)",
                    ""
                )},
                [pscustomobject]@{StartRegion_Functions = @(
                    "    #region Functions",
                    "",
                    "    function Update-ErrorLog {",
                    "        param(",
                    "            [System.Management.Automation.ErrorRecord]`$ErrorRecord,",
                    "            [string]`$Message,",
                    "            [switch]`$Promote",
                    "        )",
                    "",
                    "        if ( `$Message -ne '' ) {[void][System.Windows.Forms.MessageBox]::Show(`"`$(`$Message)``r``n``r``nCheck '`$(`$BaseDir)\exceptions.txt' for details.`",'Exception Occurred')}",
                    "",
                    "        `$date = Get-Date -Format 'yyyyMMdd HH:mm:ss'",
                    "        `$ErrorRecord | Out-File `"`$(`$BaseDir)\tmpError.txt`"",
                    "",
                    "        Add-Content -Path `"`$(`$BaseDir)\exceptions.txt`" -Value `"`$(`$date): `$(`$(Get-Content `"`$(`$BaseDir)\tmpError.txt`") -replace `"\s+`",`" `")`"",
                    "",
                    "        Remove-Item -Path `"`$(`$BaseDir)\tmpError.txt`"",
                    "",
                    "        if ( `$Promote ) {throw `$ErrorRecord}",
                    "    }",
                    "",
                    "    function ConvertFrom-WinFormsXML {",
                    "        param(",
                    "            [Parameter(Mandatory=`$true)]`$Xml,",
                    "            [string]`$Reference,",
                    "            `$ParentControl,",
                    "            [switch]`$Suppress",
                    "        )",
                    "",
                    "        try {",
                    "            if ( `$Xml.GetType().Name -eq 'String' ) {`$Xml = ([xml]`$Xml).ChildNodes}",
                    "",
                    "            `$newControl = New-Object System.Windows.Forms.`$(`$Xml.ToString())",
                    "",
                    "            if ( `$ParentControl ) {",
                    "                if ( `$Xml.ToString() -match `"^ToolStrip`" ) {",
                    "                    if ( `$ParentControl.GetType().Name -match `"^ToolStrip`" ) {[void]`$ParentControl.DropDownItems.Add(`$newControl)} else {[void]`$ParentControl.Items.Add(`$newControl)}",
                    "                } elseif ( `$Xml.ToString() -eq 'ContextMenuStrip' ) {`$ParentControl.ContextMenuStrip = `$newControl}",
                    "                else {`$ParentControl.Controls.Add(`$newControl)}",
                    "            }",
                    "",
                    "            `$Xml.Attributes | ForEach-Object {",
                    "                if ( `$null -ne `$(`$newControl.`$(`$_.ToString())) ) {",
                    "                    if ( `$(`$newControl.`$(`$_.ToString())).GetType().Name -eq 'Boolean' ) {",
                    "                        if ( `$_.Value -eq 'True' ) {`$value = `$true} else {`$value = `$false}",
                    "                    } else {`$value = `$_.Value}",
                    "                } else {`$value = `$_.Value}",
                    "                `$newControl.`$(`$_.ToString()) = `$value",
                    "",
                    "                if (( `$_.ToString() -eq 'Name' ) -and ( `$Reference -ne '' )) {",
                    "                    try {`$refHashTable = Get-Variable -Name `$Reference -Scope Script -ErrorAction Stop}",
                    "                    catch {",
                    "                        New-Variable -Name `$Reference -Scope Script -Value @{} | Out-Null",
                    "                        `$refHashTable = Get-Variable -Name `$Reference -Scope Script -ErrorAction SilentlyContinue",
                    "                    }",
                    "",
                    "                    `$refHashTable.Value.Add(`$_.Value,`$newControl)",
                    "                }",
                    "            }",
                    "",
                    "            if ( `$Xml.ChildNodes ) {`$Xml.ChildNodes | ForEach-Object {ConvertFrom-WinformsXML -Xml `$_ -ParentControl `$newControl -Reference `$Reference -Suppress}}",
                    "",
                    "            if ( `$Suppress -eq `$false ) {return `$newControl}",
                    "        } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered adding `$(`$Xml.ToString()) to `$(`$ParentControl.Name)`"}",
                    "    }",
                    ""
                )},
                [pscustomobject]@{Function_GetSpecialControl = @(
                    "    function Get-SpecialControl {",
                    "        param(",
                    "            [Parameter(Mandatory=`$true)][hashtable]`$ControlInfo,",
                    "            [string]`$Reference,",
                    "            [switch]`$Suppress",
                    "        )",
                    "",
                    "        try {",
                    "            `$refGuid = [guid]::NewGuid()",
                    "            `$control = ConvertFrom-WinFormsXML -Xml `"`$(`$ControlInfo.XMLText)`" -Reference `$refGuid",
                    "            `$refControl = Get-Variable -Name `$refGuid -ValueOnly",
                    "",
                    "            if ( `$ControlInfo.Events ) {`$ControlInfo.Events.ForEach({`$refControl[`$_.Name].`"add_`$(`$_.EventType)`"(`$_.ScriptBlock)})}",
                    "",
                    "            if ( `$Reference -ne '' ) {New-Variable -Name `$Reference -Scope Script -Value `$GetSpecialControlSubRef}",
                    "",
                    "            Remove-Variable -Name `$refGuid -Scope Script",
                    "",
                    "            if ( `$Suppress -eq `$false ) {return `$control}",
                    "        } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered getting special control.`"}",
                    "    }",
                    ""
                )},
                [pscustomobject]@{EndRegion_Functions = @(
                    "    #endregion Functions",
                    ""
                )},
                [pscustomobject]@{StartRegion_Events = @(
                    "    #region Event ScriptBlocks",
                    "",
                    "    `$eventSB = @{"
                )},
                [pscustomobject]@{EndRegion_Events = @(
                    "    }",
                    "",
                    "    #endregion Event ScriptBlocks",
                    ""
                )},
                [pscustomobject]@{StartRegion_SubForms = @(
                    "    #region Sub Forms",
                    "",
                    "    `$Script:subFormInfo = @{"
                )},
                [pscustomobject]@{EndRegion_SubForms = @(
                    "    }",
                    "",
                    "    #endregion Sub Forms",
                    ""
                )},
                [pscustomobject]@{StartRegion_Timers = @(
                    "    #region Timers",
                    "",
                    "    `$Script:timerInfo = @{",
                    ""
                )},
                [pscustomobject]@{EndRegion_Timers = @(
                    "    }",
                    "",
                    "    #endregion Timers",
                    ""
                )},
                [pscustomobject]@{StartRegion_ContextMenuStrips = @(
                    "    #region Reusable ContextMenuStrips",
                    "",
                    "    `$Script:reuseContextInfo = @{"
                )},
                [pscustomobject]@{EndRegion_ContextMenuStrips = @(
                    "    }",
                    "",
                    "    #endregion Reusable ContextMenuStrips",
                    ""
                )},
                [pscustomobject]@{Region_EnvSetup = @(
                    "    #region Environment Setup",
                    "",
                    "    try {",
                    "        Add-Type -AssemblyName System.Windows.Forms",
                    "        Add-Type -AssemblyName System.Drawing",
                    "",
                    "",
                    "    } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered during Environment Setup.`"}",
                    "",
                    "    #endregion Environment Setup",
                    ""
                )},
                [pscustomobject]@{StartRegion_EventAssignment = @(
                    "    #region Event Assignment",
                    "",
                    "    try {"
                )},
                [pscustomobject]@{EndRegion_EventAssignment = @(
                    "    } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered during Event Assignment.`"}",
                    "",
                    "    #endregion Event Assignment",
                    ""
                )},
                [pscustomobject]@{Region_OtherActionsAndShow = @(
                    "    #region Other Actions Before ShowDialog",
                    "",
                    "    try {",
                    "        Remove-Variable -Name eventSB",
                    "    } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered before ShowDialog.`"}",
                    "",
                    "    #endregion Other Actions Before ShowDialog",
                    "",
                    "        # Show the form"
                )},
                [pscustomobject]@{Region_AfterClose = @(
                    "    <#",
                    "    #region Actions After Form Closed",
                    "",
                    "    try {",
                    "",
                    "    } catch {Update-ErrorLog -ErrorRecord `$_ -Message `"Exception encountered after Form close.`"}",
                    "",
                    "    #endregion Actions After Form Closed",
                    "    #>",
                    "}",
                    ""
                )},
                [pscustomobject]@{Last = @(
                    "#region Start Point of Execution",
                    "",
                    "    # Initialize STA Runspace",
                    "`$rsGUI = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()",
                    "`$rsGUI.ApartmentState = 'STA'",
                    "`$rsGUI.ThreadOptions = 'ReuseThread'",
                    "`$rsGUI.Open()",
                    "",
                    "    # Create the PSCommand, Load into Runspace, and BeginInvoke",
                    "`$cmdGUI = [Management.Automation.PowerShell]::Create().AddScript(`$sbGUI).AddParameter('baseDir',`$PSScriptRoot)",
                    "`$cmdGUI.RunSpace = `$rsGUI",
                    "`$handleGUI = `$cmdGUI.BeginInvoke()",
                    "",
                    "    # Hide Console Window",
                    "Add-Type -Name Window -Namespace Console -MemberDefinition '",
                    "[DllImport(`"Kernel32.dll`")]",
                    "public static extern IntPtr GetConsoleWindow();",
                    "",
                    "[DllImport(`"user32.dll`")]",
                    "public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);",
                    "'",
                    "",
                    "[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)",
                    "",
                    "    #Loop Until GUI Closure",
                    "while ( `$handleGUI.IsCompleted -eq `$false ) {Start-Sleep -Seconds 5}",
                    "",
                    "    # Dispose of GUI Runspace/Command",
                    "`$cmdGUI.EndInvoke(`$handleGUI)",
                    "`$cmdGUI.Dispose()",
                    "`$rsGUI.Dispose()",
                    "",
                    "Exit",
                    "",
                    "#endregion Start Point of Execution"
                )}
            )
        } catch {
            Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered before ShowDialog."
            $noIssues = $false
        }
    }

    #endregion

    if ( $noIssues ) {
            # Show the form
        try {[void]$Script:refs['MainForm'].ShowDialog()} catch {Update-ErrorLog -ErrorRecord $_ -Message "Exception encountered unexpectedly during form operation."}
    }
}

#region Start Point of Execution

    # Initialize STA Runspace
$rsGUI = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
$rsGUI.ApartmentState = "STA"
$rsGUI.ThreadOptions = "ReuseThread"
$rsGUI.Open()

    # Create the PSCommand, Load into Runspace, and BeginInvoke
$cmdGUI = [Management.Automation.PowerShell]::Create().AddScript($sbGUI).AddParameter('baseDir',$PSScriptRoot)
$cmdGUI.RunSpace = $rsGUI
$handleGUI = $cmdGUI.BeginInvoke()

Remove-Variable -Name sbGUI

    # Hide Console Window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
[Console.Window]::ShowWindow([Console.Window]::GetConsoleWindow(), 0)

    #Loop Until GUI Closure
while ( $handleGUI.IsCompleted -eq $false ) {Start-Sleep -Seconds 5}

    # Dispose of GUI Runspace/Command
$cmdGUI.EndInvoke($handleGUI)
$cmdGUI.Dispose()
$rsGUI.Dispose()

Exit
#endregion