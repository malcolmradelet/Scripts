#Removes most built-in Windows 10 apps and clears the start menu

Function Remove-Win10Apps {
    #Get installed user apps
    $InstalledApps = (Get-AppxPackage -AllUsers).Name

    #Get provisioned apps
    $ProvisionedApps = (Get-AppxProvisionedPackage -Online).DisplayName

    #Apps to ignore
    $ExcludedApps = @(
        "*calc*",    
        "*cortana*",
        "*edge*",    
        "*store*",
        "*sticky*",
        "*SoundRecorder*",
        "*MSPaint*",
        "*feedback*",
        "*NET.Native*",
        "*VCLibs*",
        "*Windows.Photos",
        "*WindowsCamera*"
    )

    [System.Collections.ArrayList]$UApps = @()
    [System.Collections.ArrayList]$PApps = @()

    foreach ($app in $InstalledApps) {
        foreach ($matched in $ExcludedApps) {
            if ($app -like $matched) {
                $UApps.Add($app)
            }
        }
    }
    foreach ($app in $ProvisionedApps) {
        foreach ($matched in $ExcludedApps) {
            if ($app -like $matched) {
                $PApps.Add($app)
            }
        }
    }

    Get-AppxPackage -AllUsers | Where-Object {$_.Name -notin $UApps} | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -notin $PApps} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Function Clear-StartMenu {
    Write-Host "***Setting clean start menu for new profiles...***"
    $StartLayoutString = @"
<LayoutModificationTemplate Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
 <LayoutOptions StartTileGroupCellWidth="6" />
 <DefaultLayoutOverride>
   <StartLayoutCollection>
     <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
       <start:Group Name="" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
         <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\File Explorer.lnk" />
         <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Snipping Tool.lnk" />
         <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\System Tools\Control Panel.lnk" />
       </start:Group>
     </defaultlayout:StartLayout>
   </StartLayoutCollection>
 </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@
    Add-Content $Env:TEMP\StartLayout.xml $StartLayoutString
    Import-StartLayout -layoutpath $Env:TEMP\startlayout.xml -mountpath $Env:SYSTEMDRIVE\
    Remove-Item $Env:TEMP\StartLayout.xml
}

Remove-Win10Apps; Clear-StartMenu