function Get-SQLDiscoveryReport {
    [CmdletBinding()]
    param(
    $Computers,
    [string]$SharePath
    )
    $date = Get-Date -Format yyyyMMdd
    if($SharePath) {
        $NewPath = "$SharePath$date" + "\"
        if(!(Test-Path -Path $NewPath)) {
            Write-Output "Share Not Found."
            Write-Output "Creating."
            New-Item -Path $NewPath -ItemType Directory
        } else { Write-Output "Share already exists"}
    }
    Invoke-Command -ComputerName $Computers -ScriptBlock {
        param(
            [string]$date
        )
        $paths = Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server\*\Setup Bootstrap\SQLServer*\setup.exe" -Recurse
        foreach ($path in $paths.FullName) {
            &"$path" /Action=RunDiscovery
        }
        $logs = Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server\*\Setup Bootstrap\Log\*" | Where-Object {$_.PSisContainer} | Sort-Object {$_.LastWriteTime} | Select-Object -Last 1
        $logname = "SqlDiscoveryReport.htm"
        
        $copyPath = (get-childitem $logs.FullName | Where-Object {$_.Name -eq $logname}).FullName
        $destPath = Join-Path -Path "C:\Temp\" -ChildPath $date
        $destFile = "$env:computername - $logname"
        if(!(Test-Path -Path $destPath)) {
            New-Item -Path $destPath -ItemType Directory
        }
        Copy-Item -Path $copyPath -Destination "$destPath\$destFile" -Force
    } -ArgumentList $date
    foreach ($computer in $Computers) {
        Copy-Item -path "\\$Computer\C$\Temp\$date\$computer - SqlDiscoveryReport.htm" -Destination $NewPath -Force
    }
}