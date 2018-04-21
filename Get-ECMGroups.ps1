$ECMGroupList =
'Group1',
'Group2',
'Group3'
foreach ($group in $ECMGroupList) {
    $path = Join-Path -Path 'C:\Temp\' -ChildPath "$group.csv"
    Get-ADGroupMember -Identity $group -Recursive | Get-ADUser -Properties DisplayName, Title, Department |
        Select-Object DisplayName, samAccountName, Title, Department |
        Export-Csv $path -NoTypeInformation
}