Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()



$AppDataFolder = [Environment]::GetFolderPath('ApplicationData')
$PowerSearchFolder = Join-Path -Path $AppDataFolder -ChildPath "Power Search"
if (-not (Test-Path -Path $PowerSearchFolder)) {
    New-Item -Path $PowerSearchFolder -ItemType Directory | Out-Null
}

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
function AddControlsToForm($form, $controls) {
    foreach ($control in $controls) {
        $form.Controls.Add($control)
    }
}

function RemoveControlsFromForm($form, $controls) {
    foreach ($control in $controls) {
        $form.Controls.Remove($control)
    }
}
function DisableControls($controls) {
    foreach ($control in $controls) {
        $control.Enabled = $false
    }
}

function EnableControls($controls) {
    foreach ($control in $controls) {
        $control.Enabled = $true
    }
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

$global:VirtualList = New-Object 'System.Collections.Generic.List[string]'
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
			$global:VirtualList = New-Object 'System.Collections.Generic.List[string]'
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


$FilesOnlyCheckBox = New-Object System.Windows.Forms.CheckBox
$FilesOnlyCheckBox.Text = "Files Only"
$FilesOnlyCheckBox.Checked = $false
$toolTip.SetToolTip($FilesOnlyCheckBox, "Ignore folder names and only search for files.")
$FilesOnlyCheckBox.add_CheckedChanged({
    if ($FilesOnlyCheckBox.Checked) {
        $FoldersOnlyCheckBox.Checked = $false
    }
})

$FoldersOnlyCheckBox = New-Object System.Windows.Forms.CheckBox
$FoldersOnlyCheckBox.Text = "Folders Only"
$FoldersOnlyCheckBox.Checked = $false
$toolTip.SetToolTip($FoldersOnlyCheckBox, "Ignore file names and only search for folders.")
$FoldersOnlyCheckBox.add_CheckedChanged({
    if ($FoldersOnlyCheckBox.Checked) {
        $FilesOnlyCheckBox.Checked = $false
    }
})




$searchResultsLabel = New-Object System.Windows.Forms.Label
$searchResultsLabel.AutoSize = $true

$searchCountLabel = New-Object System.Windows.Forms.Label
$searchCountLabel.AutoSize = $true
$searchCountLabel.Text = " "

$processCountlabel = New-Object System.Windows.Forms.Label
$processCountlabel.AutoSize = $true






# Create the MenuStrip
$MenuStrip = New-Object System.Windows.Forms.MenuStrip
$MenuStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom

# Create the "File" dropdown menu
$FileMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$FileMenuItem.Text = "Options"
#$FileMenuItem.Add_MouseHover({
    #Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "AddContext.txt") -ErrorAction Ignore -Force
    #Remove-Item (Join-Path -Path $PowerSearchFolder -ChildPath "RemoveContext.txt") -ErrorAction Ignore -Force
	#setContextStripItems
#})


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
	#setContextStripItems
})
$RmContextToolMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$RmContextToolMenuItem.Text = "Remove from File Explorer"
$RmContextToolMenuItem.add_Click({
	Remove-PowerSearchContextMenuItem
	#setContextStripItems
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

# Create the Add button
$AddButton = New-Object System.Windows.Forms.Button
$AddButton.Text = 'Add to File Explorer'
$AddButton.Location = New-Object System.Drawing.Point(20, 20)
$AddButton.Size = New-Object System.Drawing.Size(150, 23)
$AddButton.Add_Click({
    Add-PowerSearchContextMenuItem
    setButtonItems
})


# Create the Remove button
$RemoveButton = New-Object System.Windows.Forms.Button
$RemoveButton.Text = 'Remove from File Explorer'
$RemoveButton.Location = New-Object System.Drawing.Point(20, 20)  # Same location as the Add button
$RemoveButton.Size = New-Object System.Drawing.Size(150, 23)
$RemoveButton.Add_Click({
    Remove-PowerSearchContextMenuItem
    setButtonItems
})

function setButtonItems {
    if ((Check-ContextMenuItem -Name 'Power Search')) {
        $settingsForm.Controls.Remove($AddButton)
        $settingsForm.Controls.Add($RemoveButton)
    } else {
        $settingsForm.Controls.Remove($RemoveButton)
        $settingsForm.Controls.Add($AddButton)
    }
}

# Initial setting of button items




$settingsMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$settingsMenuItem.Text = 'Settings'
$FileMenuItem.DropDownItems.Add($settingsMenuItem)

$settingsForm = New-Object System.Windows.Forms.Form
$settingsForm.Text = 'Settings'
$settingsForm.StartPosition = 'CenterParent'
$settingsForm.Size = '400,400'
$settingsForm.FormBorderStyle = 'FixedDialog'
$settingsForm.MaximizeBox = $false
$settingsForm.MinimizeBox = $false
$settingsForm.Icon = "logo5.ico"
$settingsForm.Add_MouseHover({
	setButtonItems
})
#setContextStripItems
function loadSettingsForm {
    # Create settings form
    $global:Config = LoadSettings
    
    # Create ComboBox for SearchMethod
    $searchMethodDropdown = New-Object System.Windows.Forms.ComboBox
    $searchMethodDropdown.Items.Add("Normal")
    $searchMethodDropdown.Items.Add("Normal FIFO")
    $searchMethodDropdown.Items.Add("Normal Index")
    $searchMethodDropdown.Items.Add("RoboSearch")
    $searchMethodDropdown.Items.Add("RoboSearchMT")
    $searchMethodDropdown.Location = New-Object System.Drawing.Point(120, 60)
    $searchMethodDropdown.Size = New-Object System.Drawing.Size(150, 20)
    $searchMethodDropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $searchMethodDropdown.SelectedIndex = $searchMethodDropdown.FindStringExact($global:Config.SearchMethod)
    $settingsForm.Controls.Add($searchMethodDropdown)
    
    # Create label for ComboBox
    $searchMethodLabel = New-Object System.Windows.Forms.Label
    $searchMethodLabel.Text = 'Search Method:'
    $searchMethodLabel.Location = New-Object System.Drawing.Point(20, 60)
    $settingsForm.Controls.Add($searchMethodLabel)
    
    # Create label for SearchMethod descriptions
    $searchMethodDescriptions = @{
        "Normal" = "Normal: A standard recursive search."
        "Normal FIFO" = "Normal FIFO: A non-recursive, layer-by-layer search. Typically, this method retrieves the desired results faster than the 'Normal' search, but takes slightly more RAM"
        "Normal Index" = "Normal Index: Standard recursive search that simultaneously builds a file tree for extremely quick subsequent searches. Note that this method uses significantly more RAM and will revert to 'Normal FIFO' if you are not searching the entire drive."
        "RoboSearch" = "RoboSearch: Leverages Microsoft Robocopy's list function for searches. While this method can be slow when dealing with a large number of folders, it is incredibly quick when searching folders with numerous files. Please note that it does not support non-English characters."
        "RoboSearchMT" = "RoboSearchMT: Similar to 'RoboSearch' but with multi-threading enabled. It performs a two-pass search: pass one is a multi-threaded search for files only, and pass two is a single-threaded search for folders only. Results will not be displayed until the first pass is completed. This method demands lots of CPU resources and may yield slower results than 'RoboSearch' on systems with few logical processors. However, on high-end CPUs, this is the fastest search method. Please note that it does not support non-English characters."
    }
    
    $searchMethodDescriptionLabel = New-Object System.Windows.Forms.Label
    $searchMethodDescriptionLabel.Text = $searchMethodDescriptions[$searchMethodDropdown.SelectedItem.ToString()]
    $searchMethodDescriptionLabel.Location = New-Object System.Drawing.Point(20, 100)
    $searchMethodDescriptionLabel.Size = New-Object System.Drawing.Size(250, 200)
    $settingsForm.Controls.Add($searchMethodDescriptionLabel)
    
    $searchMethodDropdown.Add_SelectedIndexChanged({
        $searchMethodDescriptionLabel.Text = $searchMethodDescriptions[$searchMethodDropdown.SelectedItem.ToString()]
        if ($searchMethodDropdown.SelectedItem.ToString() -eq "RoboSearchMT") {
            $settingsForm.Controls.Add($ThreadsPDComboBox)
            $settingsForm.Controls.Add($ThreadsPDLabel)
        } else {
            $settingsForm.Controls.remove($ThreadsPDComboBox)
            $settingsForm.Controls.remove($ThreadsPDLabel)
        }
    })
    
    $ThreadsPDComboBox = New-Object System.Windows.Forms.ComboBox
    $ThreadsPDComboBox.Location = New-Object System.Drawing.Point(290, 200)
    $ThreadsPDComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $ThreadsPDComboBox.Size = New-Object System.Drawing.Size(40, 20)
    
    # Get the total number of logical processors
    $logicalProcessors = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
    
    # Populate the ComboBox with the numbers 1 through the total number of logical processors
    for ($i = 1; $i -le $logicalProcessors; $i++) {
        $ThreadsPDComboBox.Items.Add($i)
    }
    $ThreadsPDComboBox.SelectedIndex = (($global:Config.ThreadsPD-1))
    
    # Create a new label
    $ThreadsPDLabel = New-Object System.Windows.Forms.Label
    $ThreadsPDLabel.Text = "Threads per drive: "
    $ThreadsPDLabel.Location = New-Object System.Drawing.Point(280, 180)
    $ThreadsPDLabel.Size = New-Object System.Drawing.Size(100, 20)
    
    if ($searchMethodDropdown.SelectedItem.ToString() -eq "RoboSearchMT") {
        $settingsForm.Controls.Add($ThreadsPDComboBox)
        $settingsForm.Controls.Add($ThreadsPDLabel)
    }
    # Create Save button
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = 'Save'
    $saveButton.Location = New-Object System.Drawing.Point(20, 320)
    $saveButton.Size = New-Object System.Drawing.Size(75, 23)
    $saveButton.Add_Click({
        # Save the state of the dropdown in your settings
        SaveSettings ("SearchMethod") ($searchMethodDropdown.SelectedItem.ToString())
        SaveSettings ("ThreadsPD") ($ThreadsPDComboBox.SelectedItem.ToString())
        $settingsForm.Close()
    })
    $settingsForm.Controls.Add($saveButton)
    
    # Create Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Cancel'
    $cancelButton.Location = New-Object System.Drawing.Point(110, 320)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 23)
    $cancelButton.Add_Click({ $settingsForm.Close() })
    $settingsForm.Controls.Add($cancelButton)
    $settingsForm.ShowDialog()
    RemoveControlsFromForm $settingsForm @(
        $searchMethodDropdown,
        $searchMethodLabel,
        $searchMethodDescriptionLabel,
        $saveButton,
        $ThreadsPDComboBox,
        $ThreadsPDLabel,
        $cancelButton
    )
}

    
$settingsMenuItem.Add_Click({
    setButtonItems
    loadSettingsForm
    
})
function ConvertTo-Hashtable($inputObject) {
    $hashTable = @{}
    Get-Member -InputObject $inputObject -MemberType NoteProperty | ForEach-Object {
        $hashTable[$_.Name] = $inputObject.($_.Name)
    }
    return $hashTable
}

# Functions
function SaveSettings([string]$key, $Settingvalue) {
    $appData = [Environment]::GetFolderPath('ApplicationData')
    $settingsDir = Join-Path $appData 'Power Search'
    $settingsFile = Join-Path $settingsDir 'settings.json'

    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Force -Path $settingsDir | Out-Null
    }
    
    # Load existing settings
    if (Test-Path $settingsFile) {
        $settingsJson = Get-Content -Path $settingsFile
        $settingsObject = $settingsJson | ConvertFrom-Json
        $settings = ConvertTo-Hashtable $settingsObject
    } else {
        $settings = @{}
    }

    # Update the specified key with the provided value
    Write-Host $Settingvalue
    $settings[$key] = $Settingvalue

    # Save the updated settings
    $settingsJson = $settings | ConvertTo-Json
    Set-Content -Path $settingsFile -Value $settingsJson
}
function SettingsExists {
    $appData = [Environment]::GetFolderPath('ApplicationData')
    $settingsDir = Join-Path $appData 'Power Search'
    $settingsFile = Join-Path $settingsDir 'settings.json'
    return (Test-Path $settingsFile)
}


