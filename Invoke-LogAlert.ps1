<#
.Synopsis
    Script to create an event log for Log file analysis
.Description
    Script to create an event log for Log file analysis
.Example
    
    Invoke-LogAlert.ps1 -verbose -ContentPath C:\temp\log3.txt -Alertname 'Everything is sth happened' -EventID 1005 -Source 'CustomScom'

    VERBOSE: 12/21/2020 5:30:37 PM Script Started.
    VERBOSE: 12/21/2020 5:30:37 PM hash from previous run has been found. Hash: EFE3FDCBF91BA7CC245890344E3517F5
    VERBOSE: 12/21/2020 5:30:37 PM Number Lines = 4254.
    VERBOSE: 12/21/2020 5:30:37 PM Found previous read with hash = EFE3FDCBF91BA7CC245890344E3517F5, Line = 4254. Exiting loop.
    VERBOSE: 12/21/2020 5:30:37 PM Number Events Caught = 0.
    VERBOSE: 12/21/2020 5:30:37 PM Script ended in 0 seconds.

#>                                                                                                                                                          
[CmdLetBinding()]
Param(
[string]$ContentPath = 'C:\temp\log3.txt',
[string]$ErrorRegex = 'Switching\sfrom\snormal\smode\sto\sBusiness\sContinuity',
[string]$SuccessRegex = 'Switching\sfrom\sbusiness\scontinuity\sto\snormal\smode',
[string]$LastErrorHashPath = "$($env:TEMP)\LastErrorHash.txt",
[Parameter(Mandatory = $true)]
[string]$Alertname,
[int32]$EventID,
[string]$Source
 

)

Function Get-StringHash {

    [CmdletBinding()]
    Param(
    
        [Parameter(Mandatory =$true,ValueFromPipeLine = $true)]
        [string]$String
    
    )

Process {

    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding
    $hash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($String)))
    $hash -replace '-',''

}

}

Function Get-DateFromString {

[CmdletBinding()]
Param(


[Parameter(Mandatory = $true,ValueFromPipeLine = $true)]
[string]$DateString,
[int32]$LCID =1033

)

process {
$Culture =[System.Globalization.CultureInfo]::New($LCID)
#$DateString1 = "2020-12-18 00:00:00.461"
$FormatString = "yyyy-MM-dd HH:mm:ss.fff 'GMT'K"
[Datetime]::ParseExact($DateString,$FormatSTring,$null)

}
}

Function Get-DateString {

[CmdletBinding()]
Param(

[Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
[string]$Line

)

Process {

if ($Line -match '^\S+\s"(?<DateTime>.+)"\s\s') {


$Matches['DateTime']

}


}
}

Function Get-LastEvents {
[CmdLetBinding()]
Param(

[Parameter(Mandatory = $true)]
[string[]]$Content
)

$LastLineIndex = $Content.IndexOf($Content[-1])

Write-Verbose "$(Get-Date -Format G) Number Lines = $($LastLineIndex + 1)." 

for ($i=$LastLineIndex;$i -ge 0;$i--) {
    
    $CurrentHash = $Content[$i] | Get-StringHash
    $DateSTring = $Content[$i] | Get-DateString 
    if ($LastErrorHash -eq $CurrentHash) {
    Write-Verbose "$(Get-Date -Format G) Found previous read with hash = $LastErrorHash, Line = $($i+1). Exiting loop." 
    Break;
    
    } 

    else {

        if($Content[$i] -match $ErrorRegex) {
    
        [PSCustomObject]@{
    
            Status = 'Error'
            Content = $Content[$i]
            Date = Get-DateFromString -DateString $DateString -LCID 1033
            LineHash = $CurrentHash
            Line = $i+1
    
    
        }
    
        } elseif ($Content[$i] -match $SuccessRegex) {
    
        [PSCustomObject]@{
    
            Status = 'Success'
            Content = $Content[$i]
            Date = Get-DateFromString -DateString $DateString
            LineHash = $CurrentHash
            Line = $i+1
        
        }

        }
    }
}



}

Function Write-CustomEvent {

[CmdletBinding()]
Param(

[String]$LogName,
[String]$Message,
[int32]$EventID,
[string]$Source,
[ValidateSet("Information", "Error", "FailureAudit","SuccessAudit","Warning")]
[string]$EntryType = 'Information'

)
if (![System.Diagnostics.EventLog]::SourceExists($Source)) {
New-EventLog -Source $Source -LogName $LogName
}
Write-EventLog -LogName $LogName -EntryType $EntryType -EventId $EventID -Source $Source -Message $Message


}

$start = Get-Date
Write-Verbose "$(Get-Date -Format G) Script Started." 
# initialize variables

$Content = Get-Content -Path $ContentPath
$LastErrorHash = get-content -path $LastErrorHashPath -ErrorAction SilentlyContinue
if ($LastErrorHash) {

Write-Verbose "$(Get-Date -Format G) hash from previous run has been found. Hash: $LastErrorHash"

}

$LastEvents = @(Get-LastEvents -Content $Content)

$NumberofEventsCaught = $($LastEvents.Count)
Write-Verbose "$(Get-Date -Format G) Number Events Caught = $NumberofEventsCaught." 

if($NumberofEventsCaught -gt 0) {
    $LastError = $LastEvents.Where({$_.Status -eq 'Error'}) | Sort-Object -Property Date -Descending | Select-Object -First 1
    Write-Verbose "$(Get-Date -Format G) LastErrorDate: $($LastError.Date)"

    $LastSuccess = $LastEvents.Where({$_.Status -eq 'Success'}) | Sort-Object -Property Date -Descending | Select-Object -First 1
    Write-Verbose "$(Get-Date -Format G) LastSuccessDate: $($LastSuccess.Date)"

    try {
    $ErorStateDurationSeconds = [Math]::Round(((Get-date) - $LastError.Date).TotalSeconds)
    Write-Verbose "$(Get-Date -Format G) Last error is  $ErorStateDurationSeconds Seconds old." 
    }
    Catch {
    
    $ErorStateDurationSeconds = 0
    
    }

    if ($LastSuccessDate -le $LastError.Date -and $ErorStateDurationSeconds -gt 60)  {


        $Message = "Issue: $Alertname`nIssueDate: $($LastError.Date)`nHostname: $($env:COMPUTERNAME)"
        Write-Verbose "$(Get-Date -Format G) $Message"
        Write-EventLog -LogName Application -Message $Message -EventID $EventID -Source $Source -EntryType Error
        $LastError.LineHash | Out-File -FilePath $LastErrorHashPath -Force

    }
}


$ScriptEnd = ((Get-Date) - $start).Seconds
Write-Verbose "$(Get-Date -Format G) Script ended in $ScriptEnd seconds." 
