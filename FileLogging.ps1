<#
.Synopsis
    Logging functions

.DESCRIPTION
    This script contains logging functions. These are often used by my other scripts.
    Author : vimalsh@live.com
#>

$global:gFLScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$global:gLogFilePath = "$global:gFLScriptDir\$($myInvocation.MyCommand)" + "$(get-date -Format 'hhmm_dd_mm_yyyy')" + ".txt"
$global:gPrintToScreen = $false

#
#   Function to set the Global attributes of the Logger such as LogFilePath
#
function Set-LoggerAttribs {
    param (
    # Full path to the log file
    [string] $LogFilePath = $global:gLogFilePath,

    # The directory in which the script is executing
    [string] $ScriptDirectory = $global:gFLScriptDir,

    #Specifies whether to print the logs to the screen
    [switch] $PrintToScreen = $off
    )

    $global:gLogFilePath = $LogFilePath
    $global:gFLScriptDir = $ScriptDirectory
    $global:gPrintToScreen = $PrintToScreen

}


#
# Function to write logging to $gLogFilePath
#
function Write-LogFileEntry {
    param(
    # Message to be printed
    [Parameter(Mandatory=$True, Position=0)] 
    [string] $Message,

    # Error level of the message, default is Info
    [Parameter(Mandatory=$false)]  
    [ValidateSet("Error", "Info", "Warn")]  
    [string]$Level="Info",

    # Whether or not to include the $error variable
    [switch] $IncludeErrorVar,

    # Clears the $error variable after this print
    [switch] $ClearErrorAfterLogging,

    # Do not print message to the screen, just put it in the logs file.
    [switch] $DoNotPrintToScreen = $off
    )

    if (!(Test-Path $global:gLogFilePath))
    { 
        new-item $global:gLogFilePath -type file | out-null 
    }

    try{
        $LogMessage = "$(get-date -Format 'dd/MM/yyyy-hh:mm:ss')::$Level::$($Message)" 
        
        if($DoNotPrintToScreen -or ($global:gPrintToScreen -eq $false) )
        {
            #then dont write to screen, just write to the log file
            $LogMessage | Out-File $global:gLogFilePath -Append
        }
        else
        {
            switch($Level)
            {
                'Error' { 
                    Write-Error $LogMessage 
                    } 
                'Warn' { 
                    Write-Warning $LogMessage 
                    } 
                'Info' { 
                    Write-Verbose $LogMessage
                    }
            }
            Write-Host $LogMessage
            $LogMessage | Out-File $global:gLogFilePath -Append
        }
        
        if($IncludeErrorVar)
        {
            $error | Out-File $global:gLogFilePath -Append        
        }

        if($ClearErrorAfterLogging)
        {
            $error.clear()
        }
    }
    catch
    {
        Write-Host $Message
    }
}
    
    