function LoadSettings {
    $appData = [Environment]::GetFolderPath('ApplicationData')
    $settingsDir = Join-Path $appData 'Power Search'
    $settingsFile = Join-Path $settingsDir 'settings.json'

    if (Test-Path $settingsFile) {
        $settingsJson = Get-Content -Path $settingsFile
        $settings = $settingsJson | ConvertFrom-Json

        return $settings
    } else {
        return $null
    }
}


$global:drives = Get-PSDrive -PSProvider FileSystem
$global:Config = LoadSettings
$global:logicalProcessors = (Get-WmiObject -Class Win32_Processor).NumberOfLogicalProcessors
$driveCount = $global:drives.Count

$ProcDriveRatio = $global:logicalProcessors / $driveCount
$roundedRatio = [math]::Floor($ProcDriveRatio)

$MinDefaultThreads = 4

if ($ProcDriveRatio -lt $MinDefaultThreads) {
    $roundedRatio = $MinDefaultThreads
}

if ($global:Config.SearchMethod -eq $null) {
    if ($ProcDriveRatio -ge $MinDefaultThreads) {
        #SaveSettings ("SearchMethod") ("RoboSearchMT")
    } else {
    }
    SaveSettings ("SearchMethod") ("RoboSearch")
}

if ($global:Config.ThreadsPD -eq $null) {
    SaveSettings ("ThreadsPD") ($roundedRatio)
}

