Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
Function MakeToolTip ()
{
	
	$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.InitialDelay = 100
$toolTip.AutoPopDelay = 10000
	
Return $toolTip
}

Function ChooseFolder($Message) {
    $FolderBrowse = New-Object System.Windows.Forms.OpenFileDialog -Property @{ValidateNames = $false;CheckFileExists = $false;RestoreDirectory = $true;FileName = $Message;}
    $null = $FolderBrowse.ShowDialog()
    $FolderName = Split-Path -Path $FolderBrowse.FileName
    
	return $FolderName
}
function Check-ContextMenuItem {
    param (
        [string]$Name
    )

    $itemPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$Name"
	return (Test-Path $itemPath)
}


function Test-PathWithErrorHandling {
    param (
        [string]$Path
    )

    try {
        $result = Test-Path -Path $Path -ErrorAction Stop
        return $result
    } catch {
        return $false
    }
}

function LoadOptions {
    param (
        [string]$Filename
    )

    $options = @{}

    Get-Content $Filename | ForEach-Object {
        $line = $_
        $matchResult = [regex]::Match($line, '^(.+?)=(.+)$')

        if ($matchResult.Success) {
            $label = $matchResult.Groups[1].Value
            $value = $matchResult.Groups[2].Value

            if ($value.ToLower() -eq "true" -or $value.ToLower() -eq "false") {
                $value = $value.ToLower() -eq "true"
            }

            $options[$label] = $value
        }
    }

    return $options
}

function SortListBoxAlphabetically ($directories, $ascending) {
    if ($ascending) {
        return $directories | Sort-Object
    } else {
        return $directories | Sort-Object -Descending
    }
}

function SortListBoxByLastChild ($directories, $ascending) {
    if ($ascending) {
        return $directories | Sort-Object -Property { Split-Path $_ -Leaf }
    } else {
        return $directories | Sort-Object -Property { Split-Path $_ -Leaf } -Descending
    }
}

function SortListBoxByType ($directories, $ascending) {
	if ($ascending) {
		return $directories | Sort-Object -Property {
			if ($_ -match '\.') {
				$extension = $_ -replace '^.*\.', ''
				if ($extension -eq $_) {
					return '0' # For folders and items without extensions
				}
				return $extension
			}
			return '0'
		}
	} else {
		return $directories | Sort-Object -Property {
			if ($_ -match '\.') {
				$extension = $_ -replace '^.*\.', ''
				if ($extension -eq $_) {
					return '0' # For folders and items without extensions
				}
				return $extension
			}
			return '0'
		} -Descending
	}
}
function SortBySize {
    param (
        [System.Collections.ArrayList]$List,
        [bool]$Ascending
    )

    if ($Ascending) {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.Size
        }
    } else {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.Size
        } -Descending
    }

    return $sortedList
}

function SortByDateCreated {
    param (
        [System.Collections.ArrayList]$List,
        [bool]$Ascending
    )

    if ($Ascending) {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.DateCreated
        }
    } else {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.DateCreated
        } -Descending
    }

    return $sortedList
}

function SortByDateModified {
    param (
        [System.Collections.ArrayList]$List,
        [bool]$Ascending
    )

    if ($Ascending) {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.DateModified
        }
    } else {
        $sortedList = $List | Sort-Object {
            $data = Get-CachedFileData -FilePath $_
            $data.DateModified
        } -Descending
    }

    return $sortedList
}




$AccedingSort = $true


$SBlabel = New-Object System.Windows.Forms.Label
$SBlabel.Text = "Sort By:"
$SBlabel.Location = New-Object System.Drawing.Point(220, 75)



$dropdown = New-Object System.Windows.Forms.ComboBox
$dropdown.Location = New-Object System.Drawing.Point(270, 75)
$dropdown.Size = New-Object System.Drawing.Size(100, 21)
$dropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList


$dropdown.Items.Add("Drive")
$dropdown.Items.Add("Name")
$dropdown.Items.Add("Type")
$dropdown.Items.Add("Size")
$dropdown.Items.Add("Date Created")
$dropdown.Items.Add("Date Modified")


$dropdown.SelectedIndex = 0

