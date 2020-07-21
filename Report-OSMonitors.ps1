Param(
 
[string]$ComputerName
 
) 
Import-Module OperationsManager
$computers = Get-SCOMClass -Name 'Microsoft.Windows.Computer' | Get-SCOMClassInstance
$computer = $computers | where {$_.DisplayName -eq $ComputerName}
$Monitors = Get-SCOMManagementPack | ? Name -match 'Microsoft\.Windows\.Server\.\d+\.Monitoring' | Get-SCOMMonitor
 
$MonitorList = New-Object "System.Collections.Generic.List[Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor]";
 
$monitors | ForEach-Object {$MonitorList.Add($_)}
 
 
$Objects = $Computer.GetRelatedMonitoringObjects()
$MonitorResult = foreach ($object in $Objects) {
 
$object.GetMonitoringStates($MonitorList)
 
}
 
$MonitoResult | Select-Object -Property MonitorDisplayName, @{Name = 'Object'; Expression=  {(Get-SCOMMonitoringObject -Id ($_.MonitoringObjectId)).DispLayName}}, HealthState 
 
