<#
.Synopsis
	Script to check if a given local or domain username and password are valid.

.DESCRIPTION
    Script to check if a given local or domain username and password are valid.
    This script makes use of System.DirectoryServices.AccountManagement.PrincipalContext class.
    This requires a minimum of .Net 3.5
   
    Author : vimalsh@live.com

.EXAMPLE
    Check if the given local username and password is valid.
    IsLocalUserNamePasswordValid -UserName TestLocalUser1 -Password Test@Pass1

    
.EXAMPLE
	Check if the given domain username and password is valid.
    IsDomainUserNamePasswordValid -UserName TestDomUser1 -Password Test@Pass1 -DomainName testdom.local
#>

. .\FileLogging.ps1
Add-Type -AssemblyName System.DirectoryServices.AccountManagement  | Out-Null
  

function IsLocalUserNamePasswordValid()
{
    param(
    [String]$UserName,
    [String]$Password
	)

    Write-LogFileEntry "IsLocalUserNamePasswordValid: Attempting to validate User: $UserName, Password: $Password"  | Out-Null           
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$ComputerName)
    $bReturn = $DS.ValidateCredentials($UserName, $Password)
    
    # if function returns, then exit with the return code
    Write-LogFileEntry -Message "IsLocalUserNamePasswordValid: Returning $bReturn" | Out-Null
    return $bReturn
}

function IsDomainUserNamePasswordValid()
{
    param(
    [String]$UserName,
	[String]$Password,
	[String]$DomainName
	)
  
    Write-LogFileEntry "IsDomainUserNamePasswordValid:Attempting to validate User: $UserName, Password: $Password"  | Out-Null
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('domain',$DomainName)
    $bReturn = $DS.ValidateCredentials($UserName, $Password)
    
    # if function returns, then exit with the return code
    Write-LogFileEntry -Message "IsDomainUserNamePasswordValid: Returning $bReturn" | Out-Null
    return $bReturn
}


#Set-LoggerAttribs -LogFilePath (".\mylog" + "$(get-date -Format 'hhmm_dd_mm_yyyy')" + ".txt")
#Write-LogFileEntry "testing if local username and password is valid"
#IsLocalUserNamePasswordValid -UserName TestLocalUser1 -Password Test@Pass1
#Write-LogFileEntry "testing if local username and password is valid"
#IsDomainUserNamePasswordValid -UserName TestDomUser1 -Password Test@Pass1 -DomainName testdom.local
