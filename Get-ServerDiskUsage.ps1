#$Cred = (Get-Credential)
$ServerList = Get-ADComputer -Filter * -SearchBase "***" | Select Name

$ServerCollection = @()

foreach ($C in $ServerList.Name) {
    $Disk = Get-WmiObject Win32_LogicalDisk -ComputerName $C -Credential $Cred | Where -Property DriveType -EQ 3
    foreach ($D in $Disk) {
    $Object = New-Object psobject
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "Server" -Value ""
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "Disk" -Value ""
    Add-Member -InputObject $Object -MemberType NoteProperty -Name "Free Space (GB)" -Value ""
    $Object.Server = $C
    $Object.Disk = $D.DeviceID
    $Object.'Free Space (GB)' = [Math]::Round($D.FreeSpace / 1GB)
    $ServerCollection += $Object
    }
    
}
