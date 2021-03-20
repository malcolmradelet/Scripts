#Requires –Modules ActiveDirectory
Function New-GTLADUser {
  <#
    .SYNOPSIS
    Creates a new user in Active Directory using a template file.
    .DESCRIPTION
    This script reads a ParameterValues file to create a new user account in Active Directory.
    The user account will have all required fields entered and be placed into the correct OU.
    It will also set a password and output that result to the console window.
    .PARAMETER FullName
    This is the staff member's full name. Only a first and last name are accepted, but hyphenated names will work.
    .PARAMETER AccountName
    The 3 digit SamAccountName - longer or shorter account names will be rejected.
    .PARAMETER Role
    Pick from a selection of roles. No values outside of the set provided will be accepted.
    .PARAMETER Credential
    Optional. Used to specify alternate credentials if required.
    .EXAMPLE
    PS> New-GTLADUser -FullName "FirstName LastName" -AccountName "y43" -Role Finance
    User FirstName LastName created with password: ____________
    .EXAMPLE
    PS> New-GTLADUser -FullName "Malcolm Radelet" -AccountName "111" -Role "System Admin" -Credential (Get-Credential)
    User Malcolm Radelet created with password: ____________
    .NOTES
    This script can be updated to enable user mailboxes, 2FA, and O365 licenses.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [String]$FullName,
    [Parameter(Mandatory=$true)]
    [ValidateLength(3,3)]
    [String]$AccountName,
    [Parameter(Mandatory=$true,HelpMessage="Pick a valid employee role")]
    [ValidateSet("System Admin","Finance","Marketing")]
    [String]$Role,
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty
  )

  $DNSRoot = (Get-ADDomain).DNSRoot
  $UserPassword = New-ADUserPassword
  $RoleValues = (Get-RoleValues $Role)
  $UserValues = (Get-UserValues $AccountName $FullName $DNSRoot $UserPassword)

  if ($Credential -ne [System.Management.Automation.PSCredential]::Empty) {
            $CommonValues['Credential'] = $Credential
        }

  Try {
  New-ADUser @CommonValues @RoleValues @UserValues -ErrorAction Stop
  }
  Catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] {
  Write-Warning $_.Exception.Message
  Break
  }
  Catch [Microsoft.ActiveDirectory.Management.ADException] {
  Write-Warning $_.Exception.Message
  Break
  }
  Catch [UnauthorizedAccessException] {
  Write-Warning $_.Exception.Message
  Break
  }

  Write-Output "User $FullName created with password: $UserPassword"
}

Function New-ADUserPassword {
  param(
    [Parameter()]
    [int]$Length = 12,
    [Parameter()]
    [int]$NumberOfAlphaNumericCharacters = 5,
    [Parameter()]
    [switch]$ConvertToSecureString
  )
  Add-Type -AssemblyName 'System.Web'
  $Password = [System.Web.Security.Membership]::GeneratePassword($Length, $NumberOfAlphaNumericCharacters)
  if ($ConvertToSecureString.IsPresent) {
        ConvertTo-SecureString -String $Password -AsPlainText -Force
    } else {
        $Password
    }
}

Function Get-RoleValues{
  param(
    [Parameter(Mandatory=$true)]
    [String]$Role
  )
  switch ($Role) {
    "System Admin" { $AdminRoleValues }
    "Finance" { $FinanceRoleValues }
    "Marketing" { $MarketingRoleValues }
  }
}

Function Get-UserValues {
  param(
  [Parameter(Mandatory=$true)]
  [String]$AccountName,
  [Parameter(Mandatory=$true)]
  [String]$FullName,
  [Parameter(Mandatory=$true)]
  [String]$DNSRoot,
  [Parameter(Mandatory=$true)]
  [String]$UserPassword
  )

  @{
    SamAccountName = $AccountName
    Name = $FullName
    GivenName = ($FullName -split ' ')[0]
    Surname = ($FullName -split ' ')[1]
    UserPrincipalName = "$AccountNAme@$DNSRoot"
    AccountPassword = (ConvertTo-SecureString -String $UserPassword -AsPlainText -Force)
  }
}
