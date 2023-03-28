Add-Type -AssemblyName System.Windows.Forms
Function MakeToolTip ()
{
	
	$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.InitialDelay = 100
$toolTip.AutoPopDelay = 10000
	
Return $toolTip
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

function Load-Options {
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

function Sort-ListBoxAlphabetically ($directories, $ascending) {
    if ($ascending) {
        return $directories | Sort-Object
    } else {
        return $directories | Sort-Object -Descending
    }
}

function Sort-ListBoxByLastChild ($directories, $ascending) {
    if ($ascending) {
        return $directories | Sort-Object -Property { Split-Path $_ -Leaf }
    } else {
        return $directories | Sort-Object -Property { Split-Path $_ -Leaf } -Descending
    }
}

function Sort-ListBoxByType ($directories, $ascending) {
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

$dropdown.SelectedIndex = 0

$VirtualList = @()
function Update-Sort {
	if ($global:VirtualList.Count -gt 1) {
		switch ($dropdown.SelectedItem) {
			"Drive" {
					$sortedDirectories = Sort-ListBoxAlphabetically $global:VirtualList $AccedingSort
					$virtualListView.VirtualListSize = $sortedDirectories.Count
					$global:VirtualList = @()
					$virtualListView.Invalidate()
					$global:VirtualList = $sortedDirectories
			}
				"Name" {
				$sortedDirectories = Sort-ListBoxByLastChild $global:VirtualList $AccedingSort
					$virtualListView.VirtualListSize = $sortedDirectories.Count
					$global:VirtualList = @()
					$virtualListView.Invalidate()
					$global:VirtualList = $sortedDirectories
			}
			"Type" {
				$sortedDirectories = Sort-ListBoxByType $global:VirtualList $AccedingSort
					$virtualListView.VirtualListSize = $sortedDirectories.Count
					$global:VirtualList = @()
					$virtualListView.Invalidate()
					$global:VirtualList = $sortedDirectories
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
$form.Size = New-Object System.Drawing.Size(400, 400)
$minWidth = 400
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


$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(20, 20)
$searchBox.Size = New-Object System.Drawing.Size(340, 20)
$toolTip.SetToolTip($searchBox,(Get-Content "searchhelp.txt" -Raw))

$textBox_KeyDown = {
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        run-search
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



$form.Controls.Add($searchBox)


$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Text = 'Search'
$searchButton.Location = New-Object System.Drawing.Point(270, 40)
$searchButton.AutoSize = $true
$form.Controls.Add($searchButton)



$searchResultsLabel = New-Object System.Windows.Forms.Label
$searchResultsLabel.Location = New-Object System.Drawing.Point(20, 60)
$searchResultsLabel.AutoSize = $true
$form.Controls.Add($searchResultsLabel)
$searchCountLabel = New-Object System.Windows.Forms.Label
$searchCountLabel.Location = New-Object System.Drawing.Point(20, 42)
$searchCountLabel.AutoSize = $true
$searchCountLabel.Text = "Search Count: 0"
$form.Controls.Add($searchCountLabel)
$processCountlabel = New-Object System.Windows.Forms.Label
$processCountlabel.Location = New-Object System.Drawing.Point(20, 80)
$processCountlabel.AutoSize = $true
$form.Controls.Add($processCountlabel)

$form.Controls.Add($dropdown)
$form.Controls.Add($SBlabel)

function Add-ThousandsSeparator {
    param (
        [int]$Number
    )

    return $Number.ToString("N0", [Globalization.CultureInfo]::InvariantCulture)
}



function Update-ProcessCountLabel {
	$processCount = 0
	$newprocessCountlabelText = "Active Searches:"
	
	foreach ($drive in $drives) {
        $driveLetter = $drive.Root.Substring(0, 1)
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




$virtualListView = New-Object System.Windows.Forms.ListView
$virtualListView.Location = New-Object System.Drawing.Point(20, 100)
$virtualListView.Size = New-Object System.Drawing.Size(330, 150)
$virtualListView.Width = $form.ClientSize.Width - 50
$virtualListView.Height = $form.ClientSize.Height - (50 + $virtualListView.Location.Y)
$virtualListView.View = [System.Windows.Forms.View]::Details
$virtualListView.VirtualMode = $true
$virtualListView.VirtualListSize = 1

$columnHeader = New-Object System.Windows.Forms.ColumnHeader
$columnHeader.Text = "Location"
$columnHeader.Width = 1920

$virtualListView.add_ColumnClick({
    param($sender, $e)

    $clickedColumn = $e.Column
	if ($clickedColumn -eq 0) {
		
		$global:AccedingSort = $AccedingSort -eq $false
		Update-Sort
		$virtualListView.Invalidate()
	}
    
})
$virtualListView.Columns.Add($columnHeader)

$virtualListView_RetrieveVirtualItem = {
    $itemIndex = $_.ItemIndex
    $_.Item = New-Object System.Windows.Forms.ListViewItem($global:VirtualList[$itemIndex])
}

$virtualListView.add_RetrieveVirtualItem($virtualListView_RetrieveVirtualItem)

$form.Controls.Add($virtualListView)






function SetColors($form){
	$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"
	$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
	$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}
}
SetColors($form)


$form.Add_Resize({
	$virtualListView.Width = $form.ClientSize.Width - 50
    $virtualListView.Height = $form.ClientSize.Height - (50 + $virtualListView.Location.Y)
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100


function Stop-Search {
	foreach ($drive in $drives) {
		$driveLetter = $drive.Root.Substring(0, 1)
		$isRunning = IsProcessRunning -driveLetter $driveLetter
		if ($isRunning) {
			$process = $runningProcesses[$driveLetter]
			Stop-Process -Id $process.Id -Force
		}
	}
}


function run-search {

	if ($searchBox.Text.Length -eq 1) {
		$messageBoxResult = [System.Windows.Forms.MessageBox]::Show("The search text is only one character. This can cause the program to freeze for long periods of time.`n`n Are you sure you want to continue?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
		if ($messageBoxResult -eq [System.Windows.Forms.DialogResult]::No) {
			return
		}
	} elseif ($searchBox.Text.Length -lt 2) {
		return
	}


	$global:lastLineRead = @{}
	$timer.Stop()
	$timer.Interval = 100
	$global:ResultsCount = 0
	$searchCountLabel.Text = "Search Count: 0"
	$global:SearchCountTracker = 0
	$searchText = $searchBox.Text
	$global:VirtualList = @()
	$virtualListView.Invalidate()
	Update-ItemCountLabel
    Remove-Item "GUIoutput.txt" -ErrorAction Ignore

    $global:drives = Get-PSDrive -PSProvider FileSystem
    
    foreach ($drive in $global:drives) {
        
    }
	$lua = "SearchAgent.exe" 
	Stop-Search

	foreach ($drive in $drives) {
		$luaScriptPath = "luasearch.lua"
		$arg = "-b"
		Out-File -FilePath "GUIoutput.txt" -InputObject ("$searchText`n"+$drive.Root.ToString()) -Encoding ascii -Append
	
		if (Test-Path -LiteralPath "README.md") {
			$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath, $arg -RedirectStandardError "error.txt" -PassThru
		} else {
			$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath, $arg -RedirectStandardError "error.txt" -PassThru -WindowStyle Hidden
		}
		$driveLetter = $drive.Root.Substring(0, 1)
		 $runningProcesses[$driveLetter] = $process
	
		while (Test-PathWithErrorHandling "GUIoutput.txt") {
			Start-Sleep -Milliseconds 1
		}
	}

    $timer.Start()
}


$runningProcesses = @{}
$drives = Get-PSDrive -PSProvider FileSystem
$searchButton.Add_Click({
    run-search
})
function IsProcessRunning {
	param([string]$driveLetter)

	$process = $runningProcesses[$driveLetter]

	if ($process -ne $null) {
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


$lastLineRead = @{}
$timer.Add_Tick({
    $MadeChange = $false
    $searchCount = 0
    
	
	foreach ($drive in $drives) {
        $driveLetter = $drive.Root.Substring(0, 1)
        $isRunning = IsProcessRunning -driveLetter $driveLetter

        $resultFile = "$driveLetter" + "results.txt"
        $statsFile = "$driveLetter" + "stats.txt"
        if (Test-Path -LiteralPath $statsFile) {
            $SearchStats = Load-Options -Filename $statsFile
            $searchCount += $SearchStats["searchcount"]
        }
        if (Test-Path -LiteralPath $resultFile) {
            $NoError = $true
            if (-not $lastLineRead.ContainsKey($driveLetter)) {
                $lastLineRead[$driveLetter] = 0
            }
            $content = Get-Content $resultFile -ErrorAction Ignore | Select-Object -Skip $lastLineRead[$driveLetter]
            $lineNumber = $lastLineRead[$driveLetter]
            $startTime = Get-Date
            
			$content | ForEach-Object {
				$lineNumber++	
				$global:VirtualList += $_
            }
			if ($global:VirtualList.Count -ne $global:ResultsCount) {
				$global:ResultsCount = $global:VirtualList.Count 
				$MadeChange = $true 
			}
			
            $lastLineRead[$driveLetter] = $lineNumber
            if (-Not $isRunning) {
                Remove-Item $resultFile
            }
        }
    }
    if ($MadeChange) {
        Update-ItemCountLabel
        $timer.Interval = 1000
        Update-Sort
        $virtualListView.Invalidate()
    }
	if ($global:SearchCountTracker -lt $searchCount) {
		$global:SearchCountTracker = $searchCount
	}
    $searchCountLabel.Text = "Search Count: " + (Add-ThousandsSeparator -Number $global:SearchCountTracker)
    Update-ProcessCountLabel
})

Update-ItemCountLabel


$virtualListView_MouseDoubleClick = {
    if ($virtualListView.SelectedIndices.Count -gt 0) {
        $selectedIndex = $virtualListView.SelectedIndices[0]
        $selectedDirectory = $global:VirtualList[$selectedIndex]
		Write-Host $selectedDirectory
        Start-Process "explorer.exe" -ArgumentList "/select,`"$selectedDirectory`""
    }
	
}

$virtualListView.add_MouseDoubleClick($virtualListView_MouseDoubleClick)
$form.Add_FormClosing({
	$timer.Stop()
	$lua = "SearchAgent.exe" 
	Stop-Search
})

$form.ShowDialog()
$timer.Stop()
$timer.Dispose()