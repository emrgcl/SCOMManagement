[CmdletBinding()]
Param(
    
    [Parameter(Mandatory = $true)]
    [string[]]$ServerList,
    [Parameter(Mandatory = $true)]
    [string]$ManagementServer,
    [string]$ManagementGroupName = 'SCOM2012MG',
    [int32]$Port=5723,
    [Switch]$DontFixManagementServer
)

$ScriptBlock = {
   
    $VerbosePreference = $Using:VerbosePreference

    try {
    
        $Agent = New-Object -ComObject AgentConfigManager.MgmtSvcCfg -ErrorAction Stop

    
    } 
    
    Catch {
    
    Throw "Could not load Agent ComObject. Possibly Agent is not installed."
    
    }
    
    try {
        
        $ManagementGroup = $Agent.GetManagementGroup($Using:ManagementGroupName)
        Write-Verbose "CurrentManagementServer:$($ManagementGroup.ManagementServer) Requested ManagementServer: $($using:ManagementServer), ManagementGroup: $($Using:ManagementGroupName)"
         # If management server is not same, remove management grop and fix
        if ($ManagementGroup.ManagementServer -ne $using:ManagementServer -and !($DontFixManagementServer)) {
        Write-Verbose "$Using:ManagementGroupName is connected to $($ManagementGroup.ManagementServer). Fixing it to connect to $($using:ManagementServer)"
        $Agent.RemoveManagementGroup($using:ManagementGroupName)
        Restart-Service -Name HealthService -Force
        $Agent.AddManagementGroup($Using:ManagementGroupName, "$Using:ManagementServer",$using:Port)    
        Restart-Service -Name HealthService -Force
        
        } 
        
        else {
        
        Write-verbose "$($using:ManagementGroupName) already exists on $($Env:ComputerName)"
        
         
         }
    } 
    
    catch [System.IO.IOException] {
       
        Write-Verbose "Did not find $($Using:ManagementGroupName). Adding it."
        $Agent.AddManagementGroup($Using:ManagementGroupName, "$Using:ManagementServer",$using:Port)    
        Restart-Service -Name HealthService -Force
    
    }
    catch {
    
    throw $_

    }

}

Invoke-Command -ComputerName $ServerList -ScriptBlock $ScriptBlock