$VirtualList = @()
function Update-Sort {
	if ($global:VirtualList.Count -gt 1) {
		$selectedItemValue = $null
		if ($virtualListView.SelectedIndices.Count -gt 0) {
			$selectedIndex = $virtualListView.SelectedIndices[0]
			$selectedItemValue = $global:VirtualList[$selectedIndex]
		}
	
		# Sort the items in the VirtualList
		
		function Update-ListView {
			param (
				[System.Collections.ArrayList]$SortedDirectories
			)
			$virtualListView.VirtualListSize = $SortedDirectories.Count
			$global:VirtualList = @()
			$virtualListView.Invalidate()
			$global:VirtualList = $SortedDirectories
		}
		
		$sortedDirectories = $global:VirtualList
		switch ($dropdown.SelectedItem) {
			"Drive" {
				$sortedDirectories = SortListBoxAlphabetically $global:VirtualList $AccedingSort
			}
			"Name" {
				$sortedDirectories = SortListBoxByLastChild $global:VirtualList $AccedingSort
			}
			"Type" {
				$sortedDirectories = SortListBoxByType $global:VirtualList $AccedingSort
			}
			"Size" {
				$sortedDirectories = SortBySize $global:VirtualList $AccedingSort
			}
			"Date Created" {
				$sortedDirectories = SortByDateCreated $global:VirtualList $AccedingSort
			}
			"Date Modified" {
				$sortedDirectories = SortByDateModified $global:VirtualList $AccedingSort
			}
			
		}
		Update-ListView -SortedDirectories $sortedDirectories
		# Find the new index of the previously selected item and update the selectedIndex
		if ( $null -ne $selectedItemValue ) {
			$newIndex = -1
			for ($i = 0; $i -lt $global:VirtualList.Count; $i++) {
				if ($global:VirtualList[$i] -eq $selectedItemValue) {
					$newIndex = $i
					break
				}
			}
	
			if ($newIndex -ge 0) {
				$virtualListView.SelectedIndices.Clear()
				$virtualListView.SelectedIndices.Add($newIndex)
				$virtualListView.EnsureVisible($newIndex)
			}
		}
	}
	
}
# Handle the dropdown menu's SelectedIndexChanged event
$dropdown.Add_SelectedIndexChanged({
    Update-Sort
})

# Initialize form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Power Search'
$form.Size = New-Object System.Drawing.Size(800, 400)
$LeftLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$LeftLayout.Location = New-Object System.Drawing.Point(20,40)
	$LeftLayout.Dock = [System.Windows.Forms.DockStyle]::None
	$LeftLayout.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
	$LeftLayout.AutoSize = $true
$minWidth = 450
$minHeight = 300
$form.MinimumSize = New-Object System.Drawing.Size($minWidth, $minHeight)
$form.StartPosition = 'CenterScreen'
$form.Icon = 'logo5.ico'
#$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
#$form.AutoSize = $true
$helpIcon = New-Object System.Windows.Forms.PictureBox
$helpIcon.Image = [System.Drawing.Image]::FromFile("help2.png")
$helpIcon.SizeMode = 'Zoom'
$helpIcon.Size = New-Object System.Drawing.Size(16, 16)
$helpIcon.Location = New-Object System.Drawing.Point(1, 1)
#$form.Controls.Add($helpIcon)
$tooltip = (MakeToolTip)
$toolTip.AutoPopDelay = 90000
$toolTip.InitialDelay = 100
$helpIcon.Add_Click({
	#Start-Process -FilePath "notepad.exe" -ArgumentList "lua-pattern-matching.txt"
})
#$toolTip.SetToolTip($helpIcon,(Get-Content "searchhelp.txt" -Raw))

$Searchlabel = New-Object System.Windows.Forms.Label
$Searchlabel.Text = "Searching inside: This PC"
$Searchlabel.AutoSize = $true



$searchBox = New-Object System.Windows.Forms.TextBox
$SearchBox.TabIndex = 0
$searchBox.Location = New-Object System.Drawing.Point(20, 15)

#$searchBox.Size = New-Object System.Drawing.Size(440, 20)
$toolTip.SetToolTip($searchBox,(Get-Content "searchhelp.txt" -Raw))

$textBox_KeyDown = {
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        runsearch
    }
}


$searchBox.add_KeyDown($textBox_KeyDown)
$searchBox.Add_TextChanged({
	$currentCursorPosition = $searchBox.SelectionStart
	$searchBox.Text = $searchBox.Text -replace "`n", " "
	$searchBox.Text = $searchBox.Text -replace "  ", " "
	
	if ($searchBox.Text.Length -lt $currentCursorPosition) {
		$searchBox.SelectionStart = $searchBox.Text.Length
	} else {
		$searchBox.SelectionStart = $currentCursorPosition
	}
})






$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = 'Search'

$searchButton.Location = New-Object System.Drawing.Point(270, 40)
#$searchButton.AutoSize = $true
$searchButton.Size = New-Object System.Drawing.Size(120, 40)

$CaseSensitiveCheckBox = New-Object System.Windows.Forms.CheckBox
$CaseSensitiveCheckBox.Text = "Case Sensitive"
$CaseSensitiveCheckBox.Checked = $true
$toolTip.SetToolTip($CaseSensitiveCheckBox, "Make the search sensitve to UPPER and lower case letters")

