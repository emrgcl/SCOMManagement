<#
.Synopsis
   Gets scom rest alerts for exporting to third party systems.
.DESCRIPTION
   Gets scom rest alerts for exporting to third party systems.
.EXAMPLE
   .\Get-SCOMRestAlerts.ps1 -ManagementServer $env:COMPUTERNAME -Verbose
    
    VERBOSE: Authentication URL = http://SCOM/OperationsManager/authenticate
    VERBOSE: Token from the webssion = SCOM-CSRF-TOKEN=5jtpzpbbqZ9vIkBLM893DR_u6LvWTC-vECiSqMyM3jsi1viQMcXXKgI96EeAn-eMqkmL-5xh-V5RKDdbDwSPhwcUrMf7etptw1emnWt5XwE1%3aN6u7vu4vmiLLjbvMRzpSe-1GE2JgD6yDFScj99-J
    vm1q4AIYKMnUW2yOcs8hrTMaeKvq78Mtm5HseMv2sJxdlTnQbE6UW5uYxzTzwUajQFVBPE2_Y1KE2GhXYgJ_6fok0
    VERBOSE: POST http://scom/OperationsManager/authenticate with -1-byte payload
    VERBOSE: received 90-byte response of content type application/json; charset=utf-8
    VERBOSE: Current authentication will last for 24 hours.
    VERBOSE: POST http://scom/OperationsManager/data/alert with -1-byte payload
    VERBOSE: received 4004-byte response of content type application/json; charset=utf-8
    VERBOSE: 2 number of alerts returned.

    id                          : 13d4ad97-8b60-40a3-b38e-934819111e96
    severity                    : Error
    monitoringobjectdisplayname : WS1
    monitoringobjectpath        : web03.contoso.com
    name                        : Could not connect to Log Analytics Workspace
    age                         : 23 days, 21 hours
    ageinmilliseconds           : 2064774165.8838
    description                 : Could not connect to the following workspace.
                                              WorkspaceID: 14943d3b-6e39-40e2-9bac-dd3d1195aeca
                                              StatusText: DNS name resolution of the Microsoft Operations Management Suite service failed. This could be due to either the Workspace ID being configured 
                                  incorrectly, or the agent not having Internet access. Please check that the system either has Internet access, or that a valid HTTP proxy has been configured for the 
                                  agent.
    owner                       : 
    timeadded                   : 2021-04-12T11:03:44.2100000Z
    repeatcount                 : 0
    netbioscomputername         : web03
    netbiosdomainname           : CONTOSO
    ismonitoralert              : True

    id                          : f308e471-a7e0-4dd8-bc28-a709ef6ee653
    severity                    : Error
    monitoringobjectdisplayname : web01.contoso.com
    monitoringobjectpath        : Microsoft.SystemCenter.AgentWatchersGroup
    name                        : Failed to Connect to Computer
    age                         : 99 days, 6 hours
    ageinmilliseconds           : 8575594818.8838005
    description                 : The computer web01.contoso.com was not accessible.
    owner                       : 
    timeadded                   : 2021-01-27T03:30:03.6370000Z
    repeatcount                 : 0
    netbioscomputername         : 
    netbiosdomainname           : 
    ismonitoralert              : True


#>
Param(

    [Parameter(Mandatory = $true)]
    [string]$ManagementServer,
    [ValidateSet('New','Closed','All')]
    $ResolutionState,
    [pscredential]$Credential

)

$Starttime = Get-Date
# Set the Header and the Body
$SCOMHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SCOMHeaders.Add('Content-Type', 'application/json; charset=utf-8')
$BodyRaw = "Windows"
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyRaw)
$EncodedText = [Convert]::ToBase64String($Bytes)
$JSONBody = $EncodedText | ConvertTo-Json
 
# The SCOM REST API authentication URL
$URIBase = "http://$ManagementServer/OperationsManager/authenticate"
Write-Verbose "Authentication URL = $URIBase"
 
$AuthenticationParams = @{

    Method = 'Post'
    Uri = $URIBase
    Headers = $SCOMHeaders
    Body = $JSONBody
    SessionVariable = 'WebSesion'
    ErrorAction = 'Stop'

}

if ($Credential -and $Credential -is [pscredential]) {

    $AuthenticationParams.Add('Credential',$Credential)

} else {

    $AuthenticationParams.Add('UseDefaultCredentials',$true)
    
}

try {

    # Authentication
    $Authentication = Invoke-RestMethod @AuthenticationParams
    # Initiate the Cross-Site Request Forgery (CSRF) token, this is to prevent CSRF attacks
    $CSRFtoken = $WebSession.Cookies.GetCookies($URIBase) | Where-Object { $_.Name -eq 'SCOM-CSRF-TOKEN' }
    Write-Verbose "Token from the webssion = $($CSRFtoken.Value)"
    $SCOMHeaders.Add('SCOM-CSRF-TOKEN', [System.Web.HttpUtility]::UrlDecode($CSRFtoken.Value))

}
Catch {

    throw "Could not authenticate, Exiting. Error: $($_.Exception.Message)"

}
$TokenLifeTimeHours = [Math]::Round((([datetime]::Parse( $Authentication.expiryTime))  - (Get-Date)).TotalHours,2)
Write-Verbose "Current authentication will last for $TokenLifeTimeHours hours."
# The query which contains the criteria for our alerts
switch ($ResolutionState)
{
    'New' {$Criteria = "(ResolutionState = '0')"}
    'Closed' {$Criteria = "(ResolutionState = '255')"}
    'All' {$Criteria = "(ResolutionState = '0') or (ResolutionState = '255')"}
    Default {$Criteria = "(ResolutionState = '0') or (ResolutionState = '255')"}
}
$Query = @(@{         
        
        'classId' = ''
        # Get all alerts with severity '2' (critical) and resolutionstate '0' (new)
        'criteria' = $Criteria
        'displayColumns' ='severity','monitoringobjectdisplayname','monitoringobjectpath','name','age','description','owner','timeadded','repeatcount','netbioscomputername','netbiosdomainname','ismonitoralert','resolutionstate'
})
 
# Convert our query to JSON format
$JSONQuery = $Query | ConvertTo-Json
 
$Response = Invoke-RestMethod -Uri "http://$ManagementServer/OperationsManager/data/alert" -Method Post -Body $JSONQuery -ContentType "application/json" -Headers $SCOMHeaders -WebSession $WebSession
 
# Print out the alert results
$Alerts = $Response.Rows
Write-Verbose "$($Alerts.Count) number of alerts returned."
$Alerts

$ScriptDurationSeconds = [Math]::Round(((Get-Date) - $Starttime).TotalSeconds)
Write-Verbose "Script ended. Duration $ScriptDurationSeconds seconds."