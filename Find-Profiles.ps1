$UserName = "name"
$DiscoveredProfiles = @()
$aProfileTypes = @("$UserName";"$UserName"+".v2";"$UserName"+".v6")
$Path = "C:\Temp\Profiles\"

Foreach ($P in $aProfileTypes) {
    if(Test-Path -Path (Join-Path -Path $Path -ChildPath $P) -PathType Container) {
        Write-Verbose "$P Folder Found" -Verbose
        $DiscoveredProfiles += "C:\Temp\Profiles\" + "$P"}
    }

$DiscoveredProfiles
