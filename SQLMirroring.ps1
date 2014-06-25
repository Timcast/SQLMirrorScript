#Imports The .NET Assembly To Create Userr Input Boxes
#*****************************************************************************
[Reflection.Assembly]:: LoadWithPartialName("System.Windows.Forms") | Out-Null
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
Set-ExecutionPolicy RemoteSigned -Force
Add-Type -Assembly System.Web


#This Is To Get The Database Names To Be Mirrored
#*****************************************************************************
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
$Databases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
$DBs = $Databases.Databases | Select Name, Size


##Grabbing All The IPs Assigned To This Server
#*****************************************************************************
$ThisIP = IPConfig -All | Select-String IPV4
$TheseIPs = ($ThisIP.Line).Substring(39) -replace "\(Preferred\)","".Trim() | Sort


##Creates Random Password For System User
$Length = 15
$NumberOfNonAlphanumericCharacters = 2
$ServerUserpword = [Web.Security.Membership]::GeneratePassword($Length,$NumberOfNonAlphanumericCharacters)


#Initial Form For IPs And Databases
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
$Form1 = New-Object System.Windows.Forms.Form 
$Form1.Size = New-Object System.Drawing.Size(440,310) 
$Form1.ControlBox = $False
$Form1.Text = "Enter The Following Information For The Mirroring Scripts"
$Form1.StartPosition = "CenterScreen"

$OKButton1 = New-Object System.Windows.Forms.Button
$OKButton1.Location = New-Object System.Drawing.Size(125,247)
$OKButton1.Size = New-Object System.Drawing.Size(80,25)
$OKButton1.Text = "OK"
$OKButton1.Add_Click(
    {
    $IPValidation = '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'    
    $IncompleteField = "Please Review Following Fields: `n"
        If(($InputUserBoxMirrorIP.Text.Trim() -as [Bool]) -eq $False)
            {
            $IncompleteField += "`nMirror Server IP"
            }
        If(($InputUserBoxMirrorIP.Text.Trim() -in $TheseIPs.Trim()) -eq $True)
            {
            $IncompleteField += "`nMirror Server IP - This Is The Principal Server IP"
            }
        If(($InputUserBoxWitnessIP.Text.Trim() -as [Bool]) -eq $False)
            {
            $IncompleteField += "`nWitness Server IP"
            } 
        If(($InputUserBoxWitnessIP.Text.Trim() -in $TheseIPs.Trim()) -eq $True)
            {
            $IncompleteField += "`nWitness Server IP - This Is The Principal Server IP"
            }
        If($InputUserBoxMirrorIP.Text.Trim() -eq $InputUserBoxWitnessIP.Text.Trim())
            {
            $IncompleteField += "`nThe Mirror IP Is The Same As The Witness IP"
            }
        If(($InputUserBoxMirrorIP.Text.Trim() -match $IPValidation) -eq $False)
            {
            $IncompleteField += "`nMirror Server IP Is Invalid"
            }
        If(($InputUserBoxWitnessIP.Text.Trim() -match $IPValidation) -eq $False)
            {
            $IncompleteField += "`nWitness Server IP Is Invalid"
            }      
        If($ObjListBoxDBList.SelectedItems.Count -eq 0)
            {
            $IncompleteField += "`nSelect Database(s)"
            }
    If(($ObjListBoxDBList.SelectedItems.Count -eq 0) -or ((($InputUserBoxMirrorIP.Text) -as [Bool]) -eq $False) -or ((($InputUserBoxWitnessIP.Text) -as [Bool]) -eq $False) -or (($InputUserBoxMirrorIP.Text.Trim() -in $TheseIPs.Trim()) -eq $True) -or (($InputUserBoxWitnessIP.Text.Trim() -in $TheseIPs.Trim()) -eq $True) -or ($InputUserBoxMirrorIP.Text.Trim() -eq $InputUserBoxWitnessIP.Text.Trim()) -or (($InputUserBoxMirrorIP.Text.Trim() -match $IPValidation) -eq $False) -or (($InputUserBoxWitnessIP.Text.Trim() -match $IPValidation) -eq $False))
        {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.MessageBox]::Show(($IncompleteField),"Incomplete Information","OK","Error")
        }
    
    ##Blocking This Off In An If Statement To Allow For Error Correcting
    If(($ObjListBoxDBList.SelectedItems.Count -gt 0) -and ((($InputUserBoxMirrorIP.Text) -as [Bool]) -eq $True) -and ((($InputUserBoxWitnessIP.Text) -as [Bool]) -eq $True) -and (($InputUserBoxMirrorIP.Text.Trim() -in $TheseIPs.Trim()) -eq $False) -and (($InputUserBoxWitnessIP.Text.Trim() -in $TheseIPs.Trim()) -eq $False) -and ($InputUserBoxMirrorIP.Text.Trim() -ne $InputUserBoxWitnessIP.Text.Trim()) -and (($InputUserBoxMirrorIP.Text.Trim() -match $IPValidation) -eq $True) -and (($InputUserBoxWitnessIP.Text.Trim() -match $IPValidation) -eq $True))
        { 
        If($Form2 -ne $Null) ##Hides Second Form For Second Pass Through
            { 
            $Form2.Hide()
            }
        
        $Form1.Hide() ##Hides Initial Form To Allow Script To Come Back To Initial Form To Make Changes


        #Assigns IP Input Values To Variables
        #*****************************************************************************   
        ##Witness And Mirror IP Addresses
        $Global:MirrorIP = $InputUserBoxMirrorIP.Text.Trim()
        $Global:WitnessIP = $InputUserBoxWitnessIP.Text.Trim()
        
        ##This Will Determine What IP To Use According To The Entries Made In The Mirror & Witness IP Input Boxes
        $Global:PrincipalIP =
        If($MirrorIP -like '10.*' -and $WitnessIP -like '10.*') ##If Both Addresses Entered Are On The Private Metwork, This Will Select The 10. Address
            {
            $TheseIPs.Trim() | Select -First 1
            }
        Else
            {
            If((((($MirrorIP.Split('.')[0..2]) -join '.') -eq (($WitnessIP.Split('.')[0..2]) -join '.')) -and $TheseIPs -match (($MirrorIP.Split('.')[0..2]) -join '.')) -eq $True) ##This Select The Public IP Based On The First Three Octects Incase They Are Using Cloud Networks
                {
                $TheseIPs.Trim() -match (($MirrorIP.Split('.')[0..2]) -join '.') | Select -First 1
                }
            Else 
                {
                $TheseIPs.Trim() | Select -Last 1
                }
            }
    


        #Second Form To Display Commands On Mirror And Witness To Allow Remote Access - Had To Place This Inside Of The First Form For Behaviorial Purposes
        #*****************************************************************************
        #*****************************************************************************
        #*****************************************************************************
        $Form2 = New-Object System.Windows.Forms.Form    
        $Form2.Size = New-Object System.Drawing.Size(600,270) 
        $Form2.ControlBox = $False
        $Form2.Text = "Remote Enabling Commands"
        $Form2.StartPosition = "CenterScreen" 

        $OKButton2 = New-Object System.Windows.Forms.Button
        $OKButton2.Location = New-Object System.Drawing.Size(160,210)
        $OKButton2.Size = New-Object System.Drawing.Size(80,25)
        $OKButton2.Text = "OK"
        $OKButton2.Add_Click(
            {
            ##Testing Connection To Verify The Scripts Were Run
            Set-Item WSMAN:\Localhost\Client\TrustedHosts -Value ($MirrorIP + ',' + $WitnessIP) -Force
            $RemotingPassword = ConvertTo-SecureString -AsPlainText -Force -String $ServerUserpword
            $Global:RemotingCred = New-Object -Typename System.Management.Automation.PSCredential -Argumentlist "SQL_MirrorUser",$RemotingPassword

            ##Creating PSSessions
            $Global:MirrorSession = New-PSSession -Computername $MirrorIP -Credential $RemotingCred
            $Global:WitnessSession = New-PSSession -Computername $WitnessIP -Credential $RemotingCred

            ##Variable For Output On Error Message
            $ScriptNotRun = "The Script Was Not Successfully Run On The Following Server(s): `n"
                If((($MirrorSession.Availability) -as [Bool]) -eq $False)
                    {
                    $ScriptNotRun += "`nMirror Server (double check IP)"
                    }
                If((($WitnessSession.Availability) -as [Bool]) -eq $False)
                    {
                    $ScriptNotRun += "`nWitness Server (double check IP)"
                    }

            If((($MirrorSession.Availability) -as [Int]) + (($WitnessSession.Availability) -as [Int]) -lt 2)
                {
                [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                [System.Windows.Forms.MessageBox]::Show(($ScriptNotRun),"Script Was Not Run","OK","Error")
                }
            Else
            {
            $Form2.Close()
            }
            })
        $Form2.Controls.Add($OKButton2)

        $BackButton2 = New-Object System.Windows.Forms.Button
        $BackButton2.Location = New-Object System.Drawing.Size(260,210)
        $BackButton2.Size = New-Object System.Drawing.Size(80,24)
        $BackButton2.Text = "Back"
        $BackButton2.Add_Click(
            {
            $Form1.show()   
            })
        $Form2.Controls.Add($BackButton2)

        $CancelButton2 = New-Object System.Windows.Forms.Button
        $CancelButton2.Location = New-Object System.Drawing.Size(360,210)
        $CancelButton2.Size = New-Object System.Drawing.Size(80,24)
        $CancelButton2.Text = "Quit"
        $CancelButton2.Add_Click(
            {
            Invoke-Command -Session $MirrorSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
            Invoke-Command -Session $WitnessSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
            $Form2.Close()
            [Environment]::Exit(0)   
            })
        $Form2.Controls.Add($CancelButton2)


        ##Populates The Textbox With The Commands To Be Run On The Mirror And Witness Servers (yes there is a space before the net localgroup command - idk why but powershell cuts it off when you paste it so I added a space)
        $Firewalls = '
Enable-PSRemoting -Force
Set-ExecutionPolicy RemoteSigned -Force
Net User SQL_MirrorUser '''+$ServerUserpword+''' /Add /Y /Comment:"Account For SQL Mirroring." /FullName:"SQL Server User" /LogonPasswordChg:No /PasswordChg:No
WMIC Useraccount Where "Name=''SQL_MirrorUser''" Set PasswordExpires=False  
 Net LocalGroup Administrators SQL_MirrorUser /Add
Netsh AdvFirewall Firewall Add Rule Name="SQL_MIRROR_IPs" Dir=In Action=Allow Protocol=TCP LocalPort=Any Profile=Any  Enable=Yes RemoteIP="'+$PrincipalIP+','+$InputUserBoxMirrorIP.Text+','+$InputUserBoxWitnessIP.Text+'";'+'
'

        ##Header Text - Remote commands
        $ObjTextBoxRemote = New-Object System.Windows.Forms.Label
        $ObjTextBoxRemote.Location = New-Object System.Drawing.Size(6,8) 
        $ObjTextBoxRemote.Size = New-Object System.Drawing.Size(580,45) 
        $ObjTextBoxRemote.Text="Copy and Paste These Commands in a PowerShell Window on the Mirror and Witness Server Before Proceeding!"
        $ObjTextBoxRemote.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $Font2 = New-Object System.Drawing.Font("Arial",11, [System.Drawing.FontStyle]::Bold)
        $ObjTextBoxRemote.Font = $Font2
        $Form2.Controls.Add($ObjTextBoxRemote) 

        ##Output Box For The Textbox With The Commands Entered Above
        $OutputBox2 = New-Object System.Windows.Forms.TextBox 
        $OutputBox2.Location = New-Object System.Drawing.Size(10,60) 
        $OutputBox2.Size = New-Object System.Drawing.Size(575,140) 
        $OutputBox2.Text = $Firewalls
        $OutputBox2.MultiLine = $True 
        $Form2.Controls.Add($OutputBox2) 
        #*****************************************************************************
        #*****************************************************************************
        #*****************************************************************************



        #Calls The Form To Display
        #*****************************************************************************
        $Form2.Add_Shown(
            {
            $Form2.Activate();$OutputBox2.Focus()
            })
        [Void] $Form2.ShowDialog()


        ##Closes The Initail Form
        $Form1.Close() 
        }     
    })
