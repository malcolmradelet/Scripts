$UserName = "name2"
$DiscoveredProfiles = @()
$aProfileTypes = @("$UserName";"$UserName"+".v2";"$UserName"+".v6")

Foreach ($P in $aProfileTypes) {
    if(Test-Path -Path ("C:\Temp\Profiles\" + "$P") -PathType Container) {
        Write-Verbose "$P Folder Found"
        $DiscoveredProfiles += "C:\Temp\Profiles\" + "$P"}
    }

$DiscoveredProfiles
