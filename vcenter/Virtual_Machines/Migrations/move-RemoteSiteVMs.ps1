<#
.SYNOPSIS
 
.DESCRIPTION
Important requirements:  vSwitches with the same name must be setup at both locations along with all of the same port group naming (be sure to have -vsw attached to the end of each port group.)
Also, this only works with moving VMs to VSAN (so far).

.PARAMETER <Parameter_Name>
  $sourcevcenter: Source vCenter FQDN
  $destvcenter: Destination vCenter FQDN
  $sourcehost: Source Host
  $destvmhost: Destination Host
  $switch: Destination vSwitch (must match the name of the source vswitch)
  $path: Path to the CSV that contains the vmnames of all the VMs to be used for the Migration.
.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  2019.12.05
  Purpose/Change: Initial script development
.EXAMPLE

./move-RemoteSiteVMs.ps1  -sourcevcenter "" -destvcenter """ -sourcehost "" -destvmhost "" `
-switch "vSwitch0" -path "C:\path\to\file.csv"
#>
Param(
  [Parameter(Mandatory=$true)]
  [string]$destvcenter = $(throw "Destination vCenter Required."),
  [Parameter(Mandatory=$true)]
  [string]$sourcevcenter = $(throw "Source vCenter Required."),
  [Parameter(Mandatory=$true)]
  [string]$sourcehost = $(throw "Source host Required."),
  [Parameter(Mandatory=$true)]
  [string]$destvmhost = $(throw "Destination host Required."),
  [Parameter(Mandatory=$true)]
  [string]$switch = $(throw "vswitch Required."),
  [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)")

)
$srcvc = connect-viserver $sourcevcenter     
$destvc = connect-viserver $destvcenter
$vmnames = import-csv $path -header "name"
$VMsToMove = get-vm $vmnames.name -server $srcvc
#source host where all vms will be migrated to
$desthost = get-vmhost -name $destvmhost -server $destvc 
#source datastore where all vms will be migrated to
$destDatastore = $desthost | get-datastore -server $destvc | where-object { $_.name -like "*VSAN"}

foreach ($item in $VMsToMove)
{
#get vm to work with
$vm = get-vmhost -name $sourcehost -server $srcvc | get-vm $item.name -server $srcvc
#blank out the nics variable and get all network adapters to reconfigure
$nics=""
$nics = $vm | get-networkadapter

foreach($nic in $nics)
    {
      #convert vmnics from distributed to standard
      get-vm $nic.parent -server $srcvc | get-networkadapter -name $nic.name | set-networkadapter -NetworkName ($nic.NetworkName + '-vsw') -confirm:$false
      start-sleep -s 2
    }

    $vm = get-vm $item.name -server $srcvc
    $newnics = $vm | get-networkadapter -Server $srcvc
    #Grab Port Groups from destination standard switch
    $exportedpgs=@()
    $allpgs=get-virtualportgroup -virtualswitch $switch -vmhost $desthost -Server $destvc| where {$_.name -like "*"}

    #Select Port Groups that are currently in use by the VM (that are available on the destination host's standard switch).
    foreach($nic in $newnics)
    {
       $exportedpgs+=$allpgs | where {$_.name -eq $nic.NetworkName}
    }

  #migrate vm from source vcenter to destination vcenter
  move-vm -VM $vm -Destination $desthost -Datastore $destDatastore -DiskStorageFormat Thin -NetworkAdapter $newnics -PortGroup $exportedpgs -confirm:$false

  $destvm = get-vm $item.name -server $destvc
  $newnics = $destvm | get-networkadapter -Server $destvc
  foreach($nic in $newnics)
    {
      #convert vmnics from standard to distributed
      get-vm $nic.parent -server $destvc | get-networkadapter -name $nic.name | set-networkadapter -NetworkName ($nic.networkname -replace '-vsw',"") -confirm:$false
      start-sleep -s 2
    }
  #list hosts that are in the destination vcenter and select a random one minus the host configured for the migrations
  $hosts = get-vmhost -server $destvc | where {$_.name -ne $desthost}
  $RandomHost = $hosts |select -Index ((get-random)%$hosts.length)

  #migrate vm from jump host to one of the other non-standard switch configured hosts
  move-vm -VM $destvm -Destination $RandomHost -confirm:$false

}
  disconnect-viserver $srcvc,$destvc -force -confirm:$false
