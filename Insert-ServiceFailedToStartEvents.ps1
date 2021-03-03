<#
.Synopsis
   Inserts selected scom events to custom database
.DESCRIPTION
   Inserts selected scom events to custom database
.EXAMPLE
   .\Insert-ServiceFailedToStartEvents -SQLServer 'opwscomdb1' -Instance 'default,1977' -Database 'SCOMDashboard' -TableName 'ServiceFailedToStartEvents' -Verbose
    
    VERBOSE: [27.04.2020 16:24:51] Script Started.
    WARNING: Using provider context. Server = opwscomdb1\default,1977, Database = [SCOMDashboard].
    VERBOSE: [27.04.2020 16:25:21] Inserted 1691 number of CPU Samples in total
    VERBOSE: [27.04.2020 16:25:21] Script ended.Script dutation is 29.8307143
#>
 
#requires -version 5.1 -Modules OperationsManager
[CmdletBinding()]
Param(
 
[Parameter(Mandatory= $true)]
[string]$SQLServer,
[Parameter(Mandatory= $true)]
[string]$Instance,
[Parameter(Mandatory= $true)]
[string]$Database,
 
[Parameter(Mandatory= $true)]
[string]$TableName,
 
 
[string]$RuleDisplayName = 'Collection rule for Service or Driver Failed to Start events',
[string]$ManagementServer
 
)
 
Class BasicMonitoringEvent 
{
 
    [string]$LoggingComputer
    [string]$MonitoringObjectDisplayName
    [string]$MonitoringObjectPath
    [String]$ServiceDisplayName
    [datetime]$TimeAdded
    [string]$ErrorCode
 
BasicMonitoringEvent() {}
 
BasicMonitoringEvent(
 
    [string]$LoggingComputer ,
    [string]$MonitoringObjectDisplayName,
    [string]$MonitoringObjectPath,
    [String]$ServiceDisplayName,
    [datetime]$TimeAdded,
    [string]$ErrorCode
 
 
){
 
 
    this.LoggingComputer = $LoggingComputer
    this.MonitoringObjectDisplayName = $MonitoringObjectDisplayName
    this.MonitoringObjectPath = $MonitoringObjectPath
    this.ServiceDisplayName = $ServiceDisplayName
    this.TimeAdded = $TimeAdded
    this.ErrorCode = $ErrorCode
 
 
}
 
}
 
 
 
Function Get-EventParameterHash {
 
[CmdletBinding()]
Param(
 
[Parameter(Mandatory = $true)]
[string]$Name,
[Parameter(Mandatory = $true)]
[int32]$ParameterIndex,
[switch]$ResolveErrors
)
 
if ($ResolveErrors) {
 
$Expression = @"
 
               if(`$ErrorHash[`$_.Parameters[$ParameterIndex]]) {
               
               `$ErrorHash[`$_.Parameters[$ParameterIndex]]
 
               } else {
               
               `$_.Parameters[$ParameterIndex]
               
               }
               
"@
 
    @{Name=$Name;Expression=[scriptblock]::Create($Expression)}
 
} else {
 
    @{Name=$Name;Expression=[scriptblock]::Create("`$_.Parameters[$ParameterIndex]")}
}
}
 
$ScriptStart = Get-date
$SelectTableName = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG='$database' and TABLE_NAME = '$TableName'"
$InstanceRoot = "SQLSERVER:\SQL\$SQLServer\$Instance"
$DatabaseRoot = "$InstanceRoot\Databases\$Database" 
 
 
Write-Verbose "[$(Get-Date -Format G)] Script Started."
 
 
try {
 
   New-SCOMManagementGroupConnection -ComputerName $ManagementServer -ErrorAction Stop
 
 
} Catch {
 
    throw "Could not connect to $ManagementServer. Error. $($_.Exception.Message)"
 
}
 
 
 
