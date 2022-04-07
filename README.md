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

## Get-MPTCPTests.ps1
Gets Lists the TCP Port Controls in SCOM with the related watchers and tcp tests configured.

```
    PS > .\Get-MPTCPTests.ps1 -XMlPath '.\TcpPort\CONTOSO.TCPPORT.MP.xml' -Verbose | where {$_.Port -eq 80}

    VERBOSE: [07/04/2022 11:51:37] Script Started.
    VERBOSE: [07/04/2022 11:51:38] Sucessfully imported '.\TcpPort\CONTISI.TCPPORT.MP.xml'. MPVersion: 1.0.0.0
    VERBOSE: [07/04/2022 11:51:38] 348 TcpPort Control found in management pack.

    DisplayName         Port ServerName    Watchers
    -----------         ---- ----------    --------
    CS ETS WS-APP LB 80   80 11.48.111.202 (SERVERDEV001.contoso.com|SERVERDEV002.contoso.com)
    CS CC VTAPPLB 80      80 11.48.15.201  SERVERPRODX04.contoso.com
    CS ATM Issuer LB 80   80 bsatmiss.con… SERVERPRODX26.contoso.com
    CS ATM Issuer1 80     80 11.48.10.39   SERVERPRODX26.contoso.com
    CS ATM Issuer2 80     80 11.48.10.40   SERVERPRODX26.contoso.com
    CS CC TTS1 80         80 11.48.15.108  SERVERPRODX04.contoso.com
    CS CC TTS2 80         80 11.48.15.109  SERVERPRODX04.contoso.com
```

 # TODO

 - update set-scomhslogontype.ps1 to refer to  tmfver.dll autoamtically.
```
 Set objShell = WScript.CreateObject("WScript.Shell")
sngVersion = objShell.RegRead("HKLM\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Setup\InstallDirectory")

Set objFSO = CreateObject("Scripting.FileSystemObject")
fileVer = objFSO.GetFileVersion(sngVersion & "Tools\TMF\" & "OMAgentTraceTMFVer.Dll")
```