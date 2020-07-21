<#
.Synopsis
   Script to close alerts those are are monitor based by resetting the monitors. 
.DESCRIPTION
   Script to close alerts those are are monitor based by resetting the monitors those alerts are older than the DaysOldParameter. 
.EXAMPLE
   .\Reset-MonitorAlerts.ps1 -Severity Warning -DaysOld 1 -WhatIf
 
   What if: Performing the operation "Resetting State" on target "SQL Server cannot authenticate using Kerberos beca on SQL1".
   What if: Performing the operation "Resetting State" on target "SQL Server cannot authenticate using Kerberos beca on SQL2".
   What if: Performing the operation "Resetting State" on target "SQL Server cannot authenticate using Kerberos beca on SQL3s".
 
#>
[Cmdletbinding(SupportsShouldProcess = $true)]
Param(
 
[ValidateSet('Error', 'Warning', 'Information')]
[string]$Severity,
[int32]$DaysOld=3
 
)
 
Function Truncate-String {
 
Param(
[string]$strTruncate,
[int32]$NumberOfChars
)
 
if ($NumberOfChars -lt $strTruncate.Length) {
 
$strTruncate.Remove($NumberOfChars)
 
} else {$strTruncate}
 
}
 
Import-Module OperationsManager -verbose:$false
$Alerts = Get-SCOMAlert | Where-Object {$_.IsMonitorAlert -eq $true -and $_.ResolutionState -eq 0 -and ((Get-Date) - $_.TimeRaised).TotalDays -gt $DaysOld -and $_.Severity -eq $Severity}
$ResetCount = 0
Write-Verbose -Message "[$(Get-date -Format G)] script started. Number of Alerts to work on $($Alerts.Count)"
 
Foreach ($Alert in $Alerts) {
 
# Get monitor
$monitor = Get-SCOMMonitor -Id ($Alert.MonitoringRuleId.Guid)
 
# Get monitoring object
$monitoringObject = Get-SCOMMonitoringObject -Id ($Alert.MonitoringObjectId)
 
#Create ManagementPackMonitor collection, needed by the GetMonitoringStates method
$MonitorsToReset = New-Object "System.Collections.Generic.List[Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor]";
$MonitorsToReset.Add($monitor)
 
#Get the newest MonitorState
$MonitorState = $monitoringObject.GetMonitoringStates($MonitorsToReset)[0];
 
        if ($pscmdlet.ShouldProcess("$(Truncate-String -NumberOfChars 50 -strTruncate $Alert.Name) on $($Alert.NetbiosComputerName)", "Resetting State"))
        {
            $MonitoringObject.ResetMonitoringState($monitor) | out-null
            ++$ResetCount
            
        }
 
        
 
}
 
Write-Verbose -Message "[$(Get-date -Format G)] script Ended. Number of Alerts to work on $($Alerts.Count)" 
