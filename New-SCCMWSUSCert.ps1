Import-Module WebAdministration
$MyCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -EQ "SCCM Web Server Cert"}
$MyBinding = Get-WebBinding -Name "WSUS Administration" -Protocol https
$MyBinding.AddSslCertificate($MyCert.Thumbprint,"My")

Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ApiRemoting30" -Filter 'system.webserver/security/access' -Value 8
Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ClientWebService" -Filter 'system.webserver/security/access' -Value 8
Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/DSSAuthWebService" -Filter 'system.webserver/security/access' -Value 8
Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ServerSyncWebService" -Filter 'system.webserver/security/access' -Value 8
Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/SimpleAuthWebService" -Filter 'system.webserver/security/access' -Value 8