$Form1.Controls.Add($OKButton1)

$CancelButton1 = New-Object System.Windows.Forms.Button
$CancelButton1.Location = New-Object System.Drawing.Size(225,247)
$CancelButton1.Size = New-Object System.Drawing.Size(80,24)
$CancelButton1.Text = "Quit"
$CancelButton1.Add_Click(
    {
    $Form1.Close()
    [Environment]::Exit(0)
    })
$Form1.Controls.Add($CancelButton1)


#This Is The Section Of The Text Box For Entering The IP Addresses Of The Servers
#*****************************************************************************
#*****************************************************************************
##Header Text - IP Address Heading
$ObjTextBoxIP = New-Object System.Windows.Forms.Label
$ObjTextBoxIP.Location = New-Object System.Drawing.Size(15,25) 
$ObjTextBoxIP.Size = New-Object System.Drawing.Size(175,20) 
$ObjTextBoxIP.Text="IP Addresses (internal preferred):"
$ObjTextBoxIP.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form1.Controls.Add($ObjTextBoxIP) 

##Input Box For Mirror Server IP
$InputUserBoxMirrorIP = New-Object System.Windows.Forms.TextBox 
$InputUserBoxMirrorIP.Location = New-Object System.Drawing.Size(57,55) 
$InputUserBoxMirrorIP.Size = New-Object System.Drawing.Size(120,30) 
$Form1.Controls.Add($InputUserBoxMirrorIP)

##Input Box For Witness Server IP
$InputUserBoxWitnessIP = New-Object System.Windows.Forms.TextBox 
$InputUserBoxWitnessIP.Location = New-Object System.Drawing.Size(280,55) 
$InputUserBoxWitnessIP.Size = New-Object System.Drawing.Size(120,30) 
$Form1.Controls.Add($InputUserBoxWitnessIP) 

##Text - Mirror IP Input Description
$ObjTextBoxMirrorIPDesc = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorIPDesc.Location = New-Object System.Drawing.Size(22,57) 
$ObjTextBoxMirrorIPDesc.Size = New-Object System.Drawing.Size(120,20) 
$ObjTextBoxMirrorIPDesc.Text="Mirror:"
$Form1.Controls.Add($ObjTextBoxMirrorIPDesc)

##Text - Witness IP Input Description
$ObjTextBoxWitnessIPDesc = New-Object System.Windows.Forms.Label
$ObjTextBoxWitnessIPDesc.Location = New-Object System.Drawing.Size(232,57) 
$ObjTextBoxWitnessIPDesc.Size = New-Object System.Drawing.Size(120,20) 
$ObjTextBoxWitnessIPDesc.Text="Witness:"
$Form1.Controls.Add($ObjTextBoxWitnessIPDesc)  


#This Is The Section That Lists The Databases To Select For Mirroring
#*****************************************************************************
#*****************************************************************************
##Selection For Databases To Mirror
$ObjListBoxDBList = New-Object System.Windows.Forms.ListBox 
$ObjListBoxDBList.Location = New-Object System.Drawing.Size(90,125) 
$ObjListBoxDBList.Size = New-Object System.Drawing.Size(250,20) 
$ObjListBoxDBList.Height = 120
$Form1.Controls.Add($ObjListBoxDBList) 

ForEach($DB in $DBs) 
    {
    If (($DB.Name -ne "master")-and($DB.Name -ne "model")-and($DB.Name -ne "msdb")-and($DB.Name -ne "tempdb"))
        {
        [Void]$ObjListBoxDBList.Items.Add($DB.name)
        }
    $ObjListBoxDBList.SelectionMode = "MultiExtended"
    }