$ContainesAllCheckBox = New-Object System.Windows.Forms.CheckBox
$ContainesAllCheckBox.Text = "Containes All"
$ContainesAllCheckBox.Checked = $true
$toolTip.SetToolTip($ContainesAllCheckBox, "Search only for files or folders that contain every key word in its name.")



$searchResultsLabel = New-Object System.Windows.Forms.Label
$searchResultsLabel.AutoSize = $true

$searchCountLabel = New-Object System.Windows.Forms.Label
$searchCountLabel.AutoSize = $true
$searchCountLabel.Text = "Search Count: 0"

$processCountlabel = New-Object System.Windows.Forms.Label
$processCountlabel.AutoSize = $true






# Create the MenuStrip
$MenuStrip = New-Object System.Windows.Forms.MenuStrip
$MenuStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom

# Create the "File" dropdown menu
$FileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$FileMenuItem.Text = "Options"
$FileMenuItem.Add_MouseHover({
    Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "AddContext.txt") -ErrorAction Ignore -Force
    Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "RemoveContext.txt") -ErrorAction Ignore -Force
	setContextStripItems
})


# Create the "Open Folder" menu item
$OpenFolderMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenFolderMenuItem.Text = "Search a folder"
$OpenFolderMenuItem.add_Click({
    $DialogResult = ChooseFolder -Message "Search here"

    if ($DialogResult) {
		Stop-Search
		$global:OneFolderSearch = $DialogResult
		setSearchLabel
        
    }
})

$ContextToolMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$ContextToolMenuItem.Text = "Add to File Explorer"
$ContextToolMenuItem.add_Click({
	Add-PowerSearchContextMenuItem
	setContextStripItems
})
$RmContextToolMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$RmContextToolMenuItem.Text = "Remove from File Explorer"
$RmContextToolMenuItem.add_Click({
	Remove-PowerSearchContextMenuItem
	setContextStripItems
})

# Add the "Open Folder" menu item to the "File" dropdown menu
$FileMenuItem.DropDownItems.Add($OpenFolderMenuItem)
function setContextStripItems {
	if ((Check-ContextMenuItem -Name "Power Search")) {
		$FileMenuItem.DropDownItems.Remove($ContextToolMenuItem)
		$FileMenuItem.DropDownItems.Add($RmContextToolMenuItem)
	} else {
		$FileMenuItem.DropDownItems.Remove($RmContextToolMenuItem)
		$FileMenuItem.DropDownItems.Add($ContextToolMenuItem)
		
		
	}
}


setContextStripItems


# Add the "File" dropdown menu to the MenuStrip
$MenuStrip.Items.Add($FileMenuItem)








function Add-ThousandsSeparator {
    param (
        [int]$Number
    )

    return $Number.ToString("N0", [Globalization.CultureInfo]::InvariantCulture)
}



function Update-ProcessCountLabel {
	$processCount = 0
	$newprocessCountlabelText = "Active Searches:"
	
	foreach ($drive in $global:drives) {
        $driveLetter = $drive.Root
        if (-Not $driveLetter) {
			$driveLetter = $drive.Substring(0, 1)
		} else {
			$driveLetter = $drive.Root.Substring(0, 1)
		}
		$isRunning = IsProcessRunning -driveLetter $driveLetter
		if ($isRunning) {
			$processCount += 1
			$newprocessCountlabelText = $newprocessCountlabelText + " " + $driveLetter + ","
		}
	}
	if ($processCountlabel.Text -ne $newprocessCountlabelText) {
		$processCountlabel.Text = $newprocessCountlabelText
	}
	
	
}

$ResultsCount = 0
$SearchCountTracker = 0
function Update-ItemCountLabel {
	
    $searchResultsLabel.Text = "Search Results: " + $global:ResultsCount
	$virtualListView.VirtualListSize = $global:ResultsCount
}
Update-ProcessCountLabel

function Get-DirectorySize {
    param (
        [string]$DirectoryPath
    )

    if (Test-Path $DirectoryPath) {
        $directoryInfo = Get-ChildItem -Recurse -Force -LiteralPath $DirectoryPath | Where-Object { -not $_.PSIsContainer }
        $totalSize = ($directoryInfo | Measure-Object -Property Length -Sum).Sum
        return $totalSize
    } else {
        Write-Host "The specified directory does not exist."
        return $null
    }
}

function Get-FileSize {
    param (
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        $itemInfo = Get-Item -LiteralPath $FilePath
        if (-not $itemInfo.PSIsContainer) {
            $fileSize = $itemInfo.Length
            return $fileSize
        } else {
            Write-Host "The specified path points to a folder, not a file."
            return $null
        }
    } else {
        Write-Host "The specified file does not exist."
        return $null
    }
}

