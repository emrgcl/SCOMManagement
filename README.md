# SCOMManagement

## Remove-Overrides.ps1
Script to find overrides for the given Reference Alias using Regex and deletes the overrides along with the references if the reference is not used in any other element.

## Find-SubscriptionOfGroups.ps1
Finds the Notification subscriptions referring to the groups specified.

## Get-NotificationSubscriptionGroups.ps1
Lists notification subscriptions and the groups those used within the notifications.

## add-ManagementGroupToOrphanedAgents.ps1
If the Agent is insalled right out of the IMage and is not connected to any management group this script will help in prvosioning the agent to the management server and by default if the management group exists but the management server name is wrong (mistyped before) fixes it. 