##Text - List Of Databases To Mirror
$ObjTextBoxDBList = New-Object System.Windows.Forms.Label
$ObjTextBoxDBList.Location = New-Object System.Drawing.Size(80,100) 
$ObjTextBoxDBList.Size = New-Object System.Drawing.Size(260,20) 
$ObjTextBoxDBList.Text="Databases To Be Mirrored:"
$ObjTextBoxDBList.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$Form1.Controls.Add($ObjTextBoxDBList) 
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Calls The Form To Display
#*****************************************************************************
$Form1.Add_Shown(
    {
    $Form1.Activate()
    })
[Void] $Form1.ShowDialog()



#Assigns Databases Selected Into Variable
#*****************************************************************************
ForEach ($ObjItemDBList In $ObjListBoxDBList.SelectedItems)
    {
    $X += $ObjItemDBList
    }



#Creates User On Principal Server
#*****************************************************************************
Net User SQL_MirrorUser $ServerUserpword /Add /Y /Comment:"Account For SQL Mirroring." /FullName:"SQL Server User" /LogonPasswordChg:no /PasswordChg:no
WMIC UserAccount Where "Name='SQL_MirrorUser'" Set PasswordExpires=False
Net LocalGroup Administrators SQL_MirrorUser /Add
$FirewallIPs = $PrincipalIP,$InputUserBoxMirrorIP.Text,$InputUserBoxWitnessIP.Text -join ','
Netsh AdvFirewall Firewall Add Rule Name="SQL_MIRROR_IPs" Dir=In Action=Allow Protocol=TCP LocalPort=Any Profile=Any  Enable=Yes RemoteIP="$FirewallIPs"


#Gathering Compatibility Settings - SQL Listening Port, Whether TCP Is Enabled, Administraor Group Access And Default Database Location On Mirror
#*****************************************************************************
##Principal
$PrincipalHostName = Hostname
$PrincipalPort = Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort
$PrincipalTcpEnabled = Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled
$PrincipalSQLAccess = ($Databases.Logins.Name -like '*\Administrators').Length
$Mirrors = $ObjListBox1.SelectedItems
$SelectedDatabaseSize = $DBs | Where {$_.Name -in $Mirrors}
$TotalSizeOfDatabases = ($SelectedDatabaseSize.Size | Measure-Object -Sum).Sum #Size in MB

##Mirror
New-PSSession $MirrorSession
$MirrorHostName = Invoke-Command -Session $MirrorSession -ScriptBlock {Hostname}
$MirrorPort = Invoke-Command -Session $MirrorSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort}
$MirrorTcpEnabled = Invoke-Command -Session $MirrorSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled}
$MirrorSQLAccess = Invoke-Command -Session $MirrorSession -ScriptBlock {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
    $MirrorDatabases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
    ($MirrorDatabases.Logins.Name -like '*\Administrators').Length
    }
$MirrorSQLDefaultLocations = Invoke-Command -Session $MirrorSession -ScriptBlock {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
    $MirrorDatabases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
    $DatabaseDefaults = $MirrorDatabases | Select BackupDirectory, DefaultFile, DefaultLog
    }
$MirrorSQLDefaultLocations = Invoke-Command -Session $MirrorSession -ScriptBlock {$DatabaseDefaults}

##Witness
New-PSSession $WitnessSession
$WitnessPort = Invoke-Command -Session $WitnessSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort}
$WitnessTcpEnabled = Invoke-Command -Session $WitnessSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled}
$WitnessSQLAccess = Invoke-Command -Session $WitnessSession -ScriptBlock {
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
    $Databases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
    ($Databases.Logins.Name -like '*\Administrators').Length
    }



#Third Form For Database File Locations On Mirror Server
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
$Form3 = New-Object System.Windows.Forms.Form 
$Form3.Size = New-Object System.Drawing.Size(575,270)
$Form3.ControlBox = $False 
$Form3.Text = "These Are The Default Locations For The Database Files On The Mirror Server"
$Form3.StartPosition = "CenterScreen"

$OKButton3 = New-Object System.Windows.Forms.Button
$OKButton3.Location = New-Object System.Drawing.Size(193,210)
$OKButton3.Size = New-Object System.Drawing.Size(80,25)
$OKButton3.Text = "OK"
$OKButton3.Add_Click(
    {
    ##Re-Populates Variables And Runs Remote Commands To Check For Disk Space
    $Global:MirrorSQLDefaultLocations.DefaultFile = $InputUserBoxMirrorDatabaseFile.Text
    $Global:MirrorSQLDefaultLocations.DefaultLog = $InputUserBoxMirrorLogFile.Text
    $Global:MirrorSQLDefaultLocations.BackupDirectory = $InputUserBoxMirrorBackupFile.Text
    $MirrorSQLDatabaseLocationSize = Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Get-WmiObject -Class Win32_LogicalDisk -filter "Name='$($MirrorSQLDefaultLocations.DefaultFile.Substring(0,2))'" | Select @{Name = 'FreeSpace'; Expression = {$_.FreeSpace/1MB}}} -Args $MirrorSQLDefaultLocations
    $MirrorSQLDatabaseLocationFreeSpace = $MirrorSQLDatabaseLocationSize.FreeSpace ##Size In MB
    $MirrorSQLBackupLocationSize = Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Get-WmiObject -Class Win32_LogicalDisk -filter "Name='$($MirrorSQLDefaultLocations.BackupDirectory.Substring(0,2))'" | Select @{Name = 'FreeSpace'; Expression = {$_.FreeSpace/1MB}}} -Args $MirrorSQLDefaultLocations
    $MirrorSQLBackupLocationFreeSpace = $MirrorSQLDatabaseLocationSize.FreeSpace ##Size In MB
    
    $LocationValidation = "The Following Path(s) Are Invalid: `n" ##Need A Variable Here To Populate Error Message Box
        If((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.DefaultFile} -Args $MirrorSQLDefaultLocations) -eq $False) 
            {
            $LocationValidation += "`nDefault Location for Database Data Files"
            } 
        If((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.DefaultLog} -Args $MirrorSQLDefaultLocations) -eq $False) 
            {
            $LocationValidation += "`nDefault Location for Database Log Files"
            } 
        If((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.BackupDirectory} -Args $MirrorSQLDefaultLocations) -eq $False) 
            {
            $LocationValidation +=  "`nDefault Location for Database Backup Files"}

    $FreeSpaceValidation = "There Is Not Enough Disk Space In The Following Location(s): `n" ##Need Another Variable Here To Populate Error Message Box
        If($TotalSizeOfDatabases -gt $MirrorSQLDatabaseLocationFreeSpace)
            {
            $FreeSpaceValidation += "`nThe Database Files Are Too Large To Reside On The ",$MirrorSQLDefaultLocations.DefaultFile.Substring(0,3),"`nAvailable Space: ", ("{0:N1}" -f ($MirrorSQLDatabaseLocationFreeSpace/1024)),"GB"," - Total Database Size: ", ("{0:N1}" -f ($TotalSizeOfDatabases/1024)),"GB" -join ''
            }
        If(($MirrorSQLDefaultLocations.DefaultFile.Substring(0,2) -eq $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,2)) -and ($TotalSizeOfDatabases * 1.7) -gt $MirrorSQLDatabaseLocationFreeSpace)
            {
            $FreeSpaceValidation += "`n`nThe Data And Backup Files Are On The Same Directory ",$MirrorSQLDefaultLocations.DefaultFile.Substring(0,3),"`nAvailable Space: ", ("{0:N1}" -f ($MirrorSQLDatabaseLocationFreeSpace/1024)),"GB"," - Est Database and Backup Size: ", ("{0:N1}" -f (($TotalSizeOfDatabases * 1.7)/1024)),"GB" -join ''
            }
        If(($MirrorSQLDefaultLocations.DefaultFile.Substring(0,2) -ne $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,2)) -and ($TotalSizeOfDatabases * .7) -gt $MirrorSQLBackupLocationFreeSpace)
            {
            $FreeSpaceValidation += "`n`nThe Backup Files May Be Too Large For The Location Specified ",$MirrorSQLDefaultLocations.BackupDirectory.Substring(0,3),"`nAvailable Space: ", ("{0:N1}" -f ($MirrorSQLBackupLocationFreeSpace/1024)),"GB"," - Est Backup Size: ", ("{0:N1}" -f (($TotalSizeOfDatabases * .7)/1024)),"GB" -join ''
            }

    If ((((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.DefaultFile} -Args $MirrorSQLDefaultLocations) -as [Int]) + ((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.DefaultLog} -Args $MirrorSQLDefaultLocations) -as [Int]) + ((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSQLDefaultLocations) Test-Path $MirrorSQLDefaultLocations.BackupDirectory} -Args $MirrorSQLDefaultLocations) -as [Int])) -lt 3)
        {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.MessageBox]::Show(($LocationValidation),"Invalid Path","OK","Error")
        }
    ElseIf (($TotalSizeOfDatabases -gt $MirrorSQLDatabaseLocationFreeSpace) -or (($MirrorSQLDefaultLocations.DefaultFile.Substring(0,2) -eq $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,2)) -and ($TotalSizeOfDatabases * 1.7) -gt $MirrorSQLDatabaseLocationFreeSpace) -or (($MirrorSQLDefaultLocations.DefaultFile.Substring(0,2) -ne $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,2)) -and ($TotalSizeOfDatabases * .7) -gt $MirrorSQLBackupLocationFreeSpace))
        {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.MessageBox]::Show(($FreeSpaceValidation),"Insufficient Space","OK","Error")
        }
    Else
        {
        $Form3.Close()
        }
    })