function ConvertTo-ReadableSize {
    param (
        [int64]$Bytes
    )

    $units = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0

    while ($Bytes -ge 1024 -and $index -lt ($units.Length - 1)) {
        $Bytes /= 1024
        $index++
    }

    return "{0:N2} {1}" -f $Bytes, $units[$index]
}


function Remove-Newlines {
    param (
        [string]$InputString
    )

    return $InputString -replace '\r|\n', ''
}



$global:FileDataCache = @{}

function Get-CachedFileData {
    param (
        [string]$FilePath
    )

    if ($global:FileDataCache.ContainsKey($FilePath)) {
        return $global:FileDataCache[$FilePath]
    } else {
        
		$fileItem = Get-Item -LiteralPath $FilePath -ErrorAction Ignore

        if ($fileItem -and (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
            $fileData = @{
                Size = $fileItem.Length
                DateCreated = $fileItem.CreationTime
                DateModified = $fileItem.LastWriteTime
            }
        } else {
            $fileData = @{
                Size = 0
                DateCreated = $fileItem.CreationTime
                DateModified = $fileItem.LastWriteTime
            }
        }

        $global:FileDataCache[$FilePath] = $fileData
        return $fileData
    }
}



function Add-ContextMenuItem {
    param (
        [string]$Name,
        [string]$IconPath,
        [string]$ScriptPath
    )

    $itemPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$Name"
    $commandPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$Name\command"

    # Create the registry key for the context menu item
    New-Item -Path $itemPath -Force | Out-Null
    New-ItemProperty -Path $itemPath -Name "Icon" -Value $IconPath -PropertyType String -Force | Out-Null

    # Create the registry key for the command associated with the context menu item
    New-Item -Path $commandPath -Force | Out-Null
    New-ItemProperty -Path $commandPath -Name "(Default)" -Value "`"$ScriptPath`" `"%V`"" -PropertyType String -Force | Out-Null
}


function Remove-ContextMenuItem {
    param (
        [string]$Name
    )

    $itemPath = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\$Name"

    # Remove the registry key for the context menu item
    Remove-Item -Path $itemPath -Recurse -Force
}




$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
$PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"
$global:OneFolderSearch = Join-Path -Path $PowerSearchFolder -ChildPath "SearchSpot.txt"
$global:dontShow = $false
if (-Not (Test-Path $global:OneFolderSearch)) {
	$global:OneFolderSearch = $false
} else {
	$TempContent = Get-Content $global:OneFolderSearch -Raw
	Remove-Item $global:OneFolderSearch
	$global:OneFolderSearch = $TempContent
	$global:OneFolderSearch = $global:OneFolderSearch -replace "'" -replace '"'
	$global:OneFolderSearch = Remove-Newlines -InputString $global:OneFolderSearch
}




function Test-IsAdmin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    return $windowsPrincipal.IsInRole($adminRole)
}




function setSearchLabel {
	if ($global:OneFolderSearch) {
		$Searchlabel.Text = "Searching inside: `"$global:OneFolderSearch`""
		
	}
}
setSearchLabel



function Remove-PowerSearchContextMenuItem {
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure want to remove `"Power Search`" from the context menu inside of File Explorer?", "Power Search", [System.Windows.Forms.MessageBoxButtons]::YesNo)

    if ($result -eq 'Yes') {
        $AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
        $PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"

        if (-not (Test-Path -Path $PowerSearchFolder)) {
            New-Item -Path $PowerSearchFolder -ItemType Directory | Out-Null
        }

		New-Item -Path (Join-Path -Path $PowerSearchFolder -ChildPath "RemoveContext.txt") -ItemType File -Force
		Start-Process "shell:Appsfolder\33586Cherubim.PowerSearch_azr4d3dytcq80!PowerSearch" -Verb runAs -Wait
    }
}


function Add-PowerSearchContextMenuItem {
    $result = [System.Windows.Forms.MessageBox]::Show("Do you want to add `"Power Search`" to the context menu inside of File Explorer?`nThis will let you quickly start searching in a specific folder by right clicking the background inside of File Explorer.", "Power Search", [System.Windows.Forms.MessageBoxButtons]::YesNo)

    if ($result -eq 'Yes') {
        $AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
        $PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"

        if (-not (Test-Path -Path $PowerSearchFolder)) {
            New-Item -Path $PowerSearchFolder -ItemType Directory | Out-Null
        }

		New-Item -Path (Join-Path -Path $PowerSearchFolder -ChildPath "AddContext.txt") -ItemType File -Force
		Start-Process "shell:Appsfolder\33586Cherubim.PowerSearch_azr4d3dytcq80!PowerSearch" -Verb runAs -Wait
    }
}

function Add-PowerSearchContextMenuItemAdmin {
	$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
    $PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"
    if (Test-Path -Path (Join-Path -Path $PowerSearchFolder -ChildPath "AddContext.txt")) {
        Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "AddContext.txt")
        if (Test-IsAdmin) {
		
		
		Copy-Item -Path ".\logo5.ico" -Destination (Join-Path -Path $PowerSearchFolder -ChildPath "icon.ico") -Force
        Copy-Item -Path ".\context.bat" -Destination (Join-Path -Path $PowerSearchFolder -ChildPath "Script.bat") -Force

        Add-ContextMenuItem -Name "Power Search" -IconPath (Join-Path -Path $PowerSearchFolder -ChildPath "icon.ico") -ScriptPath (Join-Path -Path $PowerSearchFolder -ChildPath "Script.bat")
		$global:dontShow = $true
		}
		
    }
}

function Remove-PowerSearchContextMenuItemAdmin {
	$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
    $PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"
    if (Test-Path -Path (Join-Path -Path $PowerSearchFolder -ChildPath "RemoveContext.txt")) {
		Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "RemoveContext.txt")
		if (Test-IsAdmin) {
			Remove-Item -Path $PowerSearchFolder -Recurse -Force
		
		
			Remove-ContextMenuItem -Name "Power Search"
			$global:dontShow = $true
		}
		
    }
}

