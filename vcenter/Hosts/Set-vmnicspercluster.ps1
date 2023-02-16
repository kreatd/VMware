<#
.SYNOPSIS
	This script will add or remove vmnics to make it easier to troubleshoot new cluster configs

.DESCRIPTION
	Enter in the provided parameters and if it's your first time running the script, I'd recommend that you test it in the sandbox
.PARAMETER NONE
$vCenter -vcenter vcenter2
$cluster -cluster C20
$vmnics -vmnics vmnic0,vmnic1,vmnic4
$addremove -addremove remove

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  06/21/2019
  Purpose/Change: Initial script development

  Update Date:

.EXAMPLE

  ./set-vmnicspercluster.ps1 -vcenter vcenter3 -cluster C93 -vmnics vmnic4 -addremove remove

#>

param( 
[Parameter(Mandatory=$true)] 
[string] $vCenter = $(throw "vCenter is required."),   
[Parameter(Mandatory=$true)] 
[string] $cluster = $(throw "cluster is required"),
[Parameter(Mandatory=$true)] 
$vmnics = $(throw "vmnic list is required."),
[Parameter(Mandatory=$true)] 
[string] $addremove = $(throw "You must choose whether or not you're adding or removing nics?.")

)  

function addVMnics($esxName,$vdsName,$upLinkNames,$vmnics)
{
  
  
  $esx = Get-VMHost -Name $esxName
  
  $vds = Get-VDSwitch -Name $vdsName -VMHost $esx
  
  $uplinks = Get-VDPort -VDSwitch $vds -Uplink | where {$_.ProxyHost -like $esxName}
  
   
  
  $netSys = Get-View -Id $esx.ExtensionData.ConfigManager.NetworkSystem
  
  $hostNetworkConfig = New-Object VMware.Vim.HostNetworkConfig
  
   
  
  $proxy = New-Object VMware.Vim.HostProxySwitchConfig
  
  $proxy.Uuid = $vds.ExtensionData.Uuid
  
  $proxy.ChangeOperation = [VMware.Vim.HostConfigChangeOperation]::edit
  
  $proxy.Spec = New-Object VMware.Vim.HostProxySwitchSpec
  
  $proxy.Spec.Backing = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
  
   
  
  for($i=0;$i -lt $upLinkNames.length;$i++){
  
      $pnic = New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
      $pnic.PnicDevice = $vmnics[$i]
      $pnic.UplinkPortKey = $uplinks | where{$_.Name -eq $upLinkNames[$i]} | Select -ExpandProperty Key
  
   
  
      $proxy.Spec.Backing.PnicSpec += $pnic
  
  }
  
   
  
  $hostNetworkConfig.ProxySwitch += $proxy
  
   
  
  $netSys.UpdateNetworkConfig($hostNetworkConfig,[VMware.Vim.HostConfigChangeMode]::modify)

}
connect-viserver $vCenter


if($addremove -eq "add")
{
  $config = Read-Host -Prompt "Please enter in the config of your hosts, type in mclag or standard"
  if($config -eq "mclag")
  {
    $upLinkNames = Read-Host -Prompt "Please enter the name of all your mclag uplinks (ex. MC-LAG-0,MC-LAG-1,MC-LAG-2,MC-Lag-3)"
    $upLinkNames=$upLinkNames.Split(',')
    $vdsName = Read-Host -Prompt "Please enter in the name of your DVS that you're connecting to."
    $vmhosts=get-cluster $cluster | get-vmhost | sort -property name
    for($i=0;$i -lt $vmhosts.length;$i++){
      $esxName=$vmhosts[$i].name
    addVMnics -esxName $esxName -vdsName $vdsName -upLinkNames $upLinkNames -vmnics $vmnics
    }
  }

  

  else{
    $dswitch = Read-Host -Prompt "Please enter in the name of the Distributed Switch that you're going to add host vmnics to"
    $addnics=get-cluster $cluster | get-vmhost | Get-VMHostNetworkAdapter -physical -name $vmnics 
    Get-VDSwitch $dswitch | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $addnics -Confirm:$False
  }
}

if($addremove -eq "remove")
{

get-cluster $cluster | get-vmhost | Get-VMHostNetworkAdapter -physical -name $vmnics | Remove-VDSwitchPhysicalNetworkAdapter -Confirm:$False

}






disconnect-viserver $vcenter -Confirm:$False