$Form3.Controls.Add($OKButton3)
$CancelButton3 = New-Object System.Windows.Forms.Button
$CancelButton3.Location = New-Object System.Drawing.Size(293,210)
$CancelButton3.Size = New-Object System.Drawing.Size(80,24)
$CancelButton3.Text = "Quit"
$CancelButton3.Add_Click(
    {
    Net User SQL_MirrorUser /Delete
    Invoke-Command -Session $MirrorSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
    Invoke-Command -Session $WitnessSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
    $Form3.Close()
    [Environment]::Exit(0)
    })
$Form3.Controls.Add($CancelButton3)


#This Section Is For The Input Boxes For Default File Locations For SQL On Mirror Server
#*****************************************************************************
#*****************************************************************************
##Header Text - SQL File Locations On Mirror
$ObjTextBoxMirrorSQLFiles = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorSQLFiles.Location = New-Object System.Drawing.Size(22,25) 
$ObjTextBoxMirrorSQLFiles.Size = New-Object System.Drawing.Size(368,20) 
$ObjTextBoxMirrorSQLFiles.Text="Default File Locations For SQL Server On Mirror Server:"
$Form3.Controls.Add($ObjTextBoxMirrorSQLFiles) 

##Input Box For Default Database File Location
$InputUserBoxMirrorDatabaseFile = New-Object System.Windows.Forms.TextBox 
$InputUserBoxMirrorDatabaseFile.Location = New-Object System.Drawing.Size(92,55) 
$InputUserBoxMirrorDatabaseFile.Size = New-Object System.Drawing.Size(450,30) 
$InputUserBoxMirrorDatabaseFile.Text = $MirrorSQLDefaultLocations.DefaultFile
$Form3.Controls.Add($InputUserBoxMirrorDatabaseFile) 

##Input Box For Default Log File Location
$InputUserBoxMirrorLogFile = New-Object System.Windows.Forms.TextBox 
$InputUserBoxMirrorLogFile.Location = New-Object System.Drawing.Size(92,85) 
$InputUserBoxMirrorLogFile.Size = New-Object System.Drawing.Size(450,30)
$InputUserBoxMirrorLogFile.Text = $MirrorSQLDefaultLocations.DefaultLog
$Form3.Controls.Add($InputUserBoxMirrorLogFile)

##Input Box For Default Backup File Location
$InputUserBoxMirrorBackupFile = New-Object System.Windows.Forms.TextBox 
$InputUserBoxMirrorBackupFile.Location = New-Object System.Drawing.Size(92,115) 
$InputUserBoxMirrorBackupFile.Size = New-Object System.Drawing.Size(450,30) 
$InputUserBoxMirrorBackupFile.Text = $MirrorSQLDefaultLocations.BackupDirectory
$Form3.Controls.Add($InputUserBoxMirrorBackupFile) 

##Text - Default Database File Location Input Description
$ObjTextBoxMirrorDatabaseFileDesc = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorDatabaseFileDesc.Location = New-Object System.Drawing.Size(22,57) 
$ObjTextBoxMirrorDatabaseFileDesc.Size = New-Object System.Drawing.Size(120,20) 
$ObjTextBoxMirrorDatabaseFileDesc.Text="Data Files:"
$Form3.Controls.Add($ObjTextBoxMirrorDatabaseFileDesc) 

##Text - Default Log File Location Input Description
$ObjTextBoxMirrorLogFileDesc = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorLogFileDesc.Location = New-Object System.Drawing.Size(22,87) 
$ObjTextBoxMirrorLogFileDesc.Size = New-Object System.Drawing.Size(120,20) 
$ObjTextBoxMirrorLogFileDesc.Text="Log Files:"
$Form3.Controls.Add($ObjTextBoxMirrorLogFileDesc)

##Text - Default Backup File Location Input Description
$ObjTextBoxMirrorBackupFileDesc = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorBackupFileDesc.Location = New-Object System.Drawing.Size(22,117) 
$ObjTextBoxMirrorBackupFileDesc.Size = New-Object System.Drawing.Size(120,20) 
$ObjTextBoxMirrorBackupFileDesc.Text="Backup Files:"
$Form3.Controls.Add($ObjTextBoxMirrorBackupFileDesc)  

##Text - Informational Blurb Regarding Changing These Values Manually
$ObjTextBoxMirrorLocationUpdateInfo = New-Object System.Windows.Forms.Label
$ObjTextBoxMirrorLocationUpdateInfo.Location = New-Object System.Drawing.Size(27,162) 
$ObjTextBoxMirrorLocationUpdateInfo.Size = New-Object System.Drawing.Size(540,40) 
$ObjTextBoxMirrorLocationUpdateInfo.Text="***Please Note Changing These Values Will Only Affect The Location Of These Databases Being Restored For Mirroring; It Will Not Change The Default Location Properties For SQL Server"
$Font3 = New-Object System.Drawing.Font("Arial",7.5)
$ObjTextBoxMirrorLocationUpdateInfo.Font = $Font3
$Form3.Controls.Add($ObjTextBoxMirrorLocationUpdateInfo)  
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Calls The Form To Display
#*****************************************************************************
$Form3.Add_Shown(
    {
    $Form3.Activate()
    })
[Void] $Form3.ShowDialog()


