[CmdletBinding(
    SupportsShouldProcess = $true
)]
Param(
$ManagementServers = @('ms1.contoso.com','ms2.contoso.com','ms3.contoso.com')

)
$SetRegistryKeys = {

    $RegistryBestPractices = @(
        @{RegistryName='Persistence Checkpoint Depth Maximum';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters';RegistryValue = '104857600';Type='DWord'}
        @{RegistryName='State Queue Items';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters';RegistryValue = '20480';Type='DWord'}
        @{RegistryName='PoolLeaseRequestPeriodSeconds';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters\PoolManager';RegistryValue = '600';Type='DWord';'InvoleMSSupport' = $true}
        @{RegistryName='PoolNetworkLatencySeconds';Path = 'HKLM:\system\CurrentControlSet\Services\HealthService\Parameters\PoolManager';RegistryValue = '120';Type='DWord';'InvoleMSSupport' = $true}
        @{RegistryName='GroupCalcPollingIntervalMilliseconds';Path = 'HKLM:SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\';RegistryValue = '900000';Type='DWord'}
        @{RegistryName='Command Timeout Seconds';Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse';RegistryValue = '1800';Type='DWord'}
        @{RegistryName='Deployment Command Timeout Seconds';Path = 'HKLM:\SOFTWARE\Microsoft\Microsoft Operations Manager\3.0\Data Warehouse';RegistryValue = '86400';Type='DWord'}
        @{RegistryName='DALInitiateClearPool';Path = 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL\';RegistryValue = '1';Type='DWord'}
        @{RegistryName='DALInitiateClearPoolSeconds';Path = 'HKLM:\SOFTWARE\Microsoft\System Center\2010\Common\DAL\';RegistryValue = '60';Type='DWord'}
)


Foreach ($RegistryBestPractice in $RegistryBestPractices) {

    if (test-path -Path $RegistryBestPractice.Path) {
        if ($pscmdlet.ShouldProcess("$($RegistryBestPractice.Path)\$($RegistryBestPractice.RegistryName):$($RegistryBestPractice.RegistryValue)", "Setting Value"))
        {
            Set-ItemProperty -Path $RegistryBestPractice.Path -Name $RegistryBestPractice.RegistryName -Value $RegistryBestPractice.RegistryValue  -type
        }

    
    } else {
        if ($pscmdlet.ShouldProcess("$($RegistryBestPractice.Path)\$($RegistryBestPractice.RegistryName):$($RegistryBestPractice.RegistryValue)", "Creating Key and Setting Value"))
        {
        
            New-Item -Path $RegistryBestPractice.Path -Force
            Set-ItemProperty -Path $RegistryBestPractice.Path -Name $RegistryBestPractice.RegistryName -Value $RegistryBestPractice.RegistryValue  -type
        }
    }

}

}


Invoke-Command -ComputerName $ManagementServers -ScriptBlock $SetRegistryKeys 
