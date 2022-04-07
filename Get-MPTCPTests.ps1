<#
.SYNOPSIS 
    Lists the TCP Port Controls in SCOM with the related watchers and tcp tests configured.
.DESCRIPTION 
    Gets Lists the TCP Port Controls in SCOM with the related watchers and tcp tests configured.
.EXAMPLE 
    .\Get-MPTCPTests.ps1 -XMlPath '.\TcpPort\CONTISI.TCPPORT.MP.xml' -Verbose | Export-Csv -Path .\TcpPortReport.csv

    VERBOSE: [07/04/2022 11:48:20] Script Started.
    VERBOSE: [07/04/2022 11:48:22] Sucessfully imported '.\TcpPort\CONTISI.TCPPORT.MP.xml'. MPVersion: 1.0.0.0
    VERBOSE: [07/04/2022 11:48:22] 348 TcpPort Control found in management pack.
    VERBOSE: [07/04/2022 11:49:03] Script ended. Duration: 43 seconds.
.EXAMPLE
    .\Get-MPTCPTests.ps1 -XMlPath '.\TcpPort\CONTOSO.TCPPORT.MP.xml' -Verbose | where {$_.Port -eq 80}              

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
#>
[Cmdletbinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-path $_})]
    [string]$XMlPath
)
Function Get-TCPPortClass {
    [Cmdletbinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$MPXML
    )
    $Classes = $MPXML.ManagementPack.TypeDefinitions.EntityTypes.ClassTypes.ClassType | Where-Object {$_.Base -match 'Microsoft\.SystemCenter\.SyntheticTransactions\.TCPPortCheckPerspective$'}     
    Write-Verbose "[$(Get-Date -Format G)] $($Classes.Count) TcpPort Control found in management pack."
    $Classes
}
Function Get-DisplayString {
    [CmdletBinding()]
    Param(        
    [Parameter(Mandatory = $true)]
    [String]$ClassID,
    [Parameter(Mandatory = $true)]
    [System.Xml.XmlDocument]$MPXML
    )
    (($MPXML.ManagementPack.LanguagePacks.LanguagePack | Where-Object {$_.Id -eq 'Enu'}).DisplayStrings.DisplayString | Where-Object {$_.ElementID -eq $ClassID}).Name
}
Function Get-ElementGuid {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$Class
    )
    if ($Class.ID -match 'TCPPortCheck_(?<ElementGuid>\S+)$')
    {
        $Matches['ElementGuid']
    } else {
        Write-verbose "Could not get ElementGuid of class '$($Class.ID)'."
    }

}
Function Get-TCPProbeSettings {
    [CmdletBinding()]
    Param(
        [string]$ElementGuid,
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$MPXML
    )
    $DataSourceModuleType = $MPXML.ManagementPack.TypeDefinitions.ModuleTypes.DataSourceModuleType | where-object {$_.ID -eq "TCPPortCheck_$ElementGUID.TCPPortCheckDataSource"}
    $DataSourceModuleType.ModuleImplementation.Composite.MemberModules.ProbeAction
}
Function Get-TCPWatchers {
    [CmdletBinding()]
    Param(
        [string]$ElementGuid,
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$MPXML
    )
    $Discovery = $MPXML.ManagementPack.Monitoring.Discoveries.Discovery | where-object {$_.ID -eq "TCPPortCheck_$ElementGUID.Discovery.Rule"}
    $Discovery.DataSource.WatcherComputersList
}
#region Script Main
$StartTime = Get-Date
Write-Verbose "[$(Get-Date -Format G)] Script Started."
try {
$MPXML = [Xml](Get-Content -Path $XMlPath -ErrorAction Stop)
Write-Verbose "[$(Get-Date -Format G)] Sucessfully imported '$XmlPath'. MPVersion: $($MPXML.ManagementPack.Manifest.Identity.Version)"
}
Catch {
    throw "Could not open file '$XmlPath'. Error: $($_.Exception.Message)"
}

$Classes = Get-TCPPortClass -MPXML $MPXML
Foreach ($Class in $Classes ) {
    $ElementGuid = Get-ElementGuid -Class $Class
    $TCPProbeSettings = Get-TCPProbeSettings -ElementGuid $ElementGuid -MPXML $MPXML
    [PSCustomObject] @{
        DisplayName = Get-DisplayString -ClassID $Class.Id -MPXML $MPXML
        Port = [int32]$TCPProbeSettings.Port
        ServerName = $TCPProbeSettings.ServerName
        Watchers = Get-TCPWatchers -ElementGuid $ElementGuid -MPXML $MPXML
    }


}
$ScriptDurationSeconds = [Math]::Round(((Get-Date) - $StartTime).TotalSeconds)
Write-Verbose "[$(Get-Date -Format G)] Script ended. Duration: $ScriptDurationSeconds seconds."
#endregion