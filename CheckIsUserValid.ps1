. .\FileLogging.ps1


# This is used by some of the functions below
$logonUserSignature =

@'

[DllImport( "advapi32.dll" )]
public static extern bool LogonUser( String lpszUserName,
                                     String lpszDomain,
                                     String lpszPassword,
                                     int dwLogonType,
                                     int dwLogonProvider,
                                     ref IntPtr phToken );

'@



$closeHandleSignature =

@'

[DllImport( "kernel32.dll", CharSet = CharSet.Auto )]
public static extern bool CloseHandle( IntPtr handle );

'@

$revertToSelfSignature = 
@'

   [DllImport("advapi32.dll", SetLastError = true)]
   public static extern bool RevertToSelf();

'@

$AdvApi32 = Add-Type -MemberDefinition $logonUserSignature -Name "AdvApi32" -Namespace "PsInvoke.NativeMethods" -PassThru
$Kernel32 = Add-Type -MemberDefinition $closeHandleSignature -Name "Kernel32" -Namespace "PsInvoke.NativeMethods" -PassThru
$AdvApi32_2  = Add-Type -MemberDefinition $revertToSelfSignature -Name "AdvApi32_2" -Namespace "PsInvoke.NativeMethods" -PassThru
[Reflection.Assembly]::LoadWithPartialName("System.Security")
$LogFilePath = "CheckIsUserValid.txt"



function IsLocalUserNamePasswordValid()
{
    param(
    [String]$UserName,
    [String]$Password
	)
	
    $Logon32ProviderDefault = 0
	$Logon32LogonInteractive = 2
	$tokenHandle = [IntPtr]::Zero       
	$success = $false    
	$DomainName = $null

	#Attempt a logon using this credential
	Write-LogFileEntry "IsLocalUserNamePasswordValid:Attempting logon using User: $UserName, Password: $Password" | Out-Null
	$success = $AdvApi32::LogonUser($UserName, $DomainName, $Password, $Logon32LogonInteractive, $Logon32ProviderDefault, [Ref] $tokenHandle)            

	if (!$success )
	{
		$retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
		Write-LogFileEntry "IsLocalUserNamePasswordValid:LogonUser was unsuccessful. User may not be valid." | Out-Null
		return $false
	} else {
		Write-LogFileEntry "IsLocalUserNamePasswordValid:LogonUser was successful. Username is valid" | Out-Null
		$Kernel32::CloseHandle( $tokenHandle ) | Out-Null
		return $True
	}
}

function IsDomainUserNamePasswordValid()
{
    param(
    [String]$UserName,
	[String]$Password,
	[String]$DomainName
	)
	
    $Logon32ProviderDefault = 0
	$Logon32LogonInteractive = 2
	$tokenHandle = [IntPtr]::Zero       
	$success = $false    	

	#Attempt a logon using this credential
	Write-LogFileEntry "IsDomainUserNamePasswordValid:Attempting logon using User: $UserName, Password: $Password" | Out-Null
	$success = $AdvApi32::LogonUser($UserName, $DomainName, $Password, $Logon32LogonInteractive, $Logon32ProviderDefault, [Ref] $tokenHandle)            

	if (!$success )
	{
		$retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
		Write-LogFileEntry "IsDomainUserNamePasswordValid:LogonUser was unsuccessful. User may not be valid." | Out-Null
		return $false
	} else {
		Write-LogFileEntry "IsDomainUserNamePasswordValid:LogonUser was successful. Username is valid" | Out-Null
		$Kernel32::CloseHandle( $tokenHandle ) | Out-Null
		return $True
	}
}


