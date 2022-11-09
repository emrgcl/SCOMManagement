Param(
    [Parameter(Mandatory = $true)]
    [string]$WebConsole,
    [Parameter(Mandatory = $true)]
    [string]$ServerName,
    [pscredential]$Credential
)
#region Authenticate
$Starttime = Get-Date
# Set the Header and the Body
$SCOMHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$SCOMHeaders.Add('Content-Type', 'application/json; charset=utf-8')
$BodyRaw = "Windows"
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($BodyRaw)
$EncodedText = [Convert]::ToBase64String($Bytes)
$JSONBody = $EncodedText | ConvertTo-Json
# The SCOM REST API authentication URL
$URIBase = "https://$WebConsole/OperationsManager/authenticate"
Write-Verbose "Authentication URL = $URIBase"
$AuthenticationParams = @{
    Method = 'Post'
    Uri = $URIBase
    Headers = $SCOMHeaders
    Body = $JSONBody
    SessionVariable = 'WebSession'
    ErrorAction = 'Stop'
}
if ($Credential -and $Credential -is [pscredential]) {
    $AuthenticationParams.Add('Credential',$Credential)
    Write-Verbose 'Credentials used adding.'
} else {
    $AuthenticationParams.Add('UseDefaultCredentials',$true)
    Write-Verbose 'Credentials not used, using defaults.'
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
#endreg
# get OBjects
$OBjectsUri = "https://$WebConsole/OperationsManager/data/scomObjects"
$Body = "DisplayName LIKE '%$ServerName%'" | ConvertTo-Json
$Response = Invoke-RestMethod -Uri $OBjectsUri  -Method Post -Body $Body -ContentType "application/json" -Headers $SCOMHeaders -WebSession $WebSession
$WatcherID=$Response.scopeDatas.Where({$_.ClassName -eq 'Health Service Watcher'}).id
$HealthUri = "https://$WebConsole/OperationsManager/data/healthstate/$WatcherID"
$HealthUri = "https://$WebConsole/OperationsManager/data/monitoring/$WatcherID"
$HealthResponse = Invoke-RestMethod -Uri $HealthUri  -Method GET -ContentType "application/json" -Headers $SCOMHeaders -WebSession $WebSession
$HealthResponse.childNodeDatas.where({$_.MonitorName -eq 'System.Health.AvailabilityState'})
# Print out the alert results
$ScriptDurationSeconds = [Math]::Round(((Get-Date) - $Starttime).TotalSeconds)
Write-Verbose "Script ended. Duration $ScriptDurationSeconds seconds."