#Formatting Database Default Entries
#*****************************************************************************
##Default File
$MirrorSQLDefaultLocations.DefaultFile = 
    If (($MirrorSQLDefaultLocations.DefaultFile.Substring(($MirrorSQLDefaultLocations.DefaultFile.Length) - 1) -ne "\"))
        {
        $MirrorSQLDefaultLocations.DefaultFile + "\"
        }
    Else
        {
        $MirrorSQLDefaultLocations.DefaultFile
        }
##Log File
$MirrorSQLDefaultLocations.DefaultLog = 
    If (($MirrorSQLDefaultLocations.DefaultLog.Substring(($MirrorSQLDefaultLocations.DefaultLog.Length) - 1) -ne "\"))
        {
        $MirrorSQLDefaultLocations.DefaultLog + "\"
        }
    Else
        {
        $MirrorSQLDefaultLocations.DefaultLog
        }
##Backup File
$MirrorSQLDefaultLocations.BackupDirectory = 
    If (($MirrorSQLDefaultLocations.BackupDirectory.Substring(($MirrorSQLDefaultLocations.BackupDirectory.Length) - 1) -ne "\"))
        {
        $MirrorSQLDefaultLocations.BackupDirectory + "\"
        }
    Else
        {
        $MirrorSQLDefaultLocations.BackupDirectory
        }



#This Is for the Error Box That Will Display for All Other Compatiblity Concerns
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
$Form4 = New-Object System.Windows.Forms.Form 
$Form4.Text = "There Is An Error With One Or More Properties"
$Form4.Size = New-Object System.Drawing.Size(375,300) 
$Form4.ControlBox = $False 
$Form4.StartPosition = "CenterScreen"

$OKButton4 = New-Object System.Windows.Forms.Button
$OKButton4.Location = New-Object System.Drawing.Size(108,240)
$OKButton4.Size = New-Object System.Drawing.Size(80,25)
$OKButton4.Text = "OK"
$OKButton4.Add_Click(
    {
    ##Re-Runs These Variables to Make Sure The Necessary Changes Were Made
    ##Principal
    $PrincipalPort = Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort
    $PrincipalTcpEnabled = Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled
    $PrincipalSQLAccess = ($Databases.Logins.Name -like '*\Administrators').Length
    ##Mirror
    $MirrorPort = Invoke-Command -Session $MirrorSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort}
    $MirrorTcpEnabled = Invoke-Command -Session $MirrorSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled}
    $MirrorSQLAccess = Invoke-Command -Session $MirrorSession -ScriptBlock {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
        $MirrorDatabases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
        ($MirrorDatabases.Logins.Name -like '*\Administrators').Length
        }
    ##Witness
    $WitnessPort = Invoke-Command -Session $WitnessSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib\Tcp' | Where PSChildName -eq 'IPAll'  | Get-ItemProperty | Select-Object -ExpandProperty TcpPort}
    $WitnessTcpEnabled = Invoke-Command -Session $WitnessSession -ScriptBlock {Get-ChildItem  'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\SuperSocketNetLib' | Where PSChildName -eq 'Tcp'  | Get-ItemProperty | Select-Object -ExpandProperty Enabled}
    $WitnessSQLAccess = Invoke-Command -Session $WitnessSession -ScriptBlock {
        [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | Out-Null
        $Databases = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "Localhost"
        ($Databases.Logins.Name -like '*\Administrators').Length
        }

    ##Need A Variable Here To Populate Error Message Box
    $ErrorOutput = "You Must Correct ALL Errors to Proceed. These Issues Still Need To Be Resolved:`n" 
        If (($PrincipalPort -eq $MirrorPort -and $PrincipalPort -eq $WitnessPort) -eq $False)
            {
            $ErrorOutput += "`nListening Port"
            }
        If (($PrincipalTcpEnabled -eq 1 -and $MirrorTcpEnabled -eq 1 -and $WitnessTcpEnabled -eq 1) -eq $False)
            {
            $ErrorOutput += "`nTCP Enabled"
            }
        If (($PrincipalSQLAccess + $MirrorSQLAccess +$WitnessSQLAccess -gt 2) -eq $False)
            {
            $ErrorOutput += "`nAdministrators Group Access"
            }

    ##Checks To See If Changes Were Made; If Not, Message Box Will Be Triggered; Else, The Window Will Close And Script Will Continue
    If ((($PrincipalPort -eq $MirrorPort -and $PrincipalPort -eq $WitnessPort) -and ($PrincipalTcpEnabled -eq 1 -and $MirrorTcpEnabled -eq 1 -and $WitnessTcpEnabled -eq 1) -and ($PrincipalSQLAccess + $MirrorSQLAccess +$WitnessSQLAccess -gt 2)) -eq $False)
        {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        [System.Windows.Forms.MessageBox]::Show($ErrorOutput,"Errors Still Not Resolved","OK","Error")
        }
    Else
        {
        $Form4.Close()
        }
    })

$Form4.Controls.Add($OKButton4)
$CancelButton4 = New-Object System.Windows.Forms.Button
$CancelButton4.Location = New-Object System.Drawing.Size(208,240)
$CancelButton4.Size = New-Object System.Drawing.Size(80,24)
$CancelButton4.Text = "Quit"
$CancelButton4.Add_Click(
    {
    #Will Quit The Script And Revert Server
    Net User SQL_MirrorUser /Delete
    Invoke-Command -Session $MirrorSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
    Invoke-Command -Session $WitnessSession -ScriptBlock {Net User SQL_MirrorUser /Delete}
    $Form4.Close()
    [Environment]::Exit(0)
    })
$Form4.Controls.Add($CancelButton4)


##Text Box To Display SQL Server Properties
#*****************************************************************************
#*****************************************************************************
$ObjTextBoxSQLProperties = New-Object System.Windows.Forms.Label
$ObjTextBoxSQLProperties.Location = New-Object System.Drawing.Size(22,32) 
$ObjTextBoxSQLProperties.Size = New-Object System.Drawing.Size(520,240) 
$ObjTextBoxSQLProperties.Text = 
"SQL Server Properties On Each Server


Principal Server Listening Port:  " + $PrincipalPort + "
Mirror Server Listening Port:     " + $MirrorPort + "
Witness Server Listening Port:    " + $WitnessPort + "


TCP Enabled - Principal: " + ($PrincipalTcpEnabled -as [Bool]) + "
TCP Enabled - Mirror:    " + ($MirrorTcpEnabled -as [Bool]) + "
TCP Enabled - Witness:   " + ($WitnessTcpEnabled -as [Bool]) + "


Admin Access for SQL - Principal: " + ($PrincipalSQLAccess -as [Bool]) + "
Admin Access for SQL - Mirror:    " + ($MirrorSQLAccess -as [Bool]) + "
Admin Access for SQL - Witness:   " + ($WitnessSQLAccess -as [Bool]) 
$Font4 = New-Object System.Drawing.Font("Lucida Console", 8.5)
$ObjTextBoxSQLProperties.Font = $Font4
$Form4.Controls.Add($ObjTextBoxSQLProperties) 
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Will Only Call This Form If The SQL Properties Do Not Match
If ((($PrincipalPort -eq $MirrorPort -and $PrincipalPort -eq $WitnessPort) -and ($PrincipalTcpEnabled -eq 1 -and $MirrorTcpEnabled -eq 1 -and $WitnessTcpEnabled -eq 1) -and ($PrincipalSQLAccess + $MirrorSQLAccess +$WitnessSQLAccess -gt 2)) -eq $False)
    {
    #Calls The Form To Display
    #*****************************************************************************
    $Form4.Add_Shown(
        {
        $Form4.Activate()
        })
    [Void] $Form4.ShowDialog()
    }



#Updating Host Files On Servers
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Principal Server
$HostEntries = "

",$PrincipalIP,"    PrincipalServer
",$MirrorIP,"    MirrorServer
",$WitnessIP,"    WitnessServer" -join ''
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value $HostEntries

##Mirror Server
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($HostEntries) Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value $HostEntries} -Args $HostEntries 

##Witness Server
$HostEntries += "
",$PrincipalIP,"    ",$PrincipalHostName,"
",$MirrorIP,"    ",$MirrorHostName -join ''##Yes This Is Necessary; It Took Me Three Weeks To Figure This Out
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($HostEntries)  Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value $HostEntries} -Args $HostEntries
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Scripts For SQL Mirroring
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Various Variables
$File = 'C:\rs-pkgs\SQLMirrorScripts\Scripts'
$File2 = 'C:\rs-pkgs\SQLMirrorScripts\Certificates'
$Date = Get-Date
$Length = 18
$NumberOfNonAlphanumericCharacters = 3
$SQLUserpword = [Web.Security.Membership]::GeneratePassword($Length,$NumberOfNonAlphanumericCharacters)
$SQLCertpword = [Web.Security.Membership]::GeneratePassword($Length,$NumberOfNonAlphanumericCharacters)

##Creating Directory For Scripts And Certs
New-Item -ItemType Directory -Path $File
New-Item -ItemType Directory -Path $File2


#Certificate Scripts
#*****************************************************************************
#*****************************************************************************
##Principal Certificate Script
$SQLPrincipalCert = 
'USE MASTER
;
 
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = ''##MS_DatabaseMasterKey##'')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+$SQLCertpword+'''
;

IF NOT EXISTS (select 1 from sys.databases where [is_master_key_encrypted_by_server] = 1)
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''PrincipalServerCert'')
CREATE  CERTIFICATE PrincipalServerCert
WITH SUBJECT = ''Principal Server Certificate''
,START_DATE =''' + $Date.AddDays(-1).ToShortDateString() + ''''+
',EXPIRY_DATE =''' + $Date.AddYears(20).ToShortDateString() + '''

BACKUP CERTIFICATE PrincipalServerCert TO FILE = '''+ $File2 + '\PrincipalServerCert.crt''' > ($File + '\PrincipalServerCertScript.sql')

##Mirror Certificate Script
$SQLMirrorCert =
'USE MASTER
;
 
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = ''##MS_DatabaseMasterKey##'')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+$SQLCertpword+'''
;

IF NOT EXISTS (select 1 from sys.databases where [is_master_key_encrypted_by_server] = 1)
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''MirrorServerCert'')
CREATE  CERTIFICATE MirrorServerCert
WITH SUBJECT = ''Mirror Server Certificate''
,START_DATE =''' + $Date.AddDays(-1).ToShortDateString() + ''''+
',EXPIRY_DATE =''' + $Date.AddYears(20).ToShortDateString() + '''

BACKUP CERTIFICATE MirrorServerCert TO FILE = '''+ $File2 + '\MirrorServerCert.crt''' > ($File + '\MirrorServerCertScript.sql')

##Witness Certificate Creation Script
$SQLWitnessCert =
'USE MASTER
;
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = ''##MS_DatabaseMasterKey##'')
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+$SQLCertpword+'''
;

IF NOT EXISTS (select 1 from sys.databases where [is_master_key_encrypted_by_server] = 1)
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY
;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = ''WitnessServerCert'')
CREATE  CERTIFICATE WitnessServerCert
WITH SUBJECT = ''Witness Server Certificate''
,START_DATE =''' + $Date.AddDays(-1).ToShortDateString() + ''''+
',EXPIRY_DATE =''' + $Date.AddYears(20).ToShortDateString() + '''

BACKUP CERTIFICATE WitnessServerCert TO FILE = '''+ $File2 + '\WitnessServerCert.crt''' > ($File + '\WitnessServerCertScript.sql')


#Scripts For End-Points
#*****************************************************************************
#*****************************************************************************
##Principal End-Point Script
$SQLPrincipalEndPoint = 
'USE Master
;
--Check If Mirroring Endpoint Exists
IF NOT EXISTS(SELECT * FROM sys.endpoints WHERE type = 4)
CREATE ENDPOINT DBMirrorEndPoint 
STATE = STARTED AS TCP (LISTENER_PORT = 4040)
FOR DATABASE_MIRRORING ( AUTHENTICATION = CERTIFICATE PrincipalServerCert, ENCRYPTION = REQUIRED, ROLE = ALL )' > ($File + '\PrincipalServerEndPointScript.sql')

##Mirror End-Point Script
$SQLMirrorEndPoint =
'USE Master
;
--Check If Mirroring Endpoint Exists
IF NOT EXISTS(SELECT * FROM sys.endpoints WHERE type = 4)
CREATE ENDPOINT DBMirrorEndPoint
STATE=STARTED AS TCP (LISTENER_PORT = 4041)
FOR DATABASE_MIRRORING ( AUTHENTICATION = CERTIFICATE MirrorServerCert, ENCRYPTION = REQUIRED, ROLE = ALL )' > ($File + '\MirrorServerEndPointScript.sql')

##Witness End-Point Script
$SQLWitnessEndPoint =
'USE Master
;
--Check If Mirroring Endpoint Exists
IF NOT EXISTS(SELECT * FROM sys.endpoints WHERE type = 4)
CREATE ENDPOINT DBMirrorEndPoint
STATE=STARTED AS TCP (LISTENER_PORT = 4042)
FOR DATABASE_MIRRORING ( AUTHENTICATION = CERTIFICATE WitnessServerCert, ENCRYPTION = REQUIRED, ROLE = WITNESS )' > ($File + '\WitnessServerEndPointScript.sql')


#Scripts For Login And Grants
#*****************************************************************************
#*****************************************************************************
##Principal Login And Grant Script
$SQLPrincipalLoginGrant =
'USE MASTER
;
--For Mirror Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''MirrorServerUser'')
CREATE LOGIN MirrorServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''MirrorServerUser'')
CREATE USER MirrorServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''MirrorDBCertPub'')
CREATE CERTIFICATE MirrorDBCertPub  AUTHORIZATION MirrorServerUser
FROM FILE = ''' + $File2 + '\MirrorServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO MirrorServerUser
;
 
--For Witness Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''WitnessServerUser'')
CREATE LOGIN WitnessServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''WitnessServerUser'')
CREATE USER WitnessServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''WitnessDBCertPub'')
CREATE CERTIFICATE WitnessDBCertPub  AUTHORIZATION WitnessServerUser
FROM FILE = ''' + $File2 + '\WitnessServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO WitnessServerUser
;' > ($File + '\PrincipalServerLoginGrantScript.sql')

