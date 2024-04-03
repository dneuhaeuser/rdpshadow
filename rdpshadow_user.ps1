Add-Type -assembly System.Windows.Forms
Import-Module RunAs

function Show-Console
{
    param ([Switch]$Show,[Switch]$Hide)
    if (-not ("Console.Window" -as [type])) { 

        Add-Type -Name Window -Namespace Console -MemberDefinition '
        [DllImport("Kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
        '
    }

    if ($Show)
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        $null = [Console.Window]::ShowWindow($consolePtr, 5)
    }

    if ($Hide)
    {
        $consolePtr = [Console.Window]::GetConsoleWindow()
        $null = [Console.Window]::ShowWindow($consolePtr, 0)
    }
}

Show-Console -Hide

$gForm = New-Object System.Windows.Forms.Form
$gForm.Text ='Remotesteuerung'
$gForm.Width = 600
$gForm.Height = 250
$gForm.AutoSize = $true
#$gForm.FormBorderStyle = 'FixedDialog'
$gForm.MaximumSize = $gForm.Size
$gForm.MinimumSize = $gForm.Size
$gForm.MaximizeBox = $false
$gForm.MinimizeBox = $false
$gForm.StartPosition = "CenterScreen"
$gForm.KeyPreview = $True
$gForm.TopMost = $true

$objIcon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\mstsc.exe")
$gForm.Icon = $objIcon

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,15)
$objLabel.Size = New-Object System.Drawing.Size(60,30)
$objLabel.Text = "Host / IP:"
$gForm.Controls.Add($objLabel)

$objTextBox = New-Object System.Windows.Forms.TextBox
$objTextBox.Location = New-Object System.Drawing.Size(75,12)
$objTextBox.Size = New-Object System.Drawing.Size(90,30)
$gForm.Controls.Add($objTextBox)

$ConnBttn = New-Object System.Windows.Forms.Button
$ConnBttn.Text = 'Verbinden'
$ConnBttn.Location = New-Object System.Drawing.Point(180,11)
$gForm.Controls.Add($ConnBttn)

$DisCoBttn = New-Object System.Windows.Forms.Button
$DisCoBttn.Text = 'Trennen'
$DisCoBttn.Location = New-Object System.Drawing.Point(280,11)
$DisCoBttn.Enabled = $false
$gForm.Controls.Add($DisCoBttn)

$ShdwBttn = New-Object System.Windows.Forms.Button
$ShdwBttn.Text = 'Steuern'
$ShdwBttn.Location = New-Object System.Drawing.Point(490,11)
$ShdwBttn.Enabled = $false
$gForm.Controls.Add($ShdwBttn)

$dList = New-Object System.Windows.Forms.ListView
$dList.Location = New-Object System.Drawing.Point(0,60)
$dList.Width = $gForm.ClientRectangle.Width
$dList.Height = $gForm.ClientRectangle.Height
$dList.Anchor = "Top, Left, Right, Bottom"
$dList.MultiSelect = $False
$dList.View = 'Details'
$dList.FullRowSelect = 1;
$dList.GridLines = 1
$dList.Scrollable = 1
$gForm.Controls.add($dList)

$Header = "Benutzername", "Sitzungsname", "ID", "Status", "Leerlauf", "Anmeldezeit"

foreach ($column in $Header){
  $dList.Columns.Add($column) | Out-Null
}

$dList.columns[0].width = 100
$dList.columns[1].width = 100
$dList.columns[2].width = 50
$dList.columns[3].width = 80
$dList.columns[4].width = 80
$dList.columns[5].width = 150


$ConnBttn.Add_Click({
  if ($objTextBox.Text -eq "") { return }

  $ConnBttn.Enabled = $false
  
  $Server = $objTextBox.Text
  $global:Credential = Get-Credential

  runas -netonly $global:Credential "powershell" "-WindowStyle Minimized quser /server:$Server | findstr Aktiv >c:\temp\1session.txt"
  
  $Timeout = 4
  $ready = $false
  $timer = [Diagnostics.Stopwatch]::StartNew()
  while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and (-not $ready)) {
    if (Test-Path -Path "c:\temp\1session.txt" -PathType Leaf) {
      if ((Get-Item "c:\temp\1session.txt").length -gt 0kb) {
  	    $ready = $true
      }
    }
    Start-Sleep -Seconds 0.5
    Write-Output "Waiting for remote session info... $($timer.Elapsed.TotalSeconds)"
  }
  $timer.Stop()
  
  if ($ready) {
    $(Get-Content c:\temp\1session.txt) -replace "^[\s>]" , "" -replace "\s\s+" , "," | ConvertFrom-Csv -Header $Header | ForEach-Object {
      $dListItem = New-Object System.Windows.Forms.ListViewItem($_.Benutzername)
      $dListItem.Subitems.Add($_.Sitzungsname) | Out-Null
      $dListItem.Subitems.Add($_.ID) | Out-Null
      $dListItem.Subitems.Add($_.Status) | Out-Null
      $dListItem.Subitems.Add($_.Leerlauf) | Out-Null
      $dListItem.Subitems.Add($_.Anmeldezeit) | Out-Null
      $dList.Items.Add($dListItem) | Out-Null
    }
    $ShdwBttn.Enabled = $true
	$DisCoBttn.Enabled = $true
  }
  else
  {
    [System.Windows.Forms.MessageBox]::Show("Verbindung fehlgeschlagen","Fehler",0,[System.Windows.Forms.MessageBoxIcon]::Error)
	$ConnBttn.Enabled = $true
  }
})


$DisCoBttn.Add_Click({
  $ConnBttn.Enabled = $true
  $DisCoBttn.Enabled = $false
  $ShdwBttn.Enabled = $false
  $gForm.TopMost = $true
  Remove-Item 'c:\temp\1session.txt'
  $dList.Items.Clear()
  $objTextBox.Text=""
  $objTextBox.Focus()
})


$ShdwBttn.Add_Click({
  $SelectedItem = $dList.SelectedItems[0]
  $Server = $objTextBox.Text
  $gForm.TopMost = $false

  if ($SelectedItem -eq $null){
    [System.Windows.Forms.MessageBox]::Show("keine Sitzung ausgewählt","Warnung",0,[System.Windows.Forms.MessageBoxIcon]::Exclamation)
  }else{
    $session_id = $SelectedItem.subitems[2].text
    #[System.Windows.Forms.MessageBox]::Show($session_id)
	runas -netonly $global:Credential "mstsc" "/v:$Server /shadow:$session_id /control"
  }
})


$gForm.Add_KeyDown({
  if ($_.KeyCode -eq "Escape"){
    $gForm.Close()
  }
  if ($_.KeyCode -eq "Enter"){
    $ConnBttn.PerformClick()
  }
})


$gForm.ShowDialog()
Remove-Item 'c:\temp\1session.txt'
