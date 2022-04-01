<#
.SYNOPSIS
    Gets the effective configuration for the specified  server instance.
.DESCRIPTION
    Gets the effective configuration for the specified  server instance.
.EXAMPLE
    PS C:\> PS C:\Source\Repos\SCOMManagement> .\Get-SCOMServerEffectiveConfiguration.ps1 -ManagementServer 'scomms1.contoso.com' -ReportPath 'C:\Scom\OutPut' -ServerName 'server1.contoso.com' -Verbose
    VERBOSE: [4/1/2022 2:10:46 PM] Script started.
    VERBOSE: [4/1/2022 2:10:47 PM] Connected to 'scomms1.contoso.com'
    VERBOSE: [4/1/2022 2:15:26 PM] Server Instance 'server1.contoso.com' found. Exporting settings to 'C:\Scom\OutPut\SQLOLTPN3.csv'
    VERBOSE: [4/1/2022 2:15:26 PM] Script Ended. Duration: 280 seconds.
#>
[CmdletBinding()]
Param(
[string]$ManagementServer,
[string]$ReportPath,
[string]$ServerName
)
$ScriptStart = Get-DAte
Write-verbose "[$(Get-DAte -Format G)] Script started."
Import-Module OperationsManager -verbose:$False
$ServerNetbiosName = ($ServerName -split '\.')[0]
$ResultPath = "$ReportPath\$SErverNetbiosName.csv"
if ($Null -eq (Get-SCOMManagementGroupConnection -verbose:$false)) {

Try {
    New-SCOMManagementGroupConnection -ComputerName $ManagementServer -verbose:$False -ErrorAction Stop
    Write-verbose "[$(Get-DAte -Format G)] Connected to '$ManagementServer'"
}
Catch {
    Throw "Could not connect to '$Managementserver'. Error: $($Error[0].Exception.Message)"
}
}
$Server = Get-ScomClass -Name 'Microsoft.Windows.Computer' | Get-SCOMClassInstance | where {$_.Displayname -eq $ServerName}
if ($Null -ne $Server) {
Export-SCOMEffectiveMonitoringConfiguration -Instance $Server -Path $ResultPath -RecurseContainedObjects
Write-verbose "[$(Get-DAte -Format G)] Server Instance '$($Server.DisplayName)' found. Exporting settings to '$ResultPath'"
} else {
    Write-verbose "[$(Get-DAte -Format G)] No Server instance found. Exiting Script."
}
$ScriptDurationSeconds=[Math]::Round(((Get-date) - $ScriptStart).TotalSeconds)
Write-verbose "[$(Get-DAte -Format G)] Script Ended. Duration: $ScriptDurationSeconds seconds."