$global:Config = LoadSettings


# Add the "File" dropdown menu to the MenuStrip
$MenuStrip.Items.Add($FileMenuItem)








function Add-ThousandsSeparator {
    param (
        [int]$Number
    )

    return $Number.ToString("N0", [Globalization.CultureInfo]::InvariantCulture)
}
$global:runningProcesses = @{}

function IsProcessRunning {
	param([string]$driveLetter)

	$process = $global:runningProcesses[$driveLetter]

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
	
    $searchResultsLabel.Text = "Search Results: " + (Add-ThousandsSeparator -Number $global:ResultsCount)
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
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    if ($global:FileDataCache.ContainsKey($FilePath)) {
        return $global:FileDataCache[$FilePath]
    }

    $fileItem = Get-Item -LiteralPath $FilePath -ErrorAction Ignore

    if ($fileItem) {
        $fileData = @{
            Size = $fileItem.Length
            DateCreated = $fileItem.CreationTime
            DateModified = $fileItem.LastWriteTime
        }
    } else {
        $fileData = @{
            Size = 0
            DateCreated = [DateTime]::MinValue
            DateModified = [DateTime]::MinValue
        }
    }

    $global:FileDataCache[$FilePath] = $fileData
    return $fileData
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
	$global:OneFolderSearch = $global:OneFolderSearch.TrimEnd()
}


