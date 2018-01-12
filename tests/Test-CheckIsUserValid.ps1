# dot source the file to be included here. 
# Note that you have to execute the test scripts from the tests folder for this to work
. ..\CheckIsUserValid.ps1

Set-LoggerAttribs -LogFilePath (".\mylog" + "$(get-date -Format 'hhmm_dd_mm_yyyy')" + ".txt")
Write-LogFileEntry "testing if local username and password is valid"
IsLocalUserNamePasswordValid -UserName TestLocalUser1 -Password Test@Pass1

Write-LogFileEntry "testing if local username and password is valid"
IsDomainUserNamePasswordValid -UserName TestDomUser1 -Password Test@Pass1 -DomainName testdom.local
