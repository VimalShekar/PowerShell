# dot source the file to be included here.
. ..\FileLogging.ps1

Set-LoggerAttribs -LogFilePath ".\mylog.txt"

Write-LogFileEntry "hello world"
Write-LogFileEntry "Don't print to screen" -DoNotPrintToScreen

Write-LogFileEntry "hello world, this is an info" -Level Info
Write-LogFileEntry "hello world, this is a warning" -Level Warn


$error.clear()
Write-LogFileEntry "hello world, this is an error" -Level Error
Write-LogFileEntry "Previous error:" -IncludeErrorVar -ClearErrorAfterLogging