$SearchIndexFolder = Join-Path -Path $PowerSearchFolder -ChildPath "IndexTrees"

# Create the directory if it doesn't exist
if (!(Test-Path -Path $SearchIndexFolder)) {
    New-Item -ItemType Directory -Path $SearchIndexFolder | Out-Null
}

# Apply compression
Invoke-Expression "compact /C `"$SearchIndexFolder`" 2>&1"

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
			#Remove-Item -Path $PowerSearchFolder -Recurse -Force
			Remove-Item -Path (Join-Path -Path $PowerSearchFolder -ChildPath "Script.bat") -Force
			Remove-Item -Path (Join-Path -Path $PowerSearchFolder -ChildPath "icon.ico") -Force
            
            
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
SetColors($settingsForm)
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
	Set-ControlPosition -Form $form -Control $FilesOnlyCheckBox -Edge 'TopRight' -XOffset 135 -YOffset 50
	Set-ControlPosition -Form $form -Control $FoldersOnlyCheckBox -Edge 'TopRight' -XOffset 135 -YOffset 75
	Set-ControlPosition -Form $form -Control $searchButton -Edge 'TopRight' -XOffset 20 -YOffset 10
	Set-ControlPosition -Form $form -Control $dropdown -Edge 'BottomRight' -XOffset 50 -YOffset 30
	Set-ControlPosition -Form $form -Control $SBlabel -Edge 'BottomRight' -XOffset 95 -YOffset 25
}




$form.Add_Resize({
	setControlPosAndSize
	

})

$ResultGatherTimer = New-Object System.Windows.Forms.Timer
$ResultGatherTimer.Interval = 100
#function Stop-ProcessWithChildren {
#    param (
#        [Parameter(Mandatory=$true)]
#        [int] $fPID
#    )
#
#    # Get all processes
#    $allProcesses = Get-WmiObject -Query "Select * From Win32_Process"
#
#    # Find child processes
#    $childProcesses = $allProcesses | Where-Object { $_.ParentProcessId -eq $fPID }
#
#    # Stop child processes
#    $childProcesses | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
#
#    # Stop the parent process
#    Stop-Process -Id $fPID -Force
#}

function Stop-ProcessWithChildren {
    param (
        [Parameter(Mandatory=$true)]
        [int] $fPID
    )

    # Stop the process and its child processes
    Start-Process -NoNewWindow -FilePath "taskkill" -ArgumentList "/F /T /PID $fPID"
}

# Usage

#Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "StopSearch.txt") -Force
function Stop-Search {
    #New-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "StopSearch.txt") -ItemType File -Force
    foreach ($drive in $global:drives) {
        $driveLetter = $drive.Root
        if (-Not $driveLetter) {
            $driveLetter = $drive.Substring(0, 1)
		} else {
            $driveLetter = $drive.Root.Substring(0, 1)
		}
		$isRunning = IsProcessRunning -driveLetter $driveLetter
		if ($isRunning) {
            $process = $global:runningProcesses[$driveLetter]
			#Stop-Process -Id $process.Id -Force
            Stop-ProcessWithChildren -fPID $process.Id
            
            # Wait for the process to actually stop
            #while (Get-Process -Id $process.Id -ErrorAction SilentlyContinue) {
                #Start-Sleep -Seconds 1
            #}
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

function Get-QuickSearchTable {
    param(
        [string]$inputString
    )
    $inputString = $inputString + " "
    # Split the string into words
    $words = $inputString -split '\s+'

    # Filter out undesired words
    $quickSearchTable = @()
    foreach ($word in $words) {
        if ($word.StartsWith('-')) {
            continue
        }
        if ($word.StartsWith('"-') -and $word.EndsWith('"')) {
            continue
        }
        $quickSearchTable += $word
    }

    return $quickSearchTable
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
	$global:lastLineRead = @{}
    $global:ResultFileSizes = @{}
    $global:drives = Get-PSDrive -PSProvider FileSystem
	$global:SearchStartTime = Get-Date
    
	$ResultGatherTimer.Stop()
	$ResultGatherTimer.Interval = 500
	$global:ResultsCount = 0
	$searchCountLabel.Text = "Searching..."
	$global:SearchCountTracker = 0
	$searchText = $searchBox.Text
	$global:VirtualList = New-Object 'System.Collections.Generic.List[string]'
	$virtualListView.Invalidate()
	Update-ItemCountLabel
    Remove-Item "GUIoutput.txt" -ErrorAction Ignore
    Remove-Item "SearchOptions.txt" -ErrorAction Ignore

    
    

	$lua = "SearchAgent.exe" 
	Stop-Search
	$global:Config = LoadSettings
    $hasShortWord = $false
    $quickSearchTable = Get-QuickSearchTable -inputString $searchBox.Text
    $hasManyWords = $quickSearchTable.Count -ge 3

    for ($i=0; $i -lt $quickSearchTable.Count; $i++) {
        $word = $quickSearchTable[$i]
        if ($word.Length -le 4) {
            if ($hasShortWord -ne $false) {
                $hasShortWord = [math]::Min($hasShortWord, $word.Length)
            } else {
                $hasShortWord = $word.Length
            }
        }
    }
    if (-Not $hasShortWord) {
        $hasShortWord = 999
    }
    if (($hasManyWords) -or ($hasShortWord -le 4)) {
        #$global:Config.RoboSearch = $false
    }

	Out-File -FilePath "SearchOptions.txt" -InputObject (
		"SearchText=$searchText`n" +
		"CaseSensitive=" + $CaseSensitiveCheckBox.Checked.ToString() + "`n" +
		"ContainesAll=" + $ContainesAllCheckBox.Checked.ToString() + "`n" +
		"FilesOnly=" + $FilesOnlyCheckBox.Checked.ToString() + "`n" +
		"FoldersOnly=" + $FoldersOnlyCheckBox.Checked.ToString() + "`n" +
		"ThreadsPD=" + $global:Config.ThreadsPD.ToString() + "`n" +
		"SearchMethod=" + $global:Config.SearchMethod.ToString() + "`n"
	) -Encoding ascii -Append
	
	if ($global:OneFolderSearch) {
		Out-File -FilePath "GUIoutput.txt" -InputObject ($global:OneFolderSearch) -Encoding ascii -Append
		
		$global:drives = @(($global:OneFolderSearch.Substring(0,3)))
		$global:runningProcesses[($global:OneFolderSearch.Substring(0,1))] = startLuaSearch
	} else {
		$global:drives = Get-PSDrive -PSProvider FileSystem
		foreach ($drive in $global:drives) {
			
			Out-File -FilePath "GUIoutput.txt" -InputObject ($drive.Root.ToString()) -Encoding ascii -Append
			

			$process = startLuaSearch
			$driveLetter = $drive.Root.Substring(0, 1)
			 $global:runningProcesses[$driveLetter] = $process
			 
		
			while (Test-PathWithErrorHandling "GUIoutput.txt") {
				Start-Sleep -Milliseconds 1
			}
		}
	}
    $ResultGatherTimer.Start()
}




