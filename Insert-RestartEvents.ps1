 <#
.Synopsis
   Inserts selected scom events to custom database
.DESCRIPTION
   Inserts selected scom events to custom database
.EXAMPLE
   .\Insert-RestartEvents -SQLServer 'opwscomdb1' -Instance 'default,1977' -Database 'SCOMDashboard' -TableName 'RestartEvents' -Verbose
    
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
[string]$ManagementServer = 'OvwScomMng1.kfs.local'
) 


$ScriptStart = Get-date
$SelectTableName = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG='$database' and TABLE_NAME = '$TableName'"

 
Write-Verbose "[$(Get-Date -Format G)] Script Started."

Import-module OperationsManager -Verbose:$false
Import-Module SqlServer -Verbose:$false

# Connect to Management Server

try {

   New-SCOMManagementGroupConnection -ComputerName $ManagementServer -ErrorAction Stop

 
} Catch {

    throw "Could not connect to $ManagementServer. Error. $($_.Exception.Message)"

}


# Collect Events
$event = Get-SCOMEvent

$Rules = Get-SCOMManagementPack | where {$_.Name -match 'Microsoft\.Windows\.Server\.\d{4}\.Monitoring'} | Get-SCOMRule |where {$_.Name -match '(restart)|(shutdown)'} 
$Events = get-scomevent -Rule $Rules | Select-Object -Property MonitoringObjectName,MonitoringObjectDisplayName,MonitoringObjectPath,MonitoringObjectFullName,MonitoringRuleDisplayName,MonitoringRuleDescription,PublisherName,Number,Description,CategoryId,Category,User,LoggingComputer,TimeGenerated,TimeAdded

# Prepare SQL Server connections

Try {

if((Invoke-Sqlcmd -ServerInstance "$SQLServer\$Instance" -Database $Database -Query $SelectTableName -ErrorAction stop)) {

Write-Verbose "[$(Get-date -Format G)]Found $TableName table dropping."

Invoke-Sqlcmd -ServerInstance "$SQLServer\$Instance" -Database $Database -Query "DROP TABLE [dbo].[$TableName]" -ErrorAction Stop

}
} catch {

Throw "[$(Get-Date -Format G)] Select or delete TableName`nError: $($_.Exception.Message)"

}

 
 
try {

New-PSDrive -Name SCOMDashboard -PSProvider 'SQLServer' -root "SQLSERVER:\SQL\$SQLServer\$Instance\Databases\$Database" -ErrorAction stop | Out-Null
cd 'SCOMDashboard:\Tables'
Write-SqlTableData -TableName $TableName -InputData $Events -Force -SchemaName dbo -ErrorAction Stop
Write-Verbose "[$(Get-Date -Format G)] Inserted $($ConvertedEvents.Count) number of Rows in total"

} 
 
Catch {

Throw "[$(Get-Date -Format G)] Couldnt Insert to SQL.`nError: $($_.Exception.Message)"

 
} 
Finally {
cd c:\
Remove-PSDrive SCOMDashboard
}

Write-verbose "[$(Get-date -Format G)] Script ended. Script dutation is $(((Get-date) - $ScriptStart).TotalSeconds)"   
