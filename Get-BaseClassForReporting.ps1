<#
.Synopsis
   Gets base class of the specified object and also the management pack of the base class
.DESCRIPTION
   Gets base class of the specified object and also the management pack of the base class
.EXAMPLE
   Get-SCOMClass -DisplayName 'Mon-ServisIzleme-BNPXE' | Get-Baselass 
 
   Name                                       DisplayName     MPName                                   MPDisplayName          
   ----                                       -----------     ------                                   -------------          
   Microsoft.SystemCenter.OwnProcessNTService Windows Service Microsoft.SystemCenter.NTService.Library Windows Service Library
#>
 
[CmdletBinding()]
Param(
 
[Parameter(ValueFromPipeLine = $true)]
$MonitoringClass
 
)
Process {
Import-Module OperationsManager
 
$BaseClass = $MonitoringClass.GetBaseType()
 
$BaseClass | Select-Object -Property Name,DisplayName, @{Name='MPName';Expression={($_.GetManagementPack()).Name}}, @{Name='MPDisplayName';Expression={($_.GetManagementPack()).DisplayName}} 
 
}
