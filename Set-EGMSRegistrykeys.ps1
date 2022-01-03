[CmdletBinding(
    SupportsShouldProcess = $true
)]
Param(
$ManagementServers = @('ms1.contoso.com','ms2.contoso.com','ms3.contoso.com'),
[Switch]$SetCriticalKeys
)

$SetRegistryKeys = {
    [CmdleTBinding(SupportsShouldProcess = $true)]
    Param()

    $WhatIfPreference=$using:WhatIfPreference
    $ConfirmPreference=$using:ConfirmPreference
    $SetCriticalKeys=$using:SetCriticalKeys

    $RegistryBestPractices = @(
        @{RegistryName='Persistence Checkpoint Depth Maximum';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters';RegistryValue = '104857600';Type='DWord'}
        @{RegistryName='State Queue Items';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters';RegistryValue = '20480';Type='DWord'}
        @{RegistryName='PoolLeaseRequestPeriodSeconds';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters\PoolManager';RegistryValue = '600';Type='DWord';'IsCritical' = $true}
        @{RegistryName='PoolNetworkLatencySeconds';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters\PoolManager';RegistryValue = '120';Type='DWord';'IsCritical' = $true}
        @{RegistryName='GroupCalcPollingIntervalMilliseconds';Path = 'HKLM:SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\';RegistryValue = '900000';Type='DWord'}
        @{RegistryName='Command Timeout Seconds';Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse';RegistryValue = '1800';Type='DWord'}
        @{RegistryName='Deployment Command Timeout Seconds';Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse';RegistryValue = '86400';Type='DWord'}
        @{RegistryName='DALInitiateClearPool';Path = 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL\';RegistryValue = '1';Type='DWord'}
        @{RegistryName='DALInitiateClearPoolSeconds';Path = 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL\';RegistryValue = '60';Type='DWord'}
)


Foreach ($RegistryBestPractice in $RegistryBestPractices) {

   if (test-path -Path $RegistryBestPractice.Path) {
        if ($pscmdlet.ShouldProcess("$($Env:ComputerName) =>>> $($RegistryBestPractice.Path)\$($RegistryBestPractice.RegistryName):$($RegistryBestPractice.RegistryValue)", "Setting Value"))
        {
                if ((-not $RegistryBestPractice.IsCritical -or $SetCriticalKeys) -or ($RegistryBestPractice.IsCritical -and $SetCriticalKeys) ) {
                
                    Set-ItemProperty -Path $RegistryBestPractice.Path -Name $RegistryBestPractice.RegistryName -Value $RegistryBestPractice.RegistryValue  -type $RegistryBestPractice.Type
               
                }
            
            
        }

    
    } else {
        if ($pscmdlet.ShouldProcess("$($Env:ComputerName) =>>> $($RegistryBestPractice.Path)\$($RegistryBestPractice.RegistryName):$($RegistryBestPractice.RegistryValue)", "Creating Key and Setting Value"))
        {
            if ((-not $RegistryBestPractice.IsCritical -or $SetCriticalKeys) -or ($RegistryBestPractice.IsCritical -and $SetCriticalKeys) ) {
                New-Item -Path $RegistryBestPractice.Path -Force | Out-Null
                Set-ItemProperty -Path $RegistryBestPractice.Path -Name $RegistryBestPractice.RegistryName -Value $RegistryBestPractice.RegistryValue  -type $RegistryBestPractice.Type
            }
        }
    }

}

}


Invoke-Command -ComputerName $ManagementServers -ScriptBlock $SetRegistryKeys 
