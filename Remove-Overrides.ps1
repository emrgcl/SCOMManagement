<#

.Synopsis
 Script to find overrides for the given Reference Alias using Regex and deletes the overrides along with the references if the reference is not used in any other element.

.Description
 Script to find overrides for the given Reference Alias using Regex and deletes the overrides along with the references if the reference is not used in any other element.

.Example
    PS C:\scripts> .\Remove-Overrides.ps1 -MPXmlPath 'C:\temp\Microsoft.SystemCenter.OperationsManager.DefaultUser.xml' -AliasRegex 'SQLServer' -Verbose

.Parameter MPXmlPath
    The management pack full path ie. 'C:\temp\Microsoft.SystemCenter.OperationsManager.DefaultUser.xml'
.Parameter AliasRegex
    Regex pattern for alias

#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
[Parameter(Mandatory = $true)]
[string]$MPXmlPath,
[Parameter(Mandatory = $true)]
[string]$AliasRegex
)
Function Get-ReferenceAlias {

[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]
[System.Xml.XmlDocument]$mpxml,
[Parameter(Mandatory=$true)]
[string]$RegexMatchText
)

$mpxml.ManagementPack.Manifest.References.ChildNodes | where {$_.Alias -match $RegexMatchText}

}

Function Get-OverrideType {

[Cmdletbinding()]
Param(

[Parameter(Mandatory = $true)]
[string]$TypeName
)

$OverrideTable = @{

CategoryOverride = 'Category'
MonitoringOverride= 'Monitor'
RuleConfigurationOverride= 'Rule'
RulePropertyOverride= 'Rule'
MonitorConfigurationOverride= 'Monitor'
MonitorPropertyOverride= 'Monitor'
DiagnosticConfigurationOverride= ''
DiagnosticPropertyOverride= 'Diagnostic'
RecoveryConfigurationOverride= 'Recovery'
RecoveryPropertyOverride= 'Recovery'
DiscoveryConfigurationOverride= 'Discovery'
DiscoveryPropertyOverride= 'Discovery'
SecureReferenceOverride= 'SecureReference'
}
$OverrideTable.$TypeName

}

Function Get-ReferredOverrides {
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]
[System.Xml.XmlDocument]$mpxml,
[Parameter(Mandatory=$true)]
[string]$Alias
)

$ReferredOverides = $mpxml.ManagementPack.Monitoring.Overrides.ChildNodes| where {$_.(Get-OverrideType -TypeName ($_).Name) -match "$Alias!" -or $_.Context -match "$Alias!"} | Get-UniqueXmlNode -KeyProperty 'ID'
$ReferredOverides

}

Function Remove-CurrentNode {

[CmdletBinding()]
Param(

[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[System.Xml.XmlElement]$Node

)
Process {

$Node.ParentNode.RemoveChild($Node) | Out-Null
Write-Verbose "Deleting node $($_.ID)"
}
} 

Function Get-UniqueXmlNode {
[CmdletBinding()]
Param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[System.Xml.XmlElement]$Node,
[Parameter(Mandatory=$true)]
[string]$KeyProperty


)
Begin {
[System.Collections.ArrayList]$KeyProperties=@()

}
Process {

if($KeyProperties -notcontains $_."$KeyProperty") {

$KeyProperties.Add($_."$KeyProperty") | Out-Null
$_

}

}

}

Function Test-Rerefence {

[Cmdletbinding()]
Param(
[Parameter(Mandatory = $true)]
[xml]$mpxml,
[string]$Alias
)
$mpxml.ManagementPack.InnerXml -match "$Alias!"
}

Function Get-MPReference {

[Cmdletbinding()]
Param(
[Parameter(Mandatory = $true)]
[xml]$mpxml,
[string]$Alias
)

(Select-Xml -Xml $mpxml -XPath "//ManagementPack/Manifest/References/Reference[@Alias='$Alias']").Node

}

[xml]$mpxml = Get-Content -Path $MPXmlPath

$ReferenceAliases = Get-ReferenceAlias -RegexMatchText $AliasRegex -mpxml $mpxml

$referredOverrides = Foreach ($ReferenceAlias in $ReferenceAliases) {

    Get-ReferredOverrides -mpxml $mpxml -Alias $ReferenceAlias.Alias 

}

$UniqueReferredOverrides = $referredOverrides | Get-UniqueXmlNode -KeyProperty 'ID' 

Write-Verbose "Found $($UniqueReferredOverrides.Count) unique overrides to remove."

Foreach($UniqueReferredOverride in $UniqueReferredOverrides) {

        if ($pscmdlet.ShouldProcess("$($UniqueReferredOverride.ID)", "Removing Override"))
        {

            $UniqueReferredOverrides | Remove-CurrentNode

        }

}

$Counter = 0
Foreach ($ReferenceAlias in ($ReferenceAliases | where {-not(Test-Rerefence -mpxml $mpxml -Alias $_.Alias)})) {
        
        if ($pscmdlet.ShouldProcess("$($ReferenceAlias.Alias)", "Removing reference"))
        {
            $ReferenceAlias|Remove-CurrentNode
            $Counter++
        }
}
Write-Verbose "$($ReferenceAliases.count) number of references found. $Counter of references deleted. "

$mpxml.Save($MPXmlPath)

