$cred = Get-Credential
$path = Read-Host "Please enter a location to import computers from (CSV)"
#Remove Webex
$ErrorActionPreference = "SilentlyContinue"
$ComputerName = Import-Csv -Path D:\Scripts\WebexComputers.csv
[System.Collections.ArrayList]$ConnectedComputer = @()

Foreach ($c in $ComputerName.ComputerName) {
    if(Test-Connection -ComputerName $c -Count 1){
    $ConnectedComputer.Add($c)
    }
    else { Write-Output "$c is offline" }
}

Invoke-Command -ComputerName $ConnectedComputer -ScriptBlock {
    Start-Process -FilePath "c:\ProgramData\Webex\atcliun.exe" -ArgumentList "/v_meet /v_ra /v_smt" -WindowStyle Hidden
    Start-Sleep -s 30
    Stop-Process -Name atcliun -force
} -Credential $cred

foreach ($c in $ConnectedComputer) {
    if(Test-Path -Path "\\$c\c`$\ProgramData\Webex\ieatgpc.dll" -PathType Leaf -Credential $cred) {
    Write-Output "[$c] Vulnerability not removed"
    }
    else { Write-Output "[$c] Vulnerability removed" }
}
