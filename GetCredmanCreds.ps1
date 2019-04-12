<#
.Synopsis
    Script to read stored credentials from credential manager
    Makes use of CredEnum API
    
.DESCRIPTION
    Script to read stored credentials from credential manager
    Makes use of CredEnum API
    Author : vimalsh@live.com

.EXAMPLE
    Get usernames and passwords from Web Credentials section of credential manager
    Get-PasswordVaultCredentials

.EXAMPLE
    Get usernames and passwords from Windows Credentials section of credential manager
    Get-CredManCreds
#>

if(Test-path ".\FileLogging.ps1")
{
. .\FileLogging.ps1
} else {
    # Redefine as this
    Function Write-LogFileEntry ($message, $Level, $IncludeErrorVar, $ClearErrorAfterLogging, $DoNotPrintToScreen )
    {
        Write-host $message
    }
}


function Get-PasswordVaultCredentials {
    $CRED_MANAGER_CREDS_LST = @()

    try
    {
        #Load the WinRT projection for the PasswordVault
        $Script:vaultType = [Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
        $Script:vault =  new-object Windows.Security.Credentials.PasswordVault -ErrorAction silentlycontinue
        $Results = $Script:vault.RetrieveAll()
        foreach($credentry in  $Results)
        {
                $credobject = $Script:vault.Retrieve( $credentry.Resource, $credentry.UserName )
                $obj = New-Object PSObject                
                Add-Member -inputObject $obj -memberType NoteProperty -name "Username" -value "$($credobject.UserName)"                  
                Add-Member -inputObject $obj -memberType NoteProperty -name "Hostname" -value "$($credobject.Resource)" # URI need to be sanitised
                Add-Member -inputObject $obj -memberType NoteProperty -name "Password" -value "$($credobject.Password)" 
                $CRED_MANAGER_CREDS_LST += $obj                
        }
    }
    catch
    {
        Write-LogFileEntry "Failed to instantiate passwordvault class. $($_.InvocationInfo.PositionMessage)"
    }
    return $CRED_MANAGER_CREDS_LST
}

#
# Function to compile C Sharp code into an assembly
#
function Compile-Csharp ()
{
    param(
    [String] $code, 
    [Array] $References
    )

    $cp = new-object Microsoft.CSharp.CSharpCodeProvider
    $framework = $([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())

    # Optional Array of Reference assemblies to be added
    $refs = New-Object Collections.ArrayList
    $refs.AddRange( @("${framework}\System.dll"))
    if ($references.Count -ge 1)
    {
        $refs.AddRange($References)
    }

    $cpar = New-Object System.CodeDom.Compiler.CompilerParameters
    $cpar.GenerateInMemory = $true
    $cpar.GenerateExecutable = $false
    $cr = $cp.CompileAssemblyFromSource($cpar, $code)

    if ( $cr.Errors.Count)
    {
        $codeLines = $code.Split("`n");
        foreach ($ce in $cr.Errors)
        {
            Write-LogFileEntry "Error: $($codeLines[$($ce.Line - 1)])" -DoNotPrintToScreen
            $ce |out-default
        }
        Throw "INVALID DATA: Errors encountered while compiling code"
    }
}





Function Get-CredManCreds()
{

# Defining C# code to enum credman creds
$CredEnumWrapperClass = 
@'
using System;
using System.Runtime.InteropServices;

namespace CredEnum {

        public enum CRED_FLAGS : uint {
            NONE = 0x0,
            PROMPT_NOW = 0x2,
            USERNAME_TARGET = 0x4
        }

        public enum CRED_ERRORS : uint {
            ERROR_SUCCESS = 0x0,
            ERROR_INVALID_PARAMETER = 0x80070057,
            ERROR_INVALID_FLAGS = 0x800703EC,
            ERROR_NOT_FOUND = 0x80070490,
            ERROR_NO_SUCH_LOGON_SESSION = 0x80070520,
            ERROR_BAD_USERNAME = 0x8007089A
        }

        public enum CRED_PERSIST : uint {
            SESSION = 1,
            LOCAL_MACHINE = 2,
            ENTERPRISE = 3
        }

        public enum CRED_TYPE : uint {
            GENERIC = 1,
            DOMAIN_PASSWORD = 2,
            DOMAIN_CERTIFICATE = 3,
            DOMAIN_VISIBLE_PASSWORD = 4,
            GENERIC_CERTIFICATE = 5,
            DOMAIN_EXTENDED = 6,
            MAXIMUM = 7,
            MAXIMUM_EX = 1007
        }
        
        //-- [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct Credential {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public string TargetName;
            public string Comment;
            public DateTime LastWritten;
            public UInt32 CredentialBlobSize;
            public string CredentialBlob;
            public CRED_PERSIST Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

        //-- [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct NativeCredential {
            public CRED_FLAGS Flags;
            public CRED_TYPE Type;
            public string TargetName;
            public string Comment;
            public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
            public UInt32 CredentialBlobSize;
            public IntPtr CredentialBlob;
            public CRED_PERSIST Persist;
            public UInt32 AttributeCount;
            public IntPtr Attributes;
            public string TargetAlias;
            public string UserName;
        }

    //-- For Safehandling of pointer to pointer of a non-blittable type
    public class CriticalCredentialHandle : Microsoft.Win32.SafeHandles.CriticalHandleZeroOrMinusOneIsInvalid
    {
        public CriticalCredentialHandle(IntPtr preexistingHandle)
        {
            SetHandle(preexistingHandle);
        }

        private Credential TranslateNativeCred(IntPtr pCred)
        {
            NativeCredential ncred = (NativeCredential)Marshal.PtrToStructure(pCred, typeof(NativeCredential));
            Credential cred = new Credential();
            cred.Type = ncred.Type;
            cred.Flags = ncred.Flags;
            cred.Persist = (CRED_PERSIST)ncred.Persist;

            long LastWritten = ncred.LastWritten.dwHighDateTime;
            LastWritten = (LastWritten << 32) + ncred.LastWritten.dwLowDateTime;
            cred.LastWritten = DateTime.FromFileTime(LastWritten);
            cred.UserName = ncred.UserName;
            cred.TargetName = ncred.TargetName;
            cred.TargetAlias = ncred.TargetAlias;
            cred.Comment = ncred.Comment;
            cred.CredentialBlobSize = ncred.CredentialBlobSize;
            
            if (0 < ncred.CredentialBlobSize)
            {
                cred.CredentialBlob = Marshal.PtrToStringUni(ncred.CredentialBlob, (int)ncred.CredentialBlobSize / 2);
            }

            return cred;
        }

        public Credential GetCredential()
        {
            if (IsInvalid)
            {
                throw new InvalidOperationException("Invalid CriticalHandle!");
            }
            Credential cred = TranslateNativeCred(handle);
            return cred;
        }



        public Credential[] GetCredentials(int count)
        {
            if (IsInvalid)
            {
                throw new InvalidOperationException("Invalid CriticalHandle!");
            }

            Credential[] Credentials = new Credential[count];
            IntPtr pTemp = IntPtr.Zero;
            for (int inx = 0; inx < count; inx++)
            {
                pTemp = Marshal.ReadIntPtr(handle, inx * IntPtr.Size);
                Credential cred = TranslateNativeCred(pTemp);
                Credentials[inx] = cred;
            }
            return Credentials;
        }

        override protected bool ReleaseHandle()
        {
            if (IsInvalid)
            {
                return false;
            }
            //CredFree(handle);
            SetHandleAsInvalid();
            return true;
        }
    }

    //-- wrapper for CredEnumerate() winAPI 
    public class CredEnumerator {

        //-- Defining some of the types we will use for this code

        [DllImport("Advapi32.dll", SetLastError = true, EntryPoint = "CredEnumerate")]
        public static extern bool CredEnumerate([In] string Filter, [In] int Flags, out int Count, out IntPtr CredentialPtr);        

        public static Credential[] CredEnumApi(string Filter)
        {
            int count = 0;
            int Flags = 0x0;
            IntPtr pCredentials = IntPtr.Zero;

            if (string.IsNullOrEmpty(Filter) || "*" == Filter)
            {
                Filter = null;
                if (6 <= Environment.OSVersion.Version.Major)
                {
                    Flags = 0x1; //CRED_ENUMERATE_ALL_CREDENTIALS; only valid is OS >= Vista
                }
            }

            if (CredEnumerate(Filter, Flags, out count, out pCredentials))
            {
                //--allocate credentials array
                CriticalCredentialHandle CredHandle = new CriticalCredentialHandle(pCredentials);
                Credential[] Credentials = new Credential[count];
                

                Credentials = CredHandle.GetCredentials(count);

                for (int inx = 0; inx < count; inx++)
                {
                    Credential curr = Credentials[inx];                
                }                 
                return Credentials;
            }

            return null; 
        }

    } //-- end of public class CredEnumerator 

} //-- end of namespace CredEnum 
'@

    $CRED_MANAGER_CREDS_LST = @()

    try {
        # Attempt to create an instance of this class
        Compile-CSharp $CredEnumWrapperClass            
    }
    catch {
        Write-LogFileEntry "Error during compilation. $error " | Out-Null
        $error.clear()
        return $CRED_MANAGER_CREDS_LST
    }

    $Results = [CredEnum.CredEnumerator]::CredEnumApi("")
    foreach ($credentry in $Results) 
    {
        $HostName = $credentry.TargetName
        $HostName = $HostName.ToLower()
        $ServiceName = $credentry.Type
        $UserName = $credentry.UserName
        $DomainName = ""
        $includethis = $True

        try 
        {
            if ($HostName -match "termsrv/") {                  
                $HostName = $HostName.Substring($HostName.IndexOf("termsrv/"))                  
                $ServiceName = "RDP"    
                $includethis = $True       
            }
            elseif ( ($HostName -match "http://(.*)") -or ($HostName -match "https://(.*)")) {
                $HostName = $matches[1] 
                $ServiceName = "HTTP"      
                $includethis = $True            
            }
            elseif ($HostName -match "ftp://(.*)") {
                $HostName = $matches[1] 
                $ServiceName = "FTP"    
                $includethis = $True       
            }
            elseif ( ($HostName -match "domain:target=(.*)") ) #-or ($HostName -match "legacygeneric:target=(.*)")) {
            {    
                $HostName = $matches[1]   
                $ServiceName = "SMB"       
                $includethis = $True           
            }
            elseif ( ($HostName -match "microsoftoffice(.*)") ) #-or ($HostName -match "legacygeneric:target=(.*)")) {
            {
                $ServiceName = "Outlook"                     
                $includethis = $True           
            }
            else {
                $HostName = $credentry.TargetName
                $ServiceName = $($credentry.Type)
                $includethis = $true
            }

            if ($credentry.UserName -match "@(.*)") {
                $DomainName = $matches[1]
                $UserName = $UserName.Substring(0, $UserName.IndexOf("@"))
            }
            elseif ($credentry.UserName -match "\\(.*)") {
                $DomainName = $UserName.Substring(0, $UserName.IndexOf("\\"))
                $UserName = $matches[1]
            }
            else {
                $UserName = $($credentry.UserName)
                $DomainName = ""
            }

            if ($credentry.CredentialBlob -match "^.{1,20}$") {
                $Password = $credentry.CredentialBlob
            }
            else { 
                $Password = ""
            }

            if (($includethis -eq $true) -and (![string]::IsNullOrEmpty($UserName))) {
                $obj = New-Object PSObject                
                Add-Member -inputObject $obj -memberType NoteProperty -name "Username" -value "$($credentry.UserName)"
                Add-Member -inputObject $obj -memberType NoteProperty -name "Domain" -value "$DomainName"
                Add-Member -inputObject $obj -memberType NoteProperty -name "Hostname" -value "$HostName" # need to be sanitised
                Add-Member -inputObject $obj -memberType NoteProperty -name "Password" -value "$Password"
                $CRED_MANAGER_CREDS_LST += $obj 
            }
        }
        catch {
            Write-LogFileEntry "Unexpected Exception!"
        }                   

    }

    return $CRED_MANAGER_CREDS_LST
} 
    
#Sample Usage:
#Get-PasswordVaultCredentials
#Get-CredManCreds