##Mirror Login And Grant Script
$SQLMirrorLoginGrant =
'USE MASTER
;
--For Principal Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''PrincipalServerUser'')
CREATE LOGIN PrincipalServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''PrincipalServerUser'')
CREATE USER PrincipalServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''PrincipalDBCertPub'')
CREATE CERTIFICATE PrincipalDBCertPub  AUTHORIZATION PrincipalServerUser
FROM FILE = ''' + $File2 + '\PrincipalServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO PrincipalServerUser
;
 
--For Witness Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''WitnessServerUser'')
CREATE LOGIN WitnessServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''WitnessServerUser'')
CREATE USER WitnessServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''WitnessDBCertPub'')
CREATE CERTIFICATE WitnessDBCertPub  AUTHORIZATION WitnessServerUser
FROM FILE = ''' + $File2 + '\WitnessServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO WitnessServerUser
;' > ($File + '\MirrorServerLoginGrantScript.sql')

#Witness Login And Grant Script
$SQLWitnessLoginGrant =
'USE MASTER
GO
--For Principal Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''PrincipalServerUser'')
CREATE LOGIN PrincipalServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''PrincipalServerUser'')
CREATE USER PrincipalServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''PrincipalDBCertPub'')
CREATE CERTIFICATE PrincipalDBCertPub  AUTHORIZATION PrincipalServerUser
FROM FILE = ''' + $File2 + '\PrincipalServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO PrincipalServerUser
GO
 
--For Mirror Server To Connect
IF NOT EXISTS(SELECT 1 FROM sys.syslogins WHERE name = ''MirrorServerUser'')
CREATE LOGIN MirrorServerUser WITH PASSWORD = ''' + $SQLUserpword + '''
IF NOT EXISTS(SELECT 1 FROM sys.sysusers WHERE name = ''MirrorServerUser'')
CREATE USER MirrorServerUser;
IF NOT EXISTS(SELECT 1 FROM sys.certificates WHERE name = ''MirrorDBCertPub'')
CREATE CERTIFICATE MirrorDBCertPub  AUTHORIZATION MirrorServerUser
FROM FILE = ''' + $File2 + '\MirrorServerCert.crt''
GRANT CONNECT ON ENDPOINT::DBMirrorEndPoint TO MirrorServerUser
GO' > ($File + '\WitnessServerLoginGrantScript.sql')
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Concatinating SQL Scipts To Run Invoke Commands
#*****************************************************************************
##Certificate Scripts
$PrincipalCertScript = $File + "\PrincipalServerCertScript.sql"
$MirrorCertScript = $File + "\MirrorServerCertScript.sql"
$WitnessCertScript = $File + "\WitnessServerCertScript.sql"

##End-Point Scripts
$PrincipalEndPointScript = $File + "\PrincipalServerEndPointScript.sql"
$MirrorEndPointScript = $File + "\MirrorServerEndPointScript.sql"
$WitnessEndPointScript = $File + "\WitnessServerEndPointScript.sql"

##Login And Grant Scripts
$PrincipalLoginGrantScript = $File + "\PrincipalServerLoginGrantScript.sql"
$MirrorLoginGrantScript = $File + "\MirrorServerLoginGrantScript.sql"
$WitnessLoginGrantScript = $File + "\WitnessServerLoginGrantScript.sql"



