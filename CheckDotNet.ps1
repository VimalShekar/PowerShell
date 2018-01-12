. .\FileLogging.ps1

Function IsDotNet35orGreater {   
    # Check if .NET version 3.5 or greater is present
    [bool] $bVersionPresent = $false

    $Frameworks = Get-ChildItem "HKLM:\Software\Microsoft\NET Framework Setup\NDP"
    foreach($FWver in $Frameworks) {                
        # if it matches v[0-9].+ and is >= v3.5 then requisite is met
        if(($FWver.PSChildName -match "v[0-9].+") -and  ($FWver.PSChildName -ge "v3.5")) 
        { 
            Write-LogFileEntry "IsDotNet35orGreater: $($FWver.PSChildName) is present " | Out-Null
            $bVersionPresent = $true
            break
        }
        else 
        {
            Write-LogFileEntry "IsDotNet35orGreater: $($FWver.PSChildName) is not .NET 3.5. Checking next higher version." | Out-Null
        }
    }

    Write-LogFileEntry "IsDotNet35orGreater: .NET 3.5 Pre-requisite checker returned $bVersionPresent." | Out-Null
    return $bVersionPresent
}


Function IsDotNet2orGreater {   
    # Check if .NET version 2.0 or greater is present
    [bool] $bVersionPresent = $false

    $Frameworks = Get-ChildItem "HKLM:\Software\Microsoft\NET Framework Setup\NDP"
    foreach($FWver in $Frameworks) {                
        # if it matches v[0-9].+ and is >= v2.0 then requisite is met
        if(($FWver.PSChildName -match "v[0-9].+") -and  ($FWver.PSChildName -ge "v2.0")) 
        { 
            Write-LogFileEntry "IsDotNet2orGreater: $($FWver.PSChildName) is present " | Out-Null
            $bVersionPresent = $true
            break
        }
        else 
        {
            Write-LogFileEntry "IsDotNet2orGreater: $($FWver.PSChildName) is not .NET 3.5. Checking next higher version." | Out-Null
        }
    }

    Write-LogFileEntry "IsDotNet2orGreater: .NET 2.0 checker returned $bVersionPresent." | Out-Null
    return $bVersionPresent
}

