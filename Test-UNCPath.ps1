function Test-UNCPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript( {
                if (!($_ | Test-Path) ) {
                    throw "Path does not exist"
                }
                return $true
            })]
        [alias("SP")]
        [System.IO.FileInfo]$SharePath
    )
    $date = Get-Date -Format yyyyMMdd
    $destPath = Join-Path -Path $SharePath -ChildPath $date
    Write-Verbose "Date: $date"
    Write-Verbose "Share Path: $SharePath"
    Write-Verbose "Destination Path: $destPath"
    if (!($destPath | Test-Path) ) {
        New-Item -Path $destPath -ItemType Directory
    }
    else { Write-Output "Path already exists"}
}