$searchButton.Add_Click({
    runsearch
})


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
        [int]$StartingLine,
        [boolean]$isRunning,
        [string]$resultFile,
        [string]$driveLetter
    )

    $lineNumber = $StartingLine
    $counter = 0

    $MaxToLoad = (1 / ([Math]::max(($global:runningProcesses.Count), 1))) * $global:linesPerSecond
    $MaxToLoad = [Math]::max($MaxToLoad, 10000)
    if (-Not $isRunning) {$MaxToLoad = 100000}
    # Get the start time
    $startTime = Get-Date
    $TotalLength = $Content.Count
    while ($counter -lt $TotalLength) {
        $added = $global:VirtualList.Add($Content[$counter])
        
        if (($counter) -gt ($MaxToLoad)) {
            $lineNumber += ($counter+1)
            $counter = ($TotalLength+1) # This will stop the loop
        } else {
            $counter++
        }
    }
    if ($counter -eq $TotalLength) {
        $lineNumber += ($counter)
        if ((-Not $isRunning)) {
            #Remove-Item $resultFile
            #Remove-Item ($driveLetter+"done.txt")
        }
    }
    # Get the end time
    $endTime = Get-Date

    # Calculate the duration and lines per second
    $duration = $endTime - $startTime
    if ($lineNumber -ne $StartingLine) {
		$NewlinesPerSecond = ($lineNumber - $StartingLine) / ($duration.TotalMilliseconds/1000)
        $NewlinesPerSecond = [Math]::max($NewlinesPerSecond, 100)
        $NewlinesPerSecond = [Math]::min($NewlinesPerSecond, 10000)
		$global:linesPerSecond = ($NewlinesPerSecond+$global:linesPerSecond)/2
        $global:linesPerSecond = [Math]::max($global:linesPerSecond, 100)
	}
    

    return $lineNumber
}


