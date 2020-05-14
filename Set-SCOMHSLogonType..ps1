 
 <#
 .Synopsis
 Sets scom 2019 agent to work runas accounts with either logon as a service or logon locally rights.

 .Description
 Sets scom 2019 agent to work runas accounts with either logon as a service or logon locally rights.
 Please refer to Kevin Holman at https://kevinholman.com/2019/03/14/security-changes-in-scom-2019-log-on-as-a-service/
 Plrease refer to Microsoft Documentation at https://docs.microsoft.com/en-us/system-center/scom/enable-service-logon?view=sc-om-2019.

 .Example
 PS C:\> .\Set-SCOMHSLogonType.ps1 -Verbose
 VERBOSE: Found version 10.19.10014.0 which is scom 2019. Will update/create the 'Worker Process Logon Type' under 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\'
 VERBOSE: Found 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\' . Will update the 'Worker Process Logon Type'
 VERBOSE: Restarting agent.
 
 .Example
 PS C:\temp> .\Set-SCOMHSLogonType.ps1 -LogonType 5 -Verbose
 VERBOSE: Found version 10.19.10014.0 which is scom 2019. Will update/create the 'Worker Process Logon Type' under 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\'
 VERBOSE: Found 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\' . Will update the 'Worker Process Logon Type'
 VERBOSE: Restarting agent.
 
 The above example set agent to 'Logon as Service' which is 5.

 .Example 
 PS C:> .\Set-SCOMHSLogonType.ps1 -LogonType 2 -Verbose -DontRestartAgent
 VERBOSE: Found version 10.19.10014.0 which is scom 2019. Will update/create the 'Worker Process Logon Type' under 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\'
 VERBOSE: Found 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\' . Will update the 'Worker Process Logon Type'

 .Parameter LogonType
 5 = Logon as a Service
 2 = Logon Locally
 .Parameter DontRestartAgent
 By default script restart agent. Override with this paremeter not to do so.
 #>
 
 [CmdletBinding()]
 Param(
 [string]$FilePath = 'C:\Program Files\Microsoft Monitoring Agent\Agent\HealthService.dll',
 [string]$RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\System Center\Health Service\',
 [int32]$LogonType = 2, # defaults to logon locally
 [string]$RegKEy = 'Worker Process Logon Type',
 [switch]$DontRestartAgent
 )
 try {
    
    [version]$Version = (Get-ItemProperty -Path $FilePath  -Name VersionInfo -ErrorAction Stop).VersionInfo.FileVersion
    
}
Catch [System.Management.Automation.ItemNotFoundException] {
    
    throw "$FilePath was not found exiting script."
    
    
}


if ($Version.Major -eq 10 -and $version.minor -eq 19) {
    
    Write-Verbose "Found version $($Version.ToString()) which is scom 2019. Will update/create the '$RegKEy' under '$RegPath'"
    
    if (Test-Path -Path $RegPath) {
        
        Write-Verbose -Message "Found '$RegPath' . Will update the '$RegKEy'"
        Set-ItemProperty -Path $RegPath -Name $RegKEy -Value $LogonType -Force | Out-Null
        if (-not $DontRestartAgent) {
            Write-Verbose "Restarting agent."
            Restart-Service -Name HealthService
            
            
        }
        
        
        
    } else {
        
        Write-Verbose -Message "Did not find '$RegPath'. Will create the key first then set the '$RegKEy'"
        New-Item -Path $RegPath -Force | Out-Null
        Set-ItemProperty -Path $RegPath -Name $RegKEy -Value $LogonType -Force | Out-Null
        
        if (-not $DontRestartAgent) {
            Write-Verbose "Restarting agent."
            Restart-Service -Name HealthService
            
            
        }
    }
    
} else {
    
    Write-Verbose "Found version $($Version.ToString()) which is not scom 2019. exiting."
    
} 