#Create Certificates And Move Copy To Each Server
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Running SQL Certificate Script For Principal Server
Import-Module SQLPS  
Invoke-Sqlcmd -InputFile $PrincipalCertScript
Set-Location C:\

##Running SQL Certificate Script For Mirror Server
New-PSSession $MirrorSession
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($File) New-Item -ItemType Directory -Path $File} -Args $File
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($File2) New-Item -ItemType Directory -Path $File2} -Args $File2
Net Use M: \\MirrorServer\c$ /User:SQL_MirrorUser $ServerUserpword ##Had To Add This Because There Is A Bug With BitsTrasfer That Ignores The Credentials And Copy-Item Does Not Support Credentials - https://connect.microsoft.com/PowerShell/feedback/details/837010/start-bitstransfer-ignores-credential-parameter
Start-BitsTransfer -Source ($File + '\MirrorServerCertScript.sql') -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Invoke-Command -Session $MirrorSession -ScriptBlock {Import-Module SQLPS}
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorCertScript) Invoke-Sqlcmd -InputFile $MirrorCertScript} -Args $MirrorCertScript

#Running SQL Certificate Script For Witness Server
New-PSSession $WitnessSession
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($File) New-Item -ItemType Directory -Path $File} -Args $File
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($File2) New-Item -ItemType Directory -Path $File2} -Args $File2
Net Use W: \\WitnessServer\C$ /User:SQL_MirrorUser $ServerUserpword ##Had To Add This Because There Is A Bug With BitsTrasfer That Ignores The Credentials And Copy-Item Does Not Support Credentials - https://connect.microsoft.com/PowerShell/feedback/details/837010/start-bitstransfer-ignores-credential-parameter
Start-BitsTransfer -Source ($File + '\WitnessServerCertScript.sql') -Destination ('\\WitnessServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Invoke-Command -Session $WitnessSession -ScriptBlock {Import-Module SQLPS}
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($WitnessCertScript) Invoke-Sqlcmd -InputFile $WitnessCertScript} -Args $WitnessCertScript

##Copies All Certificates To Each Server
Start-BitsTransfer -Source ($File2 + '\PrincipalServerCert.crt') -Destination ('\\MirrorServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ($File2 + '\PrincipalServerCert.crt') -Destination ('\\WitnessServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ('\\MirrorServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2) + '\MirrorServerCert.crt') -Destination $File2 -Credential $RemotingCred
Start-BitsTransfer -Source ('\\MirrorServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2) + '\MirrorServerCert.crt') -Destination ('\\WitnessServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ('\\WitnessServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2) + '\WitnessServerCert.crt') -Destination $File2 -Credential $RemotingCred
Start-BitsTransfer -Source ('\\WitnessServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2) + '\WitnessServerCert.crt') -Destination ('\\MirrorServer\' + $File2.Substring(0,1) + '$' + $File2.Substring(2)) -Credential $RemotingCred
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Create End-Points, Logins and Grants (oh my) On Each Server
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Tranferring Scripts To Remote Servers
Start-BitsTransfer -Source ($File + '\MirrorServerEndPointScript.sql') -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ($File + '\WitnessServerEndPointScript.sql') -Destination ('\\WitnessServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
##Running SQL End-Point Scripts
Invoke-Sqlcmd -InputFile $PrincipalEndPointScript
Set-Location C:\
New-PSSession $MirrorSession
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorEndPointScript) Invoke-Sqlcmd -InputFile $MirrorEndPointScript} -Args $MirrorEndPointScript
New-PSSession $WitnessSession
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($WitnessEndPointScript) Invoke-Sqlcmd -InputFile $WitnessEndPointScript} -Args $WitnessEndPointScript

##Tranferring Scripts To Remote Servers
Start-BitsTransfer -Source ($File + '\MirrorServerLoginGrantScript.sql') -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ($File + '\WitnessServerLoginGrantScript.sql') -Destination ('\\WitnessServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Invoke-Sqlcmd -InputFile $PrincipalLoginGrantScript
Set-Location C:\
New-PSSession $MirrorSession
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorLoginGrantScript) Invoke-Sqlcmd -InputFile $MirrorLoginGrantScript} -Args $MirrorLoginGrantScript
New-PSSession $WitnessSession
Invoke-Command -Session $WitnessSession -ScriptBlock {Param($WitnessLoginGrantScript) Invoke-Sqlcmd -InputFile $WitnessLoginGrantScript} -Args $WitnessLoginGrantScript
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Commands For Creating The Backup And Restore Scripts
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Creating List Of Databases Selected From Input Form
$FileIndex = ('C:\rs-pkgs\SQLMirrorScripts\Scripts').LastIndexOf('\')
######$File.Substring(0,$FileIndex) #Getting Index To Parse File Name
$Mirrors = $ObjListBoxDBList.SelectedItems
ForEach ($SelectedDatabase In $Mirrors | Out-File ($File.Substring(0,$FileIndex) + "\Databases.txt"))
    {
    Write-Host $SelectedDatabase
    } 


##Creates Recovery Model Script
$RecoveryMode = 
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'USE master ; 
ALTER DATABASE ' + $_ + ' SET RECOVERY FULL ; '
    } > ($File + '\RecoveryMode.sql')

##Creates Database Backup Script - Saves To SQL Backup Directory (from input form) On Mirror Server
$Backups = 
'--Had To Create A Shared Drive In SQL In Order To Save Backup Files To A Remote Machine
EXEC sp_configure ''show advanced options'', 1
RECONFIGURE
EXEC sp_configure ''xp_cmdshell'', 1
RECONFIGURE

EXEC XP_CMDSHELL ''net use S: "\\MirrorServer\' + $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,1) + '" /User:SQL_MirrorUser "' + $ServerUserpword + '"'', NO_OUTPUT
EXEC XP_CMDSHELL ''net use S: "\\MirrorServer\' + $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,1) + '$' + '" /User:SQL_MirrorUser "' + $ServerUserpword + '"'', NO_OUTPUT


'
$Backups += 
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'BACKUP DATABASE [' + $_ + ']
    TO  DISK = N''\\MirrorServer\'  + $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,1) + '$' + $MirrorSQLDefaultLocations.BackupDirectory.Substring(2) + $_ + 'Mirror34.bak''
    WITH NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD
;'}
$Backups +=
'


EXEC XP_CMDSHELL ''net use S: /delete'', NO_OUTPUT

EXEC sp_configure ''xp_cmdshell'',0 --turn off
RECONFIGURE'
$Backups > ($File + '\BackupScript.sql')

##Creates Database Log Backup Script - Saves To SQL Backup Directory (from input form) On Mirror Server
$LogBackup =
'--Had To Create A Shared Drive In SQL In Order To Save Backup Files To A Remote Machine
EXEC sp_configure ''show advanced options'', 1
RECONFIGURE
EXEC sp_configure ''xp_cmdshell'', 1
RECONFIGURE

EXEC XP_CMDSHELL ''net use S: "\\MirrorServer\' + $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,1) + '$' + '" /User:SQL_MirrorUser "' + $ServerUserpword + '"'', NO_OUTPUT


'
$LogBackup +=
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'BACKUP LOG [' + $_ + ']
    TO  DISK = N''\\MirrorServer\'  + $MirrorSQLDefaultLocations.BackupDirectory.Substring(0,1) + '$' + $MirrorSQLDefaultLocations.BackupDirectory.Substring(2) + $_ + 'Mirror34.bak''
    WITH NOFORMAT, NOINIT, SKIP, NOREWIND, NOUNLOAD
;'}
$LogBackup +=
'


EXEC XP_CMDSHELL ''net use S: /delete'', NO_OUTPUT

EXEC sp_configure ''xp_cmdshell'',0 --turn off
RECONFIGURE' 
$LogBackup > ($File + '\LogBackupScript.sql')

##Creates Database Restore Script
$BackupRestore = 
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
$DatbaseLogicalFile = Invoke-Sqlcmd -Query "SELECT	name AS LogicalDatabaseFileName
                            FROM	sys.master_files
                            WHERE	DB_NAME(database_id) IN ('$_')
		                            AND type = 0"
$LogLLogicalFile = Invoke-Sqlcmd -Query "SELECT	name AS LogicalLogFileName
                            FROM	sys.master_files
                            WHERE	DB_NAME(database_id) IN ('$_')
		                            AND type = 1"
'USE [master]
RESTORE DATABASE [' + $_ + '] FROM  DISK = N''' + $MirrorSQLDefaultLocations.BackupDirectory + $_ + 'Mirror34.bak'' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,
MOVE N''' + $DatbaseLogicalFile.LogicalDatabaseFileName + ''' TO N''' + $MirrorSQLDefaultLocations.DefaultFile + $DatbaseLogicalFile.LogicalDatabaseFileName + '.mdf'',
MOVE N''' + $LogLLogicalFile.LogicalLogFileName + ''' TO N''' + $MirrorSQLDefaultLocations.DefaultFile + $LogLLogicalFile.LogicalLogFileName + '.ldf'';
RESTORE LOG [' + $_ + '] FROM  DISK = N''' + $MirrorSQLDefaultLocations.BackupDirectory + $_ + 'Mirror34.bak'' WITH  FILE = 2,  NORECOVERY,  NOUNLOAD
;'} > ($File + '\BackupRestore.sql')

##Creates Set Partner Script For Principal Server
$PrincipalSetMirror =
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'ALTER DATABASE ' + $_ + ' SET PARTNER = ''tcp://MirrorServer:4041''
;'} > ($File + '\PrincipalSetMirror.sql')

##Creates Set Partner Script For Mirror Server
$MirrorSetMirror =
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'ALTER DATABASE ' + $_ + ' SET PARTNER = ''tcp://PrincipalServer:4040''
;'} > ($File + '\MirrorSetMirror.sql')

##Creates Set Witness Script For Principal Server
$PrincipalSetWitness =
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'ALTER DATABASE ' + $_ + ' SET WITNESS = ''tcp://WitnessServer:4042''
;'} > ($File + '\PrincipalSetWitness.sql')
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



#Runs Final SQL Commands For Mirroring Process
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************
##Concatinating SQL Scipts to Run Invoke Commands
$RecoveryModeScript = $File + "\RecoveryMode.sql"
$BackupScript = $File + "\BackupScript.sql"
$LogBackupScript = $File + "\LogBackupScript.sql"
$BackupRestoreScript = $File + "\BackupRestore.sql"
$PrincipalSetMirrorScript = $File + "\PrincipalSetMirror.sql"
$MirrorSetMirrorScript = $File + "\MirrorSetMirror.sql"
$PrincipalSetWitnessScript = $File + "\PrincipalSetWitness.sql"

##Transfers Last Of SQL Scripts To Be Run On Mirror Server
Start-BitsTransfer -Source ($BackupRestoreScript) -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
Start-BitsTransfer -Source ($MirrorSetMirrorScript) -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred

##Runs The Backup/Restore Scipts And Enables Mirroring
Invoke-Sqlcmd -InputFile $RecoveryModeScript
Invoke-Sqlcmd -InputFile $BackupScript
Invoke-Sqlcmd -InputFile $LogBackupScript
Set-Location C:\
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($BackupRestoreScript) Invoke-Sqlcmd -InputFile $BackupRestoreScript} -Args $BackupRestoreScript
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($MirrorSetMirrorScript) Invoke-Sqlcmd -InputFile $MirrorSetMirrorScript} -Args $MirrorSetMirrorScript
Invoke-Sqlcmd -InputFile $PrincipalSetMirrorScript
Start-Sleep -S 15
Invoke-Sqlcmd -InputFile $PrincipalSetWitnessScript
Set-Location C:\