$SearchSpeed = 0
$SearchCountOffset = 0
$ProcessCount = 0
$SearchStartTime = Get-Date
$global:lastLineRead = @{}
$global:ResultFileSizes = @{}
$ResultGatherTimer.Add_Tick({
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
		$isRunning = (-Not (Test-Path ($driveLetter+"done.txt")))
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
        $resultFileSize = 0
        if (Test-Path -LiteralPath $resultFile) {
            $resultFileItem = Get-Item $resultFile
            $resultFileSize = $resultFileItem.Length
        }
        if (-not $global:ResultFileSizes.ContainsKey($driveLetter)) {
            $global:ResultFileSizes[$driveLetter] = 0
        }
        if (($resultFileSize -gt $global:ResultFileSizes[$driveLetter]) -and (Test-Path -LiteralPath $resultFile)) {
            if (-not $global:lastLineRead.ContainsKey($driveLetter)) {
                $global:lastLineRead[$driveLetter] = 0
            }
            $global:ResultFileSizes[$driveLetter] = $resultFileSize
            $content = Get-Content $resultFile -ErrorAction Ignore | Select-Object -Skip ($global:lastLineRead[$driveLetter])

			$lineNumber = ProcessContent -Content $content -StartingLine ($global:lastLineRead[$driveLetter]) -IsRunning $isRunning -resultFile $resultFile -driveLetter $driveLetter
			
			if ($global:VirtualList.Count -ne $global:ResultsCount) {
				$global:ResultsCount = $global:VirtualList.Count 
				$MadeChange = $true 
			}
			
            $global:lastLineRead[$driveLetter] = $lineNumber
        }
        if ((-Not $isRunning)) {
            Remove-Item $resultFile -ErrorAction Ignore
            #Remove-Item ($statsFile) -ErrorAction Ignore
            #Remove-Item ($driveLetter+"done.txt") -ErrorAction Ignore
            Remove-Item ($driveLetter+"robolog.txt") -ErrorAction Ignore
        }
    }
    if ($MadeChange) {
        Update-ItemCountLabel
        $ResultGatherTimer.Interval = 1000
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
    if ($global:SearchSpeed -le 1) {
        $global:SearchStartTime = Get-Date
    }
    if ($global:SearchSpeed -gt 0) {
        if (($global:Config.SearchMethod -eq "RoboSearch") -or ($global:Config.SearchMethod -eq "RoboSearchMT")) {
            $searchCountLabel.Text = "Searching Folders: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker) + "   F/s: " + (Add-ThousandsSeparator -Number $global:SearchSpeed)
        } else {
            $searchCountLabel.Text = "Searching: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker) + "   f/s: " + (Add-ThousandsSeparator -Number $global:SearchSpeed)
        }
    } elseif  (-Not $SearchIsRunning) {
        if ($global:SearchCountTracker -gt 0) {

            if (($global:Config.SearchMethod -eq "RoboSearch") -or ($global:Config.SearchMethod -eq "RoboSearchMT")) {
                $searchCountLabel.Text = "Folders Searched: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker)
            } else {
                $searchCountLabel.Text = "Items Searched: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker)
            }
        } else {
            $searchCountLabel.Text = "Search Complete."
        }
        $ResultGatherTimer.Stop()
    }
    
    
	
    Update-ProcessCountLabel
})

Update-ItemCountLabel

