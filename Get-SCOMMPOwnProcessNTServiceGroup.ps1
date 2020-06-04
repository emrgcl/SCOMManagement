<#
.Synopsis
    Gets the Group Ids used for Service Monitoring Templates.
.Description
    Gets the Group Ids used for Service Monitoring Templates.
.Example 

    PS C:\> .\Get-SCOMMPOwnProcessNTServiceGroup.ps1 -FilePath C:\Temp\MyServiceMonitorMP.xml -Verbose

    VERBOSE: [6/4/2020 3:06:07 PM] Script started
    VERBOSE: [6/4/2020 3:06:11 PM] Loaded XML.
    VERBOSE: Found 279 Services
    VERBOSE: Found 279 Discoveries
    VERBOSE: Found 279 DiscoveryNodes
    VERBOSE: Found 279 Groups and 3 is Unique.
    6bea6fd8-11f6-46b7-00eb-a9de8e62b95f
    c09f85c8-2e1f-1267-08e9-917f85d2121a
    e952f7c1-6ff0-607b-4217-57287e43ddb8
    VERBOSE: Script Ended. Duration: 14 Seconds

#>
[CmdletBinding()]
Param(

[ValidateScript({Test-Path -Path $_})]
[string]$FilePath

)


Function Get-SCOMMPOwnProcessNTServiceNode {
[CmdletBinding()]
Param(

[System.Xml.XmlDocument]$MPXml

)
($MPXml.ManagementPack.TypeDefinitions.EntityTypes.ClassTypes).ChildNodes | where {$_.Base -match 'Microsoft\.SystemCenter\.OwnProcessNTService'}
}

Function Get-SCOMMPDiscoveryNode {
[CmdletBinding()]
Param(

[Parameter(Mandatory = $true)]
[System.Xml.XmlDocument]$MPXml,

[Parameter(ValueFromPipeLine=$true,ValueFromPipelineByPropertyName=$true,Mandatory = $true)]
[System.Xml.XmlElement]$OwnProcessNTServiceNode

)

Begin {

$DiscoveryNodes = ($MPXml.ManagementPack.Monitoring.Discoveries).ChildNodes

}

Process {

$DiscoveryNodes | where {$_.DiscoveryTypes.DiscoveryClass.TypeID -eq $OwnProcessNTServiceNode.Id }

}

}

Function Get-SCOMMPDiscoveryOverrideNode {
[CmdletBinding()]
Param(

[Parameter(Mandatory = $true)]
[System.Xml.XmlDocument]$MPXml,

[Parameter(ValueFromPipeLine=$true,ValueFromPipelineByPropertyName=$true,Mandatory = $true)]
[System.Xml.XmlElement]$OwnProcessNTServiceDiscoveryNode

)

Begin {

$DiscoveryOverrideNodes = $MPXml.ManagementPack.Monitoring.Overrides.DiscoveryPropertyOverride

}


Process {

$DiscoveryOverrideNodes | where {$_.Discovery -eq $OwnProcessNTServiceDiscoveryNode.Id }

}

}


$ScriptStart = Get-Date
Write-Verbose "[$(Get-Date -Format G)] Script started"

# Get File Content
try {
[xml]$MPXml = Get-Content -Path $FilePath -Encoding Unicode -ErrorAction Stop
Write-Verbose "[$(Get-Date -Format G)] Loaded XML."
} 
Catch {

"Could not load $FilePath. Error: $_.Exception.Message"
throw

}

$OwnProcessNTServiceNodes = Get-SCOMMPOwnProcessNTServiceNode -MPXML $MPXml
Write-Verbose "[$(Get-Date -Format G)] Found $($OwnProcessNTServiceNodes.Count) Services"

$OwnProcessNTServiceDiscoveryNodes = $OwnProcessNTServiceNodes | Get-SCOMMPDiscoveryNode -MPXML $MPXml
Write-Verbose "[$(Get-Date -Format G)] Found $($OwnProcessNTServiceDiscoveryNodes.Count) Discoveries"

$DiscoveryOverrideNodes = $OwnProcessNTServiceDiscoveryNodes | Get-SCOMMPDiscoveryOverrideNode -MPXML $MPXml
Write-Verbose "[$(Get-Date -Format G)] Found $($OwnProcessNTServiceDiscoveryNodes.Count) DiscoveryNodes"

$Groups = $DiscoveryOverrideNodes.ContextInstance 
$UniqueGroups = $Groups | Select-Object -Unique 
Write-Verbose "[$(Get-Date -Format G)] Found $($Groups.Count) Groups and $($UniqueGroups.Count) is Unique."

$UniqueGroups
Write-Verbose "Script Ended. Duration: $([Math]::Round(((Get-Date) - $ScriptStart).TotalSeconds)) Seconds"
