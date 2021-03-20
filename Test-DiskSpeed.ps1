Import-Module -Name ImportExcel
$xlfile = "C:\Temp\PSreports.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue
$Drive = "E:\IO.dat"
$Test1 = @()
$Test2 = @()
$Test3 = @()
$Test4 = @()
$WritePercentage = 30

1..12 | ForEach-Object {
   Write-Progress -Activity "Small Random IO Test 1" -Status "Run $_ of 12" -PercentComplete (($_/12)*100)
   $param = "-o$_"
   $write = "-w$WritePercentage"
   $ThreadCount = 2
   $thread = "-t$ThreadCount"
   $result = . C:\DiskSpd\amd64\diskspd.exe $thread $param -r -b4k $write -d120 -W15 -Sh -D -L -c64G -Z1M $Drive
   foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
   foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
   $Object = New-Object psobject
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPUParam" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Threads/File" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "QD/Thread" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Total QD" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Write %" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "IOPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "MBPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Latency (ms)" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPU" -Value ""
   $Object.CPUParam = $param
   $Object.'Threads/File' = 2
   $Object.'QD/Thread' = $_
   $Object.'Total QD' = $_ * $ThreadCount
   $Object.'Write %' = $WritePercentage
   $Object.IOPS = $total.Split("|")[3].Trim()
   $Object.MBPS = $total.Split("|")[2].Trim()
   $Object.'Latency (MS)' = $total.Split("|")[4].Trim()
   $Object.CPU = $avg.Split("|")[1].Trim()
   $Test1 += $Object
}

1..24 | ForEach-Object {
    Write-Progress -Activity "Small Random IO Test 2" -Status "Run $_ of 24" -PercentComplete (($_/24)*100)
    $QD = 120
    $write = "-w$WritePercentage"
    if (($QD % $_) -eq 0) {
        $thread = "-t$_"
        $param = "-o$($QD / $_)"
        $result = . C:\DiskSpd\amd64\diskspd.exe $thread $param -r -b4k $write -d120 -W15 -Sh -D -L -c64G -Z1M $Drive
        foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
        foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
        $Object = New-Object psobject
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPUParam" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "Threads/File" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "QD/Thread" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "Total QD" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "Write %" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "IOPS" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "MBPS" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "Latency (ms)" -Value ""
        Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPU" -Value ""
        $Object.CPUParam = $param
        $Object.'Threads/File' = $_
        $Object.'QD/Thread' = $QD / $_
        $Object.'Total QD' = $QD
        $Object.'Write %' = $WritePercentage
        $Object.IOPS = $total.Split("|")[3].Trim()
        $Object.MBPS = $total.Split("|")[2].Trim()
        $Object.'Latency (MS)' = $total.Split("|")[4].Trim()
        $Object.CPU = $avg.Split("|")[1].Trim()
        $Test2 += $Object
    }
}

1..12 | ForEach-Object {
   Write-Progress -Activity "Large Sequential Reads" -Status "Run $_ of 12" -PercentComplete (($_/12)*100)
   $param = "-o$_"
   $result = . C:\DiskSpd\amd64\diskspd.exe -t1 $param -b512k -d120 -W15 -Sh -D -L -c64G -Z1M $Drive
   foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
   foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
   $Object = New-Object psobject
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPUParam" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "IOPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "MBPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Latency (ms)" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPU" -Value ""
   $Object.CPUParam = $param
   $Object.IOPS = $total.Split("|")[3].Trim()
   $Object.MBPS = $total.Split("|")[2].Trim()
   $Object.'Latency (MS)' = $total.Split("|")[4].Trim()
   $Object.CPU = $avg.Split("|")[1].Trim()
   $Test3 += $Object
}

1..12 | ForEach-Object {
   Write-Progress -Activity "Large Sequential Writes" -Status "Run $_ of 12" -PercentComplete (($_/12)*100)
   $param = "-o$_"
   $result = . C:\DiskSpd\amd64\diskspd.exe -t1 $param -w100 -b512k -d120 -W15 -Sh -D -L -c64G -Z1M $Drive
   foreach ($line in $result) {if ($line -like "total:*") { $total=$line; break } }
   foreach ($line in $result) {if ($line -like "avg.*") { $avg=$line; break } }
   $Object = New-Object psobject
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPUParam" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "IOPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "MBPS" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "Latency (ms)" -Value ""
   Add-Member -InputObject $Object -MemberType NoteProperty -Name "CPU" -Value ""
   $Object.CPUParam = $param
   $Object.IOPS = $total.Split("|")[3].Trim()
   $Object.MBPS = $total.Split("|")[2].Trim()
   $Object.'Latency (MS)' = $total.Split("|")[4].Trim()
   $Object.CPU = $avg.Split("|")[1].Trim()
   $Test4 += $Object
}

$Test1 | Export-Excel $xlfile -AutoSize -StartRow 1 -TableName "Test1" -WorksheetName "Small Random IO Test 1"
$Test2 | Export-Excel $xlfile -AutoSize -StartRow 1 -TableName "Test2" -WorksheetName "Small Random IO Test 2"
$Test3 | Export-Excel $xlfile -AutoSize -StartRow 1 -TableName "Test3" -WorksheetName "Large Sequential Reads Test 3"
$Test4 | Export-Excel $xlfile -AutoSize -StartRow 1 -TableName "Test4" -WorksheetName "Large Sequential Writes Test 4"
