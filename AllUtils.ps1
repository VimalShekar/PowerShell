. .\FileLogging.ps1
. .\CheckDotNet.ps1

if(IsDotNet35orGreater){
    . .\CheckIsUserValid_1.ps1
}
else {
    . .\CheckDotNet.ps1
}