$ErrorHash =  @{
 
    '%%1331' = 'Account Currently Disabled'
    '%%50' = 'Insufficient Rights'
    '%%1909' = 'The Referenced account is currently locked out and may not be logged on to.'
    '%%8' = 'Not enough memory'
    '%%1326' = 'The User Name and password is incorrect'
    '%%1787' = 'The security database on the server does not have a computer account for this workstation trust relationship'
    '%%1069' = 'The service did not start to due to a logon failure'
    '%%1053' = 'The Service did not respond to the start or control request in a timely fashion'
    '%%2' = 'The system cannot find the file specified.'
    '%%1275' = 'This driver has been blocked from loading'
    '%%1455' = 'The paging file is to small for this operation to complete.'
    '%%3' = 'The system cannot find the path specified.'
 
}
 
$ServiceFailedToStartEventRules = Get-scomrule -DisplayName $RuleDisplayName 
$ServiceFailedToStartEvents = Get-SCOMEvent -Rule $ServiceFailedToStartEventRules
 
#$LogonFailedEvents = $ServiceFailedToStartEvents.where({$_.Number -eq 7038})| Select-Object -Property 'LoggingComputer','MonitoringObjectPath','MonitoringObjectDisplayName','TimeAdded','TimeRaised',(Get-EventParameterHash -Name 'ServiceDisplayname' -ParameterIndex 0),(Get-EventParameterHash -Name 'UserName' -ParameterIndex 0),(Get-EventParameterHash -Name 'ErrorCode' -ParameterIndex 2 -ResolveErrors )
$ServiceStartEvents =$ServiceFailedToStartEvents.where({$_.Number -eq 7000})| Select-Object -Property 'LoggingComputer','MonitoringObjectPath','MonitoringObjectDisplayName','TimeAdded',(Get-EventParameterHash -Name 'ServiceDisplayname' -ParameterIndex 0),(Get-EventParameterHash -Name 'ErrorCode' -ParameterIndex 1 -ResolveErrors )
Write-Verbose "[$(Get-Date -Format G)] Found $($ServiceStartEvents.Count) number of Events in total"
 
#convert custom objects to a proper classs so that we can insert into sql healthy
$ConvertedEvents = $ServiceStartEvents | ForEach-Object {
 
[BasicMonitoringEvent]@{
 
LoggingComputer = $_.LoggingComputer.ToString()
MonitoringObjectDisplayName = $_.MonitoringObjectDisplayName.ToString() 
MonitoringObjectPath = $_.MonitoringObjectPath.ToString()
ServiceDisplayName = $_.ServiceDisplayName.ToString()
TimeAdded = [datetime]$_.TimeAdded
ErrorCode = $_.ErrorCode
 
}
}
 
Write-Verbose "[$(Get-Date -Format G)] Converted Events."
 
# Drop table if it exists, we will create it during insert automatically.
Try {
 
Set-Location -Path $InstanceRoot -ErrorAction Stop
if((Invoke-Sqlcmd -ServerInstance (Get-Item .) -Database $Database -Query $SelectTableName -ErrorAction stop)


) {
 
Write-Verbose "[$(Get-date -Format G)]Found $TableName table dropping."
 
Invoke-Sqlcmd -ServerInstance (Get-Item .) -Database $Database -Query "DROP TABLE [dbo].[$TableName]" -ErrorAction Stop
 
} else {

Write-Verbose "[$(Get-Date -Format G)] $TableName is not found in $Database. Script will create the table"

}
} catch {
 
Throw "[$(Get-Date -Format G)] Select or delete TableName`nError: $($_.Exception.Message)"
 
}
 
 
 
try {
 
New-PSDrive -Name SCOMDashboard -PSProvider 'SQLServer' -root $DatabaseRoot -ErrorAction stop | Out-Null
cd 'SCOMDashboard:\Tables'
Write-SqlTableData -TableName $TableName -InputData $ConvertedEvents -Force -SchemaName dbo -ErrorAction Stop
Write-Verbose "[$(Get-Date -Format G)] Inserted $($ConvertedEvents.Count) number of Rows in total"
 
} 
 
Catch {
 
Throw "[$(Get-Date -Format G)] Couldnt Insert to SQL.`nError: $($_.Exception.Message)"
 
 
} 
Finally {
cd c:\
Remove-PSDrive SCOMDashboard
}
 
Write-verbose "[$(Get-date -Format G)] Script ended. Script dutation is $([Math]::Round(((Get-date) - $ScriptStart).TotalSeconds)) seconds."  