$virtualListView_SelectedIndexChanged = {
    if ($DelayTimer -ne $null) {
        $DelayTimer.Stop()
        $DelayTimer.Dispose()
    }
    
    $DelayTimer = New-Object System.Windows.Forms.Timer
    $DelayTimer.Interval = 10 # 10 milliseconds delay
    $DelayTimer.add_Tick({
        $this.Stop()
        $this.Dispose()

        if ($virtualListView.SelectedIndices.Count -eq 1) {
            $selectedIndex = $virtualListView.SelectedIndices[0]
            $selectedDirectory = $global:VirtualList[$selectedIndex]
            $lastLeaf = Split-Path -Path $selectedDirectory -Leaf
            
            $searchMenuItem.Text = "Search `"" + $lastLeaf + "`""
            EnableControls @(
                $openInExplorerMenuItem,
                $searchMenuItem,
                $renameMenuItem,
                $CopyPath

            )
        } elseif ($virtualListView.SelectedIndices.Count -gt 1) {
            $selectedIndex = $virtualListView.SelectedIndices[0]
            $selectedDirectory = $global:VirtualList[$selectedIndex]
            $lastLeaf = Split-Path -Path $selectedDirectory -Leaf
            
            $searchMenuItem.Text = "Search"
            DisableControls @(
                $openInExplorerMenuItem,
                $searchMenuItem,
                $CopyPath
            )
            EnableControls @(
                $renameMenuItem
            )
        } else {
            DisableControls @(
                $openInExplorerMenuItem,
                $searchMenuItem,
                $renameMenuItem,
                $CopyPath

            )
            $searchMenuItem.Text = "Search"
        }
        Write-Host ($virtualListView.SelectedIndices.Count)
    })
    $DelayTimer.Start()
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

$CopyPath = New-Object System.Windows.Forms.ToolStripMenuItem("Copy path to clipboard")
$CopyPath.Enabled = $false



# Usage



$CopyPath.add_Click({
    $selectedIndex = $virtualListView.SelectedIndices[0]
    $selectedDirectory = $global:VirtualList[$selectedIndex]
    Set-Clipboard -Value $selectedDirectory
})

$renameMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem("Rename")
$renameMenuItem.Enabled = $false

$renameMenuItem.add_Click({
    if ($virtualListView.SelectedIndices.Count -eq 1) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
    
        Add-Type -AssemblyName Microsoft.VisualBasic
        $originalName = Split-Path $selectedDirectory -Leaf
        $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new name for `"$originalName`"`nlocated at `"$selectedDirectory`"", "Rename", $originalName)
    
        if ($newName -and $newName -ne $originalName) {
            $newPath = Join-Path -Path (Split-Path -Parent $selectedDirectory) -ChildPath $newName
            try {
                Rename-Item -Path $selectedDirectory -NewName $newPath -ErrorAction Stop
                Write-Host "Renamed $selectedDirectory to $newPath"
                $global:VirtualList.Remove($selectedDirectory)
                $global:VirtualList.Add($newPath)
                Update-Sort
                
                # Find the new index of the renamed item in the sorted list
                $newIndex = $global:VirtualList.IndexOf($newPath)
                
                # Clear the previous selection and select the renamed item
                $virtualListView.SelectedIndices.Clear()
                $virtualListView.SelectedIndices.Add($newIndex)
            }
            catch {
                [System.Windows.Forms.MessageBox]::Show("Failed to rename ${selectedDirectory}: $_", "Power Search", [System.Windows.Forms.MessageBoxButtons]::OK)
                Write-Host "Failed to rename ${selectedDirectory}: $_"
            }
        }
    }
    
    if ($virtualListView.SelectedIndices.Count -gt 1) {
        $selectedItems = $virtualListView.SelectedIndices | ForEach-Object { $global:VirtualList[$_] }

        $dialog = New-Object System.Windows.Forms.Form
        $dialog.Text = "Rename Multiple Items"
        $dialog.Size = New-Object System.Drawing.Size(600, 400)
        $dialog.StartPosition = 'CenterScreen'
        $dialog.Icon = 'logo5.ico'
        SetColors($dialog)
        $nameLabel = New-Object System.Windows.Forms.Label
        $nameLabel.Text = "New Name:"
        $nameLabel.AutoSize = $true
        $nameLabel.Location = New-Object System.Drawing.Point(10, 10)
        
        $nameTextBox = New-Object System.Windows.Forms.TextBox
        $nameTextBox.Location = New-Object System.Drawing.Point(10, 30)
        $nameTextBox.Size = New-Object System.Drawing.Size(200, 20)
        $nameTextBox.Text = "New"
        $ignoreExtensionsCheckBox = New-Object System.Windows.Forms.CheckBox
        $ignoreExtensionsCheckBox.Text = "Ignore Extensions"
        $ignoreExtensionsCheckBox.Location = New-Object System.Drawing.Point(10, 60)
        $ignoreExtensionsCheckBox.add_CheckedChanged({
            UpdatePreview
        })
        
        $autoIncrementCheckBox = New-Object System.Windows.Forms.CheckBox
        $autoIncrementCheckBox.Text = "Auto Increment"
        $autoIncrementCheckBox.Location = New-Object System.Drawing.Point(10, 90)
        $autoIncrementCheckBox.add_CheckedChanged({
            UpdatePreview
        })
        
        $replaceCheckBox = New-Object System.Windows.Forms.CheckBox
        $replaceCheckBox.Text = "Replace"
        $replaceCheckBox.Location = New-Object System.Drawing.Point(10, 120)
        
        $replaceTextBox = New-Object System.Windows.Forms.TextBox
        $replaceTextBox.Location = New-Object System.Drawing.Point(10, 150)
        $replaceTextBox.Size = New-Object System.Drawing.Size(200, 20)
        $replaceTextBox.Enabled = $false
        $replaceTextBox.Text = "old"
        
        $replaceCheckBox.add_CheckedChanged({
            $replaceTextBox.Enabled = $replaceCheckBox.Checked
            UpdatePreview
        })
        
        $nameTextBox.add_TextChanged({ UpdatePreview })
        $replaceTextBox.add_TextChanged({ UpdatePreview })
        
        $previewButton = New-Object System.Windows.Forms.Button
        $previewButton.Text = "Preview"
        $previewButton.Location = New-Object System.Drawing.Point(10, 180)
        
        $previewTextBox = New-Object System.Windows.Forms.TextBox
        $previewTextBox.Location = New-Object System.Drawing.Point(10, 210)
        $previewTextBox.Size = New-Object System.Drawing.Size(560, 200)
        $previewTextBox.Multiline = $true
        $previewTextBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
        
        $applyButton = New-Object System.Windows.Forms.Button
        $applyButton.Text = "Apply"
        $applyButton.Location = New-Object System.Drawing.Point(380, 180)
        
        Function UpdatePreview {
            $previewTextBox.Clear()
        
            $newName = $nameTextBox.Text
            $ignoreExtensions = $ignoreExtensionsCheckBox.Checked
            $autoIncrement = $autoIncrementCheckBox.Checked
            $replace = $replaceCheckBox.Checked
            $replaceText = $replaceTextBox.Text
        
            $index = 0
            $selectedItems | ForEach-Object {
                $originalName = Split-Path $_ -Leaf
                $extension = if ($ignoreExtensions) { "" } else { [System.IO.Path]::GetExtension($_) }
                $increment = if ($autoIncrement) { " ($index)" } else { "" }
                $newNameReplaced = if ($replace) { $originalName -replace $replaceText, $newName } else { $newName }
        
                $preview = "$_ => $newNameReplaced$increment$extension"
                $previewTextBox.AppendText($preview + [Environment]::NewLine)
        
                $index++
            }
        }
        
        $previewButton.add_Click({
            UpdatePreview
        })
        
        $applyButton.add_Click({
            $newName = $nameTextBox.Text
            $ignoreExtensions = $ignoreExtensionsCheckBox.Checked
            $autoIncrement = $autoIncrementCheckBox.Checked
            $replace = $replaceCheckBox.Checked
            $replaceText = $replaceTextBox.Text
        
            $index = 0
            $selectedItems | ForEach-Object {
                $originalName = Split-Path $_ -Leaf
                $extension = if ($ignoreExtensions) { "" } else { [System.IO.Path]::GetExtension($_) }
                $increment = if ($autoIncrement) { " ($index)" } else { "" }
                $newNameReplaced = if ($replace) { $originalName -replace $replaceText, $newName } else { $newName }
        
                $newPath = Join-Path (Split-Path $_ -Parent) "$newNameReplaced$increment$extension"
        
                try {
                    Rename-Item -Path $_ -NewName $newPath -ErrorAction Stop
                    Write-Host "Renamed $_ to $newPath"
                    $global:VirtualList.Remove($_)
                    $global:VirtualList.Add($newPath)
                    $VirtualListView.Invalidate()
                }
                catch {
                    Write-Host "Failed to rename $_ : $_"
                }
        
                $index++
            }
        })
        
        $dialog.Controls.AddRange(@($nameLabel, $nameTextBox, $ignoreExtensionsCheckBox, $autoIncrementCheckBox, $replaceCheckBox, $replaceTextBox, $previewButton, $previewTextBox, $applyButton))
        UpdatePreview
        $dialog.ShowDialog()
        

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
$contextMenuStrip.Items.Add($renameMenuItem)
$contextMenuStrip.Items.Add($CopyPath)

# Assign the context menu strip to the virtualListView
$virtualListView.ContextMenuStrip = $contextMenuStrip

$virtualListView.add_MouseDoubleClick($virtualListView_MouseDoubleClick)
$form.Add_FormClosing({
	$ResultGatherTimer.Stop()
	$ResultGatherTimer.Dispose()
	Stop-Search
})
$form.Controls.Add($searchBox)
$form.Controls.Add($virtualListView)
$form.Controls.Add($MenuStrip)
$form.Controls.Add($searchButton)
$form.Controls.Add($CaseSensitiveCheckBox)
$form.Controls.Add($ContainesAllCheckBox)
$form.Controls.Add($FilesOnlyCheckBox)
$form.Controls.Add($FoldersOnlyCheckBox)

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
$ResultGatherTimer.Stop()
$ResultGatherTimer.Dispose()
