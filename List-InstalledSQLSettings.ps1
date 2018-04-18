function Get-SQLDiscoveryReport {
    <#
.SYNOPSIS

Retrieve SQL Discovery reports and store them in a shared location.

.DESCRIPTION

This script uses the setup.exe bootstrap file left behind by SQL installations with the "/Action=RunDiscovery" flag
to generate a "SQL Discovery Report".

The report contains the installed SQL Server products, instances, and features, which can be useful to diagnose
issues or prepare a cluster.

After the reports are generated they are moved to a specified location with the name of the server appended to the
filename.

.PARAMETER ComputerName
Specifies the computer or ComputerName to query.

.PARAMETER SharePath
Specifies the destination folder to put the reports in. The path must end with a slash "\"

.EXAMPLE

PS C:\>Get-SQLDiscoveryReport -ComputerName SQLServer01 -SharePath "\\FileServer01\Share01\"
#>
    [CmdletBinding()]
    param(
        $ComputerName,
        [string]$SharePath
    )
    $date = Get-Date -Format yyyyMMdd
    if ($SharePath) {
        $NewPath = "$SharePath$date" + "\"
        if (!(Test-Path -Path $NewPath)) {
            Write-Output "Share Not Found."
            Write-Output "Creating."
            New-Item -Path $NewPath -ItemType Directory
        }
        else { 
            Write-Output "Share already exists"
        }
    }
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
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
        if (!(Test-Path -Path $destPath)) {
            New-Item -Path $destPath -ItemType Directory
        }
        Copy-Item -Path $copyPath -Destination "$destPath\$destFile" -Force
    } -ArgumentList $date
    foreach ($computer in $ComputerName) {
        Copy-Item -path "\\$Computer\C$\Temp\$date\$computer - SqlDiscoveryReport.htm" -Destination $NewPath -Force
    }
}
