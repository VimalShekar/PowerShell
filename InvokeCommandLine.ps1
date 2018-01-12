
<#
.Synopsis
    Executes a given process/command line and returns the exit code or Std output
    
.DESCRIPTION
    Executes a given process/command line and returns the exit code or Std output.
    This function uses System.Diagnostics.Process to launch the process. The plus point of using 
    this class is that the stdout can be captured into a variable and can be printed to a file
    without any loss in formatting.
    Author : vimalsh@live.com

.EXAMPLE
    $output = Invoke-CommandLine -CommandLine "ipconfig" -Arguments "/all" -ReturnStdOut
#>
. .\FileLogging.ps1

Function Invoke-CommandLine 
{
    param(  
        # Executable name or path
        [string]$CommandLine, 

        # Switches or Arguments to be passed
        [string] $Arguments, 

        # If this switch is given, function returns the standard output of the process, else it returns exitcode
        [switch] $ReturnStdOut,

        # Wait time.
        # -1 indicates wait till exit, 0 indicates no wait and any +ve int will be used as wait time in seconds
        [int] $WaitTime = 0 # enter -1, 0 or + integer        
    )
    
    $psExitCode = -1
    $OutVar = ""
    
    Write-LogFileEntry "Invoke-CommandLine: $CommandLine $Arguments" | Out-Null    
    try 
    {        
        $ps = new-object System.Diagnostics.Process
        $ps.StartInfo.Filename = $CommandLine
        $ps.StartInfo.Arguments = $Arguments
        $ps.StartInfo.RedirectStandardOutput = $True
        $ps.StartInfo.UseShellExecute = $false
        $ps.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $ps.Start() | Out-Null

        if($WaitTime -ne 0)
        {
            $ps.WaitForExit($WaitTime)
        }

        [string] $OutVar = $ps.StandardOutput.ReadToEnd();
        $psExitCode = $ps.ExitCode

        # Write-LogFileEntry "Invoke-CommandLine returned Exitcode: $($ps.ExitCode)"  | Out-Null
        # Write-LogFileEntry "Output From Command: $OutVar" | Out-Null
    }
    catch {
        Write-LogFileEntry "Invoke-CommandLine: Exception when running process. Details: $($_.Exception.Message)"  | Out-Null
    }

    if($ReturnStdOut)
    {
        return $OutVar
    }
    else {
        return $psExitCode
    }
}
