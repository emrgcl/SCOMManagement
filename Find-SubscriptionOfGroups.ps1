<#
.Synopsis
    Finds the Notification subscriptions referring to the groups specified.
.Description
    Finds the Notification subscriptions referring to the groups specified.
.Example
    PS C:\scripts> .\Find-SubscriptionOfGroups.ps1 -ManagementServer 'SCOMMS1' -GroupDisplayName 'Critical Servers Group','VIP Interested Servers Group'

    Subscription                                 Group                       
    ------------                                 -----                       
    Send Email to SysAdmin                       Critical Servers Group
    Send only Critical Email to Managers         Critical Servers Group
    Send SMS to VIP                              VIP Interested Servers Group

.Example
    PS C:\scripts> 'Critical Servers Group','VIP Interested Servers Group' | .\Find-SubscriptionOfGroups.ps1 -ManagementServer 'SCOMMS1'

    Subscription                                 Group                       
    ------------                                 -----                       
    Send Email to SysAdmin                       Critical Servers Group
    Send only Critical Email to Managers         Critical Servers Group
    Send SMS to VIP                              VIP Interested Servers Group


#>
[CmdletBinding()]
Param(
 [Parameter(Mandatory=$true)]
 [string]$ManagementServer,
 [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
 [string[]]$GroupDisplayName
)
#Requires -Modules 'OperationsManager'
Begin {
Import-Module OperationsManager
if(-not (Get-SCOMManagementGroupConnection)) {

try {

New-SCOMManagementGroupConnection -ComputerName $ManagementServer -ErrorAction stop

} catch {


throw "Could not connect to $ManagementServer. Error: $($_.Exception.Message)"

}
}
}
Process {

$Groups=Get-SCOMGroup -DisplayName $GroupDisplayName
Foreach ($group in $Groups) {

(Get-SCOMNotificationSubscription | where{$_.Configuration.MonitoringObjectGroupIds -contains $Group.ID}).DisplayName | ForEach-Object {

[PSCustomObject]@{

Subscription = $_
Group = $Group.DisplayName

}
}

}

}