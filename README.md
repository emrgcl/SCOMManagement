# SCOMManagement

## Remove-Overrides.ps1
Script to find overrides for the given Reference Alias using Regex and deletes the overrides along with the references if the reference is not used in any other element.

## Find-SubscriptionOfGroups.ps1
Finds the Notification subscriptions referring to the groups specified.

## Get-NotificationSubscriptionGroups.ps1
Lists notification subscriptions and the groups those used within the notifications.

## add-ManagementGroupToOrphanedAgents.ps1
If the Agent is insalled right out of the IMage and is not connected to any management group this script will help in prvosioning the agent to the management server and by default if the management group exists but the management server name is wrong (mistyped before) fixes it. 

## Set-SCOMHSLogonType.ps1
Sets scom 2019 agent to work runas accounts with either logon as a service or logon locally rights.
 - Please refer to Kevin Holman at https://kevinholman.com/2019/03/14/security-changes-in-scom-2019-log-on-as-a-service/
 - Plrease refer to Microsoft Documentation at https://docs.microsoft.com/en-us/system-center/scom/enable-service-logon?view=sc-om-2019 .

## Get-SCOMMPOwnProcessNTServiceGroup.ps1
Gets the Group Ids used for Service Monitoring Templates.

 # TODO

 - update set-scomhslogontype.ps1 to refer to  tmfver.dll autoamtically.
```
 Set objShell = WScript.CreateObject("WScript.Shell")
sngVersion = objShell.RegRead("HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\InstallDirectory")

Set objFSO = CreateObject("Scripting.FileSystemObject")
fileVer = objFSO.GetFileVersion(sngVersion & "Tools\TMF\" & "OMAgentTraceTMFVer.Dll")
```