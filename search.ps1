Add-Type -AssemblyName System.Windows.Forms
Function MakeToolTip ()
{
	
	$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.InitialDelay = 100
$toolTip.AutoPopDelay = 10000
# Set the text of the tooltip
	
Return $toolTip
}
# Initialize form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Fast Search'
$form.Size = New-Object System.Drawing.Size(400, 300)
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
$form.Controls.Add($helpIcon)
$tooltip = (MakeToolTip)
$toolTip.AutoPopDelay = 90000
$toolTip.InitialDelay = 50
$helpIcon.Add_Click({
	Start-Process -FilePath "notepad.exe" -ArgumentList "lua-pattern-matching.txt"
})
$toolTip.SetToolTip($helpIcon,(Get-Content "lua-pattern-matching.txt" -Raw))
# Initialize textbox
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Location = New-Object System.Drawing.Point(20, 20)
$textbox.Size = New-Object System.Drawing.Size(340, 20)
$form.Controls.Add($textbox)

# Initialize button
$button = New-Object System.Windows.Forms.Button
$button.Text = 'Search'
$button.Location = New-Object System.Drawing.Point(270, 60)
$button.Size = New-Object System.Drawing.Size(100, 23)
$form.Controls.Add($button)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20, 70)
$label.AutoSize = $true
$form.Controls.Add($label)

# Function to update the label with the item count
function Update-ItemCountLabel {
    $label.Text = "Search Results: " + $listbox.Items.Count
}

# Initialize result list box
$listbox = New-Object System.Windows.Forms.ListBox
$listbox.Location = New-Object System.Drawing.Point(20, 100)
$listbox.Size = New-Object System.Drawing.Size(330, 150)
$listbox.Width = $form.ClientSize.Width - 50
$listbox.Height = $form.ClientSize.Height - (50 + $listbox.Location.Y)
#$listbox.AutoSize = $true
$form.Controls.Add($listbox)
$listbox.Add_SelectedIndexChanged({
	
})
function ResizeObject {
    param(
        [System.Windows.Forms.Control]$object,
        [int]$width,
        [int]$height
    )

    if ($object.Width -gt $width) {
        $object.Width = $width
    }

    if ($object.Height -gt $height) {
        $object.Height = $height
    }
}

function SetColors($form){
	$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"
	$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
	$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}
}
SetColors($form)

function Resize-ListBoxWidthBasedOnLongestItem {
    param($listBoxControl)

    $maxWidth = 0
    $graphics = $form.CreateGraphics()

    foreach ($item in $listBoxControl.Items) {
        $stringSize = $graphics.MeasureString($item, $listBoxControl.Font)
        $itemWidth = [int]($stringSize.Width) + 3 # Add a small margin

        if ($itemWidth -gt $maxWidth) {
            $maxWidth = $itemWidth
        }
    }

	if ($maxWidth -gt 800) {
        $maxWidth = 800
    }
    $listBoxControl.Width = $maxWidth
	
	#$maxHeight = 400
	#$listbox.AutoSize = $true
	#$listbox.AutoSize = $false
	#$form.AutoSize = $false
	#ResizeObject -object $listBoxControl -width $maxWidth -height $maxHeight
	#ResizeObject -object $form -width ($maxWidth+10) -height ($maxHeight+10)
}
$form.Add_Resize({
	$listbox.Width = $form.ClientSize.Width - 50
    $listbox.Height = $form.ClientSize.Height - (50 + $listbox.Location.Y)
})
# Initialize timer
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

$resultFile = $PSScriptRoot + '\search_results.txt'

function Search-FilesAndFolders {
    param([string]$searchText, [string]$drive)
    Get-ChildItem -Path $drive -Recurse -ErrorAction SilentlyContinue |
        Where-Object { ($_.Name -like "*$searchText*") } |
        ForEach-Object {
            $itemPath = $_.FullName
            Add-Content -Path ($PSScriptRoot + '\search_results.txt') -Value $itemPath
            
        }
}


function Invoke-LuaSearch {
    param([string]$searchText, [string]$drive)

    
    
    #$output = & $lua $luaScriptPath $searchText $drive
	
}
$runningProcesses = @{} # Create an empty list to store the running processes
$drives = Get-PSDrive -PSProvider FileSystem
$button.Add_Click({
    $timer.Stop()
	$searchText = $textbox.Text
    $listbox.Items.Clear()
	Update-ItemCountLabel
    #$listbox.Size = New-Object System.Drawing.Size(340, 200)
	#$form.Size = New-Object System.Drawing.Size(400, 200)
	Remove-Item $resultFile -ErrorAction Ignore
    Remove-Item "GUIoutput.txt" -ErrorAction Ignore

    $global:drives = Get-PSDrive -PSProvider FileSystem
    
    foreach ($drive in $global:drives) {
        
    }
	$lua = "SearchAgent.exe" 
	taskkill /F /IM $lua
	

	foreach ($drive in $drives) {
		$luaScriptPath = "luasearch.lua"
		$arg = "-b"
		Out-File -FilePath "GUIoutput.txt" -InputObject ("$searchText`n"+$drive.Root.ToString()) -Encoding ascii -Append
	
		if (Test-Path "README.md") {
			$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath, $arg -RedirectStandardError "error.txt" -PassThru
		} else {
			$process = Start-Process -FilePath $lua -ArgumentList $luaScriptPath, $arg -RedirectStandardError "error.txt" -PassThru -WindowStyle Hidden
		}
		$driveLetter = $drive.Root.Substring(0, 1)
		 $runningProcesses[$driveLetter] = $process
	
		while (Test-Path "GUIoutput.txt") {
			Start-Sleep -Milliseconds 10
		}
	}

    $timer.Start()
})
function IsProcessRunning {
    param([string]$driveLetter)

    
    # Find the process associated with the drive letter
	$process = $runningProcesses[$driveLetter]

    if ($process -ne $null) {
        # Check if the process is still running
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

# $drive.Root

$timer.Add_Tick({
    $MadeChange = $false
	foreach ($drive in $drives) {
        $driveLetter = $drive.Root.Substring(0, 1)
		$isRunning = IsProcessRunning -driveLetter $driveLetter

        $resultFile = "$driveLetter" + "results.txt"
		if (Test-Path $resultFile) {
            $NoError = $true
			$content = Get-Content $resultFile -ErrorAction Ignore
            $content | ForEach-Object {
                if (-not $listbox.Items.Contains($_)) {
                    if ( Test-Path $_ ) {
						$listbox.Items.Add($_)
						$MadeChange = $true
					} else {
						$NoError = $false
					}
					
                }
            }
			if ($NoError -and (-Not $isRunning)) {
				Remove-Item $resultFile
			}
			
        }
    }
	if ($MadeChange) {
		#Resize-ListBoxWidthBasedOnLongestItem -listBoxControl $listbox
		Update-ItemCountLabel
		$timer.Interval = 1000+$listbox.Items.Count
	}
	
})
Update-ItemCountLabel

$listbox.Add_MouseDoubleClick({
    if ($listbox.SelectedIndex -ge 0) {
        $selectedPath = $listbox.SelectedItem
       Write-Host $selectedPath
	   explorer.exe "/select,`"$selectedPath`""
    }
})
$form.Add_FormClosing({
	$timer.Stop()
	$lua = "SearchAgent.exe" 
	taskkill /F /IM $lua
})

$form.ShowDialog()
$timer.Stop()