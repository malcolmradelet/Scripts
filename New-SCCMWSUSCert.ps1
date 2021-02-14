Function Request-WebServerCertificate {
  [CmdletBinding()]
  Param (
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FQDN = [System.Net.Dns]::GetHostEntry('').HostName,
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$CertificateTemplate = "SCCMWebServerCertificate",
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FriendlyName = "SCCM Web Server Cert"
  )
  Function Remove-ReqTempFiles() {
      Param(
        [String[]]$TempFiles
      )
      Remove-Item -Path $TempFiles -Force -ErrorAction SilentlyContinue
  }

  Function Remove-ReqFromStore {
      Param(
        [String]$CN
      )
      $CertStore = new-object system.security.cryptography.x509Certificates.x509Store('REQUEST', 'LocalMachine')
      $CertStore.Open('ReadWrite')
      foreach ($CertReq in $($CertStore.Certificates)) {
        If ($CertReq.Subject -eq "CN=$CN") {
          $CertStore.Remove($CertReq)
        }
      }
      $CertStore.close()
  }
  $INF          = [System.IO.Path]::GetTempFileName()
  $Req          = [System.IO.Path]::GetTempFileName()
  $rootDSE      = [System.DirectoryServices.DirectoryEntry]'LDAP://RootDSE'
  $searchBase   = [System.DirectoryServices.DirectoryEntry]"LDAP://$($rootDSE.configurationNamingContext)"
  $CAs          = [System.DirectoryServices.DirectorySearcher]::new($searchBase,'objectClass=pKIEnrollmentService').FindAll()
  $CAName       = "$($CAs[0].Properties.dnshostname)\$($CAs[0].Properties.cn)"
  $FileName     = $FQDN -replace "^\*","wildcard"
  $Cer          = Join-Path -Path $env:TEMP -ChildPath "$FileName.cer"
  $RSP          = Join-Path -Path $env:TEMP -ChildPath "$FileName.rsp"
  $SubjectName  = "CN = $FQDN"
  $CertificateRequest=@"
[Version]
Signature="$Windows NT$"

[NewRequest]
FriendlyName = `"$($FriendlyName)`"
Subject = `"$($SubjectName)`"
KeyLength = 2048
HashAlgorithm = SHA256
EncryptionAlgorithm = AES
Exportable = FALSE
KeySpec = 1
KeyUsage = 0xa0
MachineKeySet = TRUE
SMIME = FALSE
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
[RequestAttributes]
CertificateTemplate = `"$($CertificateTemplate)`"
SAN="dns=$($FQDN)"
"@

  Remove-ReqTempFiles -TempFiles $INF, $Req, $Cer, $RSP
  Set-Content -Path $INF -Value $CertificateRequest

  Write-Host "Requesting certificate with subject $SubjectName and SAN: DNS=$($FQDN)" -ForegroundColor Green
  Invoke-Expression -Command "CertReq -machine -new `"$INF`" `"$Req`""
  If (!($LastExitCode -eq 0)) {
    Throw "CertReq -new command failed"
  }

  Invoke-Expression -Command "CertReq -adminforcemachine -config $CAName -submit `"$Req`" `"$Cer`""
  If (!($LastExitCode -eq 0)) {
    Throw "CertReq -submit command failed"
  }
  
  Invoke-Expression -Command "CertReq -accept `"$Cer`""
  If (!($LastExitCode -eq 0)) {
    Throw "CertReq -accept command failed"
  }
  If (($LastExitCode -eq 0) -and ($? -eq $true)) {
    Write-Host "Certificate request successfully finished!" -ForegroundColor Green
  }
  Else {
    Throw "Request failed with unknown error."
  }

  Remove-ReqTempFiles -TempFiles $INF, $Req, $Cer, $RSP
  Remove-ReqFromStore -CN $CN
}

Function Edit-WsusConfig {
  [CmdletBinding()]
  Param (
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FQDN = [System.Net.Dns]::GetHostEntry('').HostName,
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FriendlyName = "SCCM Web Server Cert"
  )
  If (!(Get-Module "WebAdministration")) {
    Write-Warning "Importing WebAdministration module"
    Import-Module WebAdministration -ErrorAction Stop
    Write-Host "Module successfully imported" -ForegroundColor Green
  }
  $WsusCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -EQ "$FriendlyName"}
  $WsusBinding = Get-WebBinding -Name "WSUS Administration" -Protocol https
  Write-Host "Creating SSL binding on WSUS Administration site with $FriendlyName" -ForegroundColor Green
  $WsusBinding.AddSslCertificate($WsusCert[-1].Thumbprint,"My")

  Write-Host "Updating SSL settings on WSUS Applications" -ForegroundColor Green
  Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ApiRemoting30" -Filter 'system.webserver/security/access' -Value 8
  Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ClientWebService" -Filter 'system.webserver/security/access' -Value 8
  Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/DSSAuthWebService" -Filter 'system.webserver/security/access' -Value 8
  Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/ServerSyncWebService" -Filter 'system.webserver/security/access' -Value 8
  Set-WebConfiguration -PSPath IIS:\Sites -Location "WSUS Administration/SimpleAuthWebService" -Filter 'system.webserver/security/access' -Value 8

  ."c:\Program Files\Update Services\Tools\WsusUtil.exe" configuressl $FQDN
}

Function Update-WsusToSSL {
  [CmdletBinding()]
  Param (
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FQDN = [System.Net.Dns]::GetHostEntry('').HostName,
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$CertificateTemplate = "SCCMWebServerCertificate",
    [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [string]$FriendlyName = "SCCM Web Server Cert"
  )
  Request-WebServerCertificate -FQDN $FQDN -CertificateTemplate $CertificateTemplate -FriendlyName $FriendlyName
  Edit-WsusConfig -FQDN $FQDN -FriendlyName $FriendlyName
}
