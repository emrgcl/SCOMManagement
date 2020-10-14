<#
.Synopsis
   Script to send SCOM Alert to Teams using noticiation channel in scom.
.DESCRIPTION
   Script to send SCOM Alert to Teams using noticiation channel in scom. Supports retry. By default retries 5 times every 5 seconds.
.EXAMPLE
   PS C:\scripts> .\Send-TeamsMessage.ps1 -Alert 'Name of Test Alert' -Source 'C:' -Priority '5' -Severity '3' -Description 'Test issue occured on server. bla bla bla bla.' -TimeRaisedLocal (Get-Date -Format G).ToString() -Uri 'lşskjdkfsdjflkjdsf' -LogFilePath c:\temp\trytest.txt -Verbose
   VERBOSE: [10/14/2020 1:53:33 PM][Send-TeamsMessage.ps1] Retry number 1: Couldt not send Alert 'Name of Test Alert' from 'C:'. Sleeping 5 seconds. Error: The remote name could not be resolved: 'lşskjdkfsdjflkjdsf'
   VERBOSE: [10/14/2020 1:53:39 PM][Send-TeamsMessage.ps1] Retry number 2: Couldt not send Alert 'Name of Test Alert' from 'C:'. Sleeping 5 seconds. Error: The remote name could not be resolved: 'lşskjdkfsdjflkjdsf'
   VERBOSE: [10/14/2020 1:53:45 PM][Send-TeamsMessage.ps1] Retry number 3: Couldt not send Alert 'Name of Test Alert' from 'C:'. Sleeping 5 seconds. Error: The remote name could not be resolved: 'lşskjdkfsdjflkjdsf'
   VERBOSE: [10/14/2020 1:53:51 PM][Send-TeamsMessage.ps1] Retry number 4: Couldt not send Alert 'Name of Test Alert' from 'C:'. Sleeping 5 seconds. Error: The remote name could not be resolved: 'lşskjdkfsdjflkjdsf'
   VERBOSE: [10/14/2020 1:53:57 PM][Send-TeamsMessage.ps1] Retry number 5: Couldt not send Alert 'Name of Test Alert' from 'C:'. Sleeping 5 seconds. Error: The remote name could not be resolved: 'lşskjdkfsdjflkjdsf'
#>
[CmdletBinding()]
Param(
[string]$Alert,
[string]$Source,
[string]$Description,
[int32]$Severity,
[int32]$Priority,
[string]$TimeRaisedLocal,
[int32]$RetryCount = 5,
[int32]$SleepSeconds = 5,
[string]$LogFilePath = 'c:\Notifications\NotificationLog.txt',
[string]$Uri =  'https://outlook.office.com/webhook/6df4982c-4212-4a63-a9a8-ef63a2207d62@832c1bc9-1e43-4f93-a086-708d36b0c95d/IncomingWebhook/3f6666718a1142d9bad866fbc3fb8cda/d095a22f-62ad-425b-83b3-dddef8b3bb7b'


)
Function Write-Log {

    [CmdletBinding()]
    Param(
    
    
    [Parameter(Mandatory = $True)]
    [string]$Message,
    [string]$LogFilePath = "$env:TEMP"
    
    )
    
    $LogFilePath = if ($Script:LogFilePath) {$Script:LogFilePath}
    
    $Log = "[$(Get-Date -Format G)][$((Get-PSCallStack)[1].Command)] $Message"
    
    Write-verbose $Log
    $Log | Out-File -FilePath $LogFilePath -Append -Force
    

}

$SeverityHash = @{

0 = 'Information'
1 = 'Warning'
2 = 'Critical'

}

$PriorityHash = @{

0 = 'Low'
1 = 'Medium'
2 = 'High'


}


$ThemeColor = switch ($SeverityHash.$Severity)
{
    'Critical' {'D70000'}
    'Warning'  {'FFCC00'}
    'Information' {'9C9C9C'}
    Default {'D70000'}
}


$Text = @"
**Source:** $Source<br/>
**Priority:** $($PriorityHash.$Priority)<br/>
**Severity:** $($SeverityHash.$severity)<br/>
**Raised Time:** $TimeRaisedLocal<br/>
**Alert Description**: $Description<br/>
"@

$JsonHash = [ordered]@{

title = $Alert
text = $Text
}

$JsonCardHash = [ordered]@{
'@type' = 'MessageCard' 
'@context' = 'http://schema.org/extensions' 
themecolor = $ThemeColor
title = $Alert
text = $Text


}

$JsonBody = ConvertTo-Json -InputObject $JsonCardHash

$Count = 0

do {
    
    try {
    
    $Count++
    Invoke-RestMethod -Method Post -Uri $Uri -Body $JsonBody  -ErrorAction Stop -Verbose:$false | Out-Null
    $Sucess = $true
    $Message = "Successfully sent Alert '$Alert' from '$Source' to teams on try $Count."
    
    }
    
    Catch {
    
    $Message = "Retry number $Count`: Couldt not send Alert '$Alert' from '$Source'. Sleeping $SleepSeconds seconds. Error: $($_.Exception.Message)"
    
    
    
    }
    
    Finally {

    Write-Log $Message
    if (-Not $Sucess) {
    
        Start-Sleep -Seconds $SleepSeconds

    }

    }
} until ($Sucess -or ($Count -eq $RetryCount))