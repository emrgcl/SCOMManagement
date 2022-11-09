[CmdletBinding(
SupportsShouldProcess=$true
)]
Param(
    $ManagementServer = 'ms1.contoso.local',
    [int32]$DurationMinutes = 60,
    [Parameter(Mandatory=$true)]
    [ValidateSet('PlannedOther','PlannedHardwareMaintenance','PlannedHardwareInstallation','PlannedOperatingSystemReconfiguration','PlannedApplicationMaintenance')]
    [string]$Reason,
    [string]$Comment='CalismaVar',
    [string]$ServerListPath = 'C:\temp\MMServers.txt'
)
try {
Import-Module OperationsManager -ErrorAction stop -verbose:$False
New-SCOMManagementGroupConnection -ComputerName $ManagementServer -ErrorAction Stop
}
Catch {
throw "Couldt not connect to $ManagementServer. Error: $($_.Exception.Message)"
}
$ServerNames = Get-Content $ServerListPath
$Time = (Get-Date).addMinutes($DurationMinutes)
$Instance = @(Get-SCOMClass -Name "Microsoft.Windows.Computer" | Get-SCOMClassInstance | ? { $_.DisplayName -in $ServerNames} )
$Watcher = @(Get-SCOMClass -Name Microsoft.SystemCenter.HealthServiceWatcher | Get-SCOMClassInstance | ? { $_.DisplayName -in $ServerNames} )
$AllOBjects = $Instance + $Watcher
Foreach ($Server in $AllOBjects) {
if ($pscmdlet.ShouldProcess($Server.FullNAme, "Starting maintenance mode for $DurationMinutes minutes"))
{
    #Start-SCOMMaintenanceMode -Instance $Server -EndTime $Time -Comment $Comment -Reason $Reason -
    #$instance.ScheduleMaintenanceMode([datetime]::Now.touniversaltime(),([datetime]::Now).addminutes($windowDuration).touniversaltime(), "$windowReason", "$windowsComment" , "Recursive")
    $Server.ScheduleMaintenanceMode((Get-DAte).ToUniversalTime(),$Time.ToUniversalTime() , $Reason, $Comment , "Recursive")
}
}