Add-PowerSearchContextMenuItemAdmin
Remove-PowerSearchContextMenuItemAdmin





$virtualListView = New-Object System.Windows.Forms.ListView
$virtualListView.Size = New-Object System.Drawing.Size(330, 150)
$virtualListView.Location = New-Object System.Drawing.Point(20, 110)
$virtualListView.View = [System.Windows.Forms.View]::Details
$virtualListView.VirtualMode = $true
$virtualListView.VirtualListSize = 1
$virtualListView.MultiSelect = $false

function Add-ListViewColumns {
    param (
        [System.Windows.Forms.ListView]$ListView,
        [System.Collections.Generic.List[hashtable]]$Columns
    )

    $columnHeaders = @()
    foreach ($column in $Columns) {
        $columnHeader = New-Object System.Windows.Forms.ColumnHeader
        $columnHeader.Text = $column["Text"]
        $columnHeader.Width = $column["Width"]
        $columnHeaders += $columnHeader
    }
    $ListView.Columns.AddRange($columnHeaders)
}

# Usage example:
$columns = [System.Collections.Generic.List[hashtable]]::new()
$columns.Add(@{"Text" = "Location"; "ToolTip" = "Click to"; "Width" = 410})
$columns.Add(@{"Text" = "Size"; "Width" = 80})
$columns.Add(@{"Text" = "Date Created"; "Width" = 110})
$columns.Add(@{"Text" = "Date Modified"; "Width" = 110})

Add-ListViewColumns -ListView $virtualListView -Columns $columns






$virtualListView.add_ColumnClick({
    param($senderr, $e)

    $clickedColumn = $e.Column
    
	if ($clickedColumn -gt 0) {
        if (($clickedColumn + 2) -eq $dropdown.SelectedIndex) {
			$global:AccedingSort = $AccedingSort -eq $false
		} else {
			$dropdown.SelectedIndex = ($clickedColumn + 2)
		} 
    } else {
		$global:AccedingSort = $AccedingSort -eq $false
	}
	Update-Sort
	$virtualListView.Invalidate()
})

$virtualListView_RetrieveVirtualItem = {
    $itemIndex = $_.ItemIndex
    $directoryPath = $global:VirtualList[$itemIndex]
	$item = New-Object System.Windows.Forms.ListViewItem($directoryPath)
    

	$fileInfo = Get-CachedFileData -FilePath $directoryPath

	$readableSize = ConvertTo-ReadableSize -Bytes $fileInfo.Size
	$item.SubItems.Add($readableSize)
	try {
		$DateCreated = $fileInfo.DateCreated.ToString("M-dd-yyyy h:mm tt")
		$item.SubItems.Add($DateCreated)
	} catch {
		$item.SubItems.Add(0)
	}
	
	try {
		$DateModified = $fileInfo.DateModified.ToString("M-dd-yyyy h:mm tt")
		$item.SubItems.Add($DateModified)
	} catch {
		$item.SubItems.Add(0)
	}
	

    $_.Item = $item
}

$virtualListView.add_RetrieveVirtualItem($virtualListView_RetrieveVirtualItem)









