<#
.DESCRIPTION
	This script will shutdown all VMs and place all hosts in maintenance mode (using posh-ssh).
.NOTES
Posh-SSH needs to be installed to run this script.  Also, you should run this from powershell 5 because POSH-SSH only works in powershell 5 (currently).
.EXAMPLE
Use at your own risk.  This script has not been tested in production.  I've verified that every piece of the code works, but I have not used it in prod.
./vSAN-Shutdown.ps1 -vcenter "vcenter name" -cluster "cluster name"
#>
param(
    [string[]] $vcenter,
    [string] $cluster
    )
function ShutdownVSAN($vcenter,$cluster){

    #turn on SSH so that we can connect later.
    $vmhosts = get-cluster $cluster | get-vmhost
    foreach($vmhost in $vmhosts){
    Get-VMHostService -vmhost $vmhost | where {$psitem.key -eq "tsm-ssh"} | Start-VMHostService -confirm:$false
    }
    #shutdown All VMs with exception to vcsa
    $ShutdownVMs = get-cluster -name $cluster -server $vcenter | get-vm | where {$_.name -notlike "vc-*"} | Shutdown-VMGuest -Confirm:$False
    
    #powerstate check.
    while($ShutdownVMs.powerstate -eq "PoweredOn"){
    write-output "Waiting for VMs to power off...."
    $ShutdownVMs = get-cluster -name $cluster -server $vcenter | get-vm | where {$_.name -notlike "vc-*"}
    }

    write-output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    write-output "All VMs (with exception to the VCSA) have been shutdown."
    write-output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

    #check for resyncing components
    $vSANResync = Get-VsanResyncingComponent -Cluster $cluster
    while($NULL -ne $vSANResync){
    write-output "Waiting on resyncing components...."
    $vSANResync = Get-VsanResyncingComponent -Cluster $cluster
    }

    #shutdown vcsa
    get-cluster -name $cluster -server $vcenter | get-vm | where {$_.name -like "vc*"} | Shutdown-VMGuest -Confirm:$False

    #verify that the vcsa is shutdown
    if($vcenter -notmatch "domainnamevc"){
        $vcenter = $vcenter + "domainnameofvc"
    }
    Do{
        $ping = test-connection $vcenter -quiet
        write-output "Waiting for $($vcenter) to go offline..."
    }until($Ping -contains $false) 
        write-output "$($vcenter) is now offline."
        
    #I wanted to avoid using POSH-SSH, but given my time constraints, I went with the solution that works.  I believe we can now use the ssh command within the latest version of powershell.
    write-output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    write-output "Enter in the esxi root password."
    $Secure = Read-Host -AsSecureString
    $cred = New-Object System.Management.Automation.PSCredential("root",$Secure)
    foreach ($vmhost in $vmhosts) {
    $ssh = New-SSHSession -ComputerName $vmhost -Credential $cred -AcceptKey -KeepAliveInterval 5
    write-output "Executing Command on $vmhost"
    Invoke-SSHCommand -SessionId $ssh.SessionId -Command "esxcli system maintenanceMode set -e true -m noaction" -TimeOut 30 | select -ExpandProperty Output
    write-output "Ending SSH Session on $vmhost"
    Remove-SSHSession -SessionId $ssh.SessionId | Out-Null
    }
    write-output "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    write-output "Once you've verified that all hosts are in maintenance mode (Log into every esxi host vami to confirm), shut every host down at the same time."
    write-output "Do not forget to disable ssh once you power the hosts back on."


}
connect-viserver $vcenter -confirm:$false
ShutdownVSAN -vcenter $vcenter -cluster $cluster