#Creating Orphaned Users/Test Failover Scripts
#*****************************************************************************
#*****************************************************************************
##Failing Over Server To Check For Orphan User On The Mirror
$Failover = 
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'ALTER DATABASE [' + $_ + '] SET PARTNER FAILOVER
;'} > ($File + '\Failover.sql')

##SQL Query For Orphaned Users To Be Run On Mirror Server - Creates A File Of List Output
$CheckForOrphanUsers = 
Get-Content ($File.Substring(0,$FileIndex) + "\Databases.txt") | ForEach-Object {
'USE [' + $_ + ']; EXEC sp_change_users_login @Action=''Report'';'} 
#*****************************************************************************
#*****************************************************************************


##Concatinating SQL Scipts to Run Invoke Commands
$FailoverScript = $File + "\Failover.sql"

##Transfers Failover Scripts To Be Run On Mirror Server After Orphan Users Are Checked/Restored
Start-BitsTransfer -Source ($FailoverScript) -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred

##Runs Failover Script On Principal
Invoke-Sqlcmd -InputFile $FailoverScript
Set-Location C:\


##Runs Sript If Orphan Users Are Found
#*****************************************************************************
#*****************************************************************************
If ((Invoke-Command -Session $MirrorSession -ScriptBlock {Param($CheckForOrphanUsers) Invoke-Sqlcmd -Query $CheckForOrphanUsers} -Args $CheckForOrphanUsers).UserName.Count -gt 0)
    {
    $OrphanedUsersList = 
"DECLARE @cmd VARCHAR(8000)
SET @cmd = 'bcp ""SELECT	name FROM sys.database_principals WHERE type_desc = ''SQL_USER'' AND sid NOT IN (SELECT sid FROM sys.server_principals)	AND name <> ''guest''"" queryout """ + $File.Substring(0,$FileIndex) + "\Orphans.txt" + """ -T -c -t'


EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE

EXEC master..xp_cmdshell @cmd

EXEC sp_configure 'xp_cmdshell',0 --turn off
RECONFIGURE" > ($File + '\OrphanUserScript.sql')

    $OrphanUserScript = $File + "\OrphanUserScript.sql"
    Start-BitsTransfer -Source ($File + '\OrphanUserScript.sql') -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
    Invoke-Command -Session $MirrorSession -ScriptBlock {Param($OrphanUserScript) Invoke-Sqlcmd -InputFile $OrphanUserScript} -Args $OrphanUserScript
    $OrphanList = Invoke-Command -Session $MirrorSession -ScriptBlock {Param($File,$FileIndex) (Get-Content ($File.Substring(0,$FileIndex) + "\Orphans.txt")) -join ','} -Args $File,$FileIndex


    ##SQL To Export User Creation Script
    #*****************************************************************************
    #*****************************************************************************
    ##Stored Procedure And Export Command
    $ExportUserScript =
"USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
	@binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO
 
IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name IN (" + "'" + $OrphanList + "'" + ")
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'xp_cmdshell', 1
RECONFIGURE

EXEC MASTER..XP_CMDSHELL 'sqlcmd -s localhost -q ""exec sp_help_revlogin"" -o """ + $File + "\RestoreUser.sql" + """ -h1'

EXEC sp_configure 'xp_cmdshell',0 --turn off
RECONFIGURE
" > ($File + "ExportUserSP.sql")


    ##Run Export And Restore Users Scripts
    #*****************************************************************************
    #*****************************************************************************
    ##Concatenate File Name
    $SQLExportUserSP = $File + "\ExportUserSP.sql" 
    $SQLRestoreUser = $File + "\RestoreUser.sql" 

    Invoke-Sqlcmd -InputFile $SQLExportUserSP
    Set-Location C:\
    
    Start-BitsTransfer -Source ($File + '\RestoreUser.sql') -Destination ('\\MirrorServer\' + $File.Substring(0,1) + '$' + $File.Substring(2)) -Credential $RemotingCred
    Invoke-Command -Session $MirrorSession -ScriptBlock {Param($SQLRestoreUser) Invoke-Sqlcmd -InputFile $SQLRestoreUser} -Args $SQLRestoreUser
    }
#*****************************************************************************
#*****************************************************************************


##Flips Mirror Back To Principal
Start-Sleep -S 10
Invoke-Command -Session $MirrorSession -ScriptBlock {Param($FailoverScript) Invoke-Sqlcmd -InputFile $FailoverScript} -Args $FailoverScript
#*****************************************************************************
#*****************************************************************************
#*****************************************************************************



Net Use M: /Delete
Net Use W: /Delete