function SetColors($form){
	$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"
	$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
	$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}
}
SetColors($form)
function Resize-Control {
    param (
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.Control]$Control,
        [int]$WidthOffset = 50,
        [int]$HeightOffset = 50
    )

    if ($WidthOffset -ne 0) {
        $Control.Width = $Form.ClientSize.Width - ($WidthOffset + $Control.Location.X)
    }

    if ($HeightOffset -ne 0) {
        $Control.Height = $Form.ClientSize.Height - ($HeightOffset + $Control.Location.Y)
    }
}

function Set-ControlPosition {
    param (
        [System.Windows.Forms.Form]$Form,
        [System.Windows.Forms.Control]$Control,
        [string]$Edge,
        [int]$XOffset = 0,
        [int]$YOffset = 0
    )

    switch ($Edge) {
        'TopLeft' {
            $Control.Location = New-Object System.Drawing.Point($XOffset, $YOffset)
        }
        'TopRight' {
            $Control.Location = New-Object System.Drawing.Point(($Form.ClientSize.Width - $Control.Width - $XOffset), $YOffset)
        }
        'BottomLeft' {
            $Control.Location = New-Object System.Drawing.Point($XOffset, ($Form.ClientSize.Height - $Control.Height - $YOffset))
        }
        'BottomRight' {
            $Control.Location = New-Object System.Drawing.Point(($Form.ClientSize.Width - $Control.Width - $XOffset), ($Form.ClientSize.Height - $Control.Height - $YOffset))
        }
        default {
            throw "Invalid edge specified. Use 'TopLeft', 'TopRight', 'BottomLeft', or 'BottomRight'."
        }
    }
}

function setControlPosAndSize {
	Resize-Control -Form $form -Control $virtualListView -WidthOffset 50 -HeightOffset 60
	Resize-Control -Form $form -Control $searchBox -WidthOffset 200 -HeightOffset 0
	Set-ControlPosition -Form $form -Control $CaseSensitiveCheckBox -Edge 'TopRight' -XOffset 35 -YOffset 50
	Set-ControlPosition -Form $form -Control $ContainesAllCheckBox -Edge 'TopRight' -XOffset 35 -YOffset 75
	Set-ControlPosition -Form $form -Control $searchButton -Edge 'TopRight' -XOffset 20 -YOffset 10
	Set-ControlPosition -Form $form -Control $dropdown -Edge 'BottomRight' -XOffset 50 -YOffset 30
	Set-ControlPosition -Form $form -Control $SBlabel -Edge 'BottomRight' -XOffset 95 -YOffset 25
}




$form.Add_Resize({
	setControlPosAndSize
	

})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100


function Stop-Search {
	foreach ($drive in $global:drives) {
		$driveLetter = $drive.Root
        if (-Not $driveLetter) {
			$driveLetter = $drive.Substring(0, 1)
		} else {
			$driveLetter = $drive.Root.Substring(0, 1)
		}
		$isRunning = IsProcessRunning -driveLetter $driveLetter
		if ($isRunning) {
			$process = $runningProcesses[$driveLetter]
			Stop-Process -Id $process.Id -Force
		}
	}
}


function startLuaSearch {
	$process = $null
	$luaScriptPath = "luasearch.lua"
	if (Test-Path -LiteralPath "README.md") {
		$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath -RedirectStandardError "error.txt" -PassThru
	} else {
		$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath -RedirectStandardError "error.txt" -PassThru -WindowStyle Hidden
	}
	return $process
}


