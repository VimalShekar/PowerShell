<#
    .SYNOPSIS 
        Impersonation function

    .DESCRIPTION
        Impersonates a user and executes a script block as that user. This requires
        that you provide the details of the user along with the script block.

    .EXAMPLE
        Execute-ScriptBlockAfterImpersonation -scriptBlock { Get-ChildItem 'C:\' | Foreach { Write-Host $_.Name } } -UserName "testdom.com\testadmin" -Password "Test@pass1"     
#>

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



function Execute-ScriptBlockAfterImpersonation {
    param( 
        [ScriptBlock] $ScriptBlock,
        [String] $UserName = $null,
        [String] $Password = $null,
        [String] $DomainName = $null
     )
     
    try {

        $Logon32ProviderDefault = 0
        $Logon32LogonInteractive = 2
        $tokenHandle = [IntPtr]::Zero       
        $success = $false    

        $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name    
        Write-Host "Before Impersonation: $identityName"

        $success = $AdvApi32::LogonUser($UserName, $DomainName, $Password, $Logon32LogonInteractive, $Logon32ProviderDefault, [Ref] $tokenHandle)
        if (!$success )
        {
            $retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Host "LogonUser was unsuccessful. Error code: $retVal"
            return
        }

        $newIdentity = New-Object System.Security.Principal.WindowsIdentity( $tokenHandle )
        $context = $newIdentity.Impersonate()
        
        $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Host "After Impersontaion: $identityName"

        # Execute the Script block
        & $scriptBlock

    }
    catch [System.Exception] {
        Write-Host $_.Exception.ToString()
    }

    finally {

        #Restoring context
        if($context -ne $null )
        {
            $context.Undo()
        }

        $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Host "After Restoring Context: $identityName"

        if ( $tokenHandle -ne [System.IntPtr]::Zero )
        {
            $Kernel32::CloseHandle( $tokenHandle )
        }

    }
}