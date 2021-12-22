<#
.Synopsis
   Sets failover servers.
.DESCRIPTION
   Sets failover servers.
.EXAMPLE
   .\Set-EGSCOMFailoverservers.ps1 -Verbose

   VERBOSE: [11/5/2021 11:47:55 AM] Script Started.
   VERBOSE: [11/5/2021 11:47:55 AM] Working on 200 number of Agents.
   VERBOSE: [11/5/2021 11:47:56 AM] 89 agents will be set, PrimaryMS: 'ms1.contoso.com', FailoverServerList: ms2.contoso.com,ms3.contoso.com 
   VERBOSE: Performing the operation "Setting Failover servers where pimary ms is 'ms1.contoso.com'" on target "ms2.contoso.com,ms3.contoso.com".
   VERBOSE: [11/5/2021 11:48:02 AM] 89 agents will be set, PrimaryMS: 'ms2.contoso.com', FailoverServerList: ms1.contoso.com,ms3.contoso.com 
   VERBOSE: Performing the operation "Setting Failover servers where pimary ms is 'ms2.contoso.com'" on target "ms1.contoso.com,ms3.contoso.com".
   VERBOSE: [11/5/2021 11:48:09 AM] 22 agents will be set, PrimaryMS: 'ms3.contoso.com', FailoverServerList: ms2.contoso.com,ms1.contoso.com 
   VERBOSE: Performing the operation "Setting Failover servers where pimary ms is 'ms3.contoso.com'" on target "ms2.contoso.com,ms1.contoso.com".
#>

[CmdletBinding(

     SupportsShouldProcess=$true

)]
Param(

    [string]$ManagementServer = "ms1.contoso.com",
    [String[]]$ServerNamesToDistribute = @('ms1.contoso.com','ms2.contoso.com','ms3.contoso.com')

)
import-module operationsmanager -Verbose:$false


Write-Verbose "[$(Get-Date -Format G )] Script Started."

if(-not (Get-SCOMManagementGroupConnection -verbose:$False)) {
try {
    New-SCOMManagementGroupConnection -ComputerName $ManagementServer -Verbose:$false -ErrorAction Stop| Out-Null
    Write-Verbose "[$(Get-Date -Format G )] Connected to management server, '$ManagementServer'"
}
Catch {

Throw "Could not connect to management server, '$ManagementServer'. Error: $($_.Exception.Message)"

}

}

$Agents = Get-SCOMAgent

Write-Verbose "[$(Get-Date -Format G )] Working on $($Agents.count) number of Agents."

#$PrimaryManagementServerNames = $Agents.PrimaryManagementServerName | Select-Object -Unique
$ManagementServersToDistribute = Get-SCOMManagementServer -Name $ServerNamesToDistribute

Foreach ($PrimaryManagementServer in $ManagementServersToDistribute) {

$PrimaryManagementServerName = $PrimaryManagementServer.DisplayName
$SelectedFailoverServers = $ManagementServersToDistribute | Where-Object {$_.DisplayName -ne $PrimaryManagementServerName}
$SelectedAgents = $Agents | Where-Object {$_.PrimaryManagementServerName -eq $PrimaryManagementServerName}


        if ($pscmdlet.ShouldProcess("$($SelectedFailoverServers.Displayname -join ',')", "Setting Failover servers where pimary ms is '$PrimaryManagementServerName'"))
        {
           Set-SCOMParentManagementServer -Agent $SelectedAgents -FailoverServer $SelectedFailOverservers
        }
}
 
 