function runsearch {

	if ($searchBox.Text.Length -eq 1) {
		$messageBoxResult = [System.Windows.Forms.MessageBox]::Show("The search text is only one character. This can render hundreds of thousands of results and will be very slow.`n`n Are you sure you want to continue?", "Confirm Search", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
		if ($messageBoxResult -eq [System.Windows.Forms.DialogResult]::No) {
			return
		}
	} elseif ($searchBox.Text.Length -lt 2) {
		return
	}
	$global:FileDataCache = @{}
	$global:SearchSpeed = 0
	$global:SearchCountOffset = 0
	$global:ProcessCount = 0
	$global:SearchStartTime = Get-Date
	$global:lastLineRead = @{}
	$timer.Stop()
	$timer.Interval = 500
	$global:ResultsCount = 0
	$searchCountLabel.Text = "Search Count: 0"
	$global:SearchCountTracker = 0
	$searchText = $searchBox.Text
	$global:VirtualList = @()
	$virtualListView.Invalidate()
	Update-ItemCountLabel
    Remove-Item "GUIoutput.txt" -ErrorAction Ignore
    Remove-Item "SearchOptions.txt" -ErrorAction Ignore

    
    

	$lua = "SearchAgent.exe" 
	Stop-Search
	
	Out-File -FilePath "SearchOptions.txt" -InputObject (
		"SearchText=$searchText`n" +
		"CaseSensitive=" + $CaseSensitiveCheckBox.Checked.ToString() + "`n" +
		"ContainesAll=" + $ContainesAllCheckBox.Checked.ToString() + "`n"
	) -Encoding ascii -Append
	
	if ($global:OneFolderSearch) {
		Out-File -FilePath "GUIoutput.txt" -InputObject ($global:OneFolderSearch) -Encoding ascii -Append
		
		$global:drives = @(($global:OneFolderSearch.Substring(0,3)))
		$runningProcesses[($global:OneFolderSearch.Substring(0,1))] = startLuaSearch
	} else {
		$global:drives = Get-PSDrive -PSProvider FileSystem
		foreach ($drive in $global:drives) {
			
			Out-File -FilePath "GUIoutput.txt" -InputObject ($drive.Root.ToString()) -Encoding ascii -Append
			

			$process = startLuaSearch
			$driveLetter = $drive.Root.Substring(0, 1)
			 $runningProcesses[$driveLetter] = $process
			 
		
			while (Test-PathWithErrorHandling "GUIoutput.txt") {
				Start-Sleep -Milliseconds 1
			}
		}
	}
    $timer.Start()
}


$runningProcesses = @{}
$drives = Get-PSDrive -PSProvider FileSystem
$searchButton.Add_Click({
    runsearch
})
function IsProcessRunning {
	param([string]$driveLetter)

	$process = $runningProcesses[$driveLetter]

	if ($null -ne $process) {
		try {
			$runningProcess = Get-Process -Id $process.Id -ErrorAction Stop
			return $true
		}
		catch {
			return $false
		}
	}

	return $false
}

function Get-DividedValueByElapsedTime {
    param (
        [DateTime]$StartTime,
        [double]$Number
    )

	if ($StartTime -eq (Get-Date)) {
		return 0
	}
    $elapsedTime = (Get-Date) - $StartTime
    $elapsedSeconds = $elapsedTime.TotalSeconds
    $result = $Number / $elapsedSeconds

    return $result
}
$global:linesPerSecond = 400
function ProcessContent {
    param (
        [array]$Content,
        [int]$StartingLine
    )

    $lineNumber = $StartingLine
    $counter = 0

    $MaxToLoad = (1 / ($runningProcesses.Count)) * $global:linesPerSecond

    # Get the start time
    $startTime = Get-Date

    while ($counter -lt $Content.Count) {
        $lineNumber++
        $global:VirtualList += $Content[$counter]

        if (($lineNumber - $StartingLine) -gt ($MaxToLoad)) {
            $counter = $Content.Count # This will stop the loop
        } else {
            $counter++
        }
    }

    # Get the end time
    $endTime = Get-Date

    # Calculate the duration and lines per second
    $duration = $endTime - $startTime
    if ($lineNumber -ne $StartingLine) {
		$NewlinesPerSecond = ($lineNumber - $StartingLine) / ($duration.TotalMilliseconds/1000)
		if ($NewlinesPerSecond -lt 10000) {$global:linesPerSecond = ($NewlinesPerSecond+$global:linesPerSecond)/2}
	}
    

    return $lineNumber
}


$SearchSpeed = 0
$SearchCountOffset = 0
$ProcessCount = 0
$SearchStartTime = Get-Date
$lastLineRead = @{}
$timer.Add_Tick({
    $MadeChange = $false
    $searchCount = 0
    $SearchIsRunning = $false
	$RunningSearches = 0
	foreach ($drive in $global:drives) {
        $driveLetter = $drive.Root
        if (-Not $driveLetter) {
			$driveLetter = $drive.Substring(0, 1)
		} else {
			$driveLetter = $drive.Root.Substring(0, 1)
		}
		$isRunning = IsProcessRunning -driveLetter $driveLetter
		if ($isRunning) {
			$RunningSearches += 1
		}
		$SearchIsRunning = $isRunning -or $SearchIsRunning
        $resultFile = "$driveLetter" + "results.txt"
        $statsFile = "$driveLetter" + "stats.txt"
        if (Test-Path -LiteralPath $statsFile) {
            $SearchStats = LoadOptions -Filename $statsFile
            $searchCount += $SearchStats["searchcount"]
        }
        if (Test-Path -LiteralPath $resultFile) {
            if (-not $global:lastLineRead.ContainsKey($driveLetter)) {
                $global:lastLineRead[$driveLetter] = 0
            }
            $content = Get-Content $resultFile -ErrorAction Ignore | Select-Object -Skip $global:lastLineRead[$driveLetter]

			$lineNumber = ProcessContent -Content $content -StartingLine ($global:lastLineRead[$driveLetter])
			
			if ($global:VirtualList.Count -ne $global:ResultsCount) {
				$global:ResultsCount = $global:VirtualList.Count 
				$MadeChange = $true 
			}
			
            $global:lastLineRead[$driveLetter] = $lineNumber
            if (-Not $isRunning) {
                Remove-Item $resultFile
            }
        }
    }
    if ($MadeChange) {
        Update-ItemCountLabel
        $timer.Interval = 1000
		# Store the value of the currently selected item
		# Sort the items in the VirtualList
		Update-Sort
	
        
        $virtualListView.Invalidate()
    }
	$global:SearchCountTracker = [Math]::max($searchCount, $global:SearchCountTracker)
	if ($global:ProcessCount -ne $RunningSearches) {
		$global:ProcessCount = $RunningSearches
		
		$global:SearchStartTime = Get-Date
		$global:SearchCountOffset = $global:SearchCountTracker
	}

	
	if ($SearchIsRunning) {
		$NewSearchSpeed = Get-DividedValueByElapsedTime -StartTime $global:SearchStartTime -Number ($global:SearchCountTracker - $global:SearchCountOffset)
		if ($NewSearchSpeed -gt 0) {
			$global:SearchSpeed = [Math]::Round($NewSearchSpeed)
		}
		
		
	} else {
		$global:SearchSpeed = 0
	}
    if ($global:SearchSpeed -gt 0) {
		$searchCountLabel.Text = "Search Count: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker) + "   f/s: " + (Add-ThousandsSeparator -Number $global:SearchSpeed)
		
	} else {
		$searchCountLabel.Text = "Search Count: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker)
	}
	
    Update-ProcessCountLabel
})

Update-ItemCountLabel

$virtualListView_SelectedIndexChanged = {
    if ($virtualListView.SelectedIndices.Count -gt 0) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
        $lastLeaf = Split-Path -Path $selectedDirectory -Leaf
        
        $searchMenuItem.Text = "Search `"" + $lastLeaf + "`""
		$openInExplorerMenuItem.Enabled = $true
		$searchMenuItem.Enabled = $true
    } else {
		$openInExplorerMenuItem.Enabled = $false
		$searchMenuItem.Enabled = $false
		$searchMenuItem.Text = "Search"
	}
}

$virtualListView.add_SelectedIndexChanged($virtualListView_SelectedIndexChanged)

$virtualListView_MouseDoubleClick = {
    if ($virtualListView.SelectedIndices.Count -gt 0) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
		Write-Host $selectedDirectory
        Start-Process "explorer.exe" -ArgumentList "/select,`"$selectedDirectory`""
    }
	
}
# Create a context menu strip
$contextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip

