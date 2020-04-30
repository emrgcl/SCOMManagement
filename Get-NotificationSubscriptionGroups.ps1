<#
.Synopsis
    Lists notification subscriptions and the groups those used within the notifications.
.Description
    Lists notification subscriptions and the groups those used within the notifications.
.Example
    PS C:\scripts> .\Get-NotificationSubscriptionGroups.ps1 -ManagementServer 'SCOMMS1'

    Subscription                              Group                               GroupID                             
    ------------                              -----                               -------                             
    Send Email to SysAdmin                    Critical Servers Group              3a7fa424-56db-7e5d-cfdb-2deeb9e57fa8
    Send SMS to VIP                           Critical Servers Group              11b7b635-ff37-4d2e-131a-4df639db41d4
    Send only Critical Email to Managers      VIP Interested Servers Group        272a6005-f717-e1f8-87c8-74a7b8ffafe0

.Example
    PS C:\scripts> .\Get-NotificationSubscriptionGroups.ps1 -ManagementServer 'SCOMMS1' | where {$_.Group -eq 'N/A'}

    Subscription                                Group    GroupID                             
    ------------                                -----    -------                             
    Send Email to SysAdmin                      N/A      11b7b635-ff37-4d2e-131a-4df639db41d4
    Send SMS to VIP                             N/A      f582c12e-ddc4-3278-3f47-162b2d58c7e1
    Send only Critical Email to Managers        N/A      09d2fc7e-743a-0842-da52-663862306dfe


    The above example finds orphaned ObjectIDs those needs to removed from the notification

#>


[CmdletBinding()]
Param(
 [Parameter(Mandatory=$true)]
 [string]$ManagementServer
)
#Requires -Modules 'OperationsManager'

Import-Module OperationsManager
if(-not (Get-SCOMManagementGroupConnection)) {

try {

New-SCOMManagementGroupConnection -ComputerName $ManagementServer -ErrorAction stop

} catch {


throw "Could not connect to $ManagementServer. Error: $($_.Exception.Message)"

}
}

$SCOMNotificationSubscriptions= Get-SCOMNotificationSubscription 
ForEach ($SCOMNotificationSubscription in $SCOMNotificationSubscriptions) {

    $MonitoringObjectGroupIds=$SCOMNotificationSubscription.Configuration.MonitoringObjectGroupIds

        foreach ($MonitoringObjectGroupId in $MonitoringObjectGroupIds) {
            
            try {
            
            $Group = Get-SCOMGroup -ID $MonitoringObjectGroupId -ErrorAction stop
            
            }           
            Catch [ValidationMetadataException] {
            
            $GroupState = $false
            Write-error "Group does not exist. ID=$MonitoringObjectGroupId. Error: $($_.Exception.Message)"

            }
            Catch {
            
            $GroupState = $false
            Write-error "Could not Get-Group. ID=$MonitoringObjectGroupId. Error: $($_.Exception.Message)"
            
            }

            [PSCustomObject]@{

                    Subscription = $SCOMNotificationSubscription.DisplayName
                    Group = if([string]::IsNullOrEmpty($Group.DisplayName) -or $GroupState -eq $false){'N/A'} else {$Group.DisplayName}
                    GroupID = $MonitoringObjectGroupId
             }
        }
        
}