# Create the 'Open in Explorer' menu item
$openInExplorerMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Show in Explorer")
$openInExplorerMenuItem.Enabled = $false

$openInExplorerMenuItem.add_Click({
    if ($virtualListView.SelectedIndices.Count -gt 0) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
        Write-Host $selectedDirectory
        Start-Process "explorer.exe" -ArgumentList "/select,`"$selectedDirectory`""
    }
})

# Create the 'Search [last leaf]' menu item
$searchMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Search")
$searchMenuItem.Enabled = $false
$searchMenuItem.add_Click({
    if ($virtualListView.SelectedIndices.Count -gt 0) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
        $lastLeaf = Split-Path -Path $selectedDirectory -Leaf
        $searchBox.Text = $lastLeaf
        runsearch
    }
})

# Add menu items to the context menu strip
$contextMenuStrip.Items.Add($openInExplorerMenuItem)
$contextMenuStrip.Items.Add($searchMenuItem)

# Assign the context menu strip to the virtualListView
$virtualListView.ContextMenuStrip = $contextMenuStrip

$virtualListView.add_MouseDoubleClick($virtualListView_MouseDoubleClick)
$form.Add_FormClosing({
	$timer.Stop()
	$timer.Dispose()
	Stop-Search
})
$form.Controls.Add($searchBox)
$form.Controls.Add($virtualListView)
$form.Controls.Add($MenuStrip)
$form.Controls.Add($searchButton)
$form.Controls.Add($CaseSensitiveCheckBox)
$form.Controls.Add($ContainesAllCheckBox)

$form.Controls.Add($dropdown)
$form.Controls.Add($SBlabel)



$LeftLayout.Controls.Add($Searchlabel)

$LeftLayout.Controls.Add($searchCountLabel)
$LeftLayout.Controls.Add($searchResultsLabel)

$LeftLayout.Controls.Add($processCountlabel)



$form.Controls.Add($LeftLayout)


setControlPosAndSize


if (-Not $global:dontShow) {
	$form.ShowDialog()
}
$timer.Stop()
$timer.Dispose()
