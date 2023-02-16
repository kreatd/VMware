<#
.SYNOPSIS

#>
Param(
  [Parameter(Mandatory=$true)]
  [string]$vcenter = $(throw "vCenter Required."),
  [Parameter(Mandatory=$true)]
  [string]$destvmcluster = $(throw "Destination cluster Required."),
  [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)")

)   

$destvc = connect-viserver $vcenter
$vmnames = import-csv $path -header "name"
$VMsToMove = get-vm $vmnames.name -server $destvc

#source host where all vms will be migrated to
$destcluster = get-cluster -name $destvmcluster -server $destvc 

#source datastore where all vms will be migrated to
$hosts= $destcluster| get-vmhost 
$NumOfHosts = $hosts.count

foreach ($item in $VMsToMove)
{
$destDatastore = $destcluster | get-datastore -server $destvc | where-object { $_.name -like "*VMP*" -and $_.name -notlike "*Templates*"} |sort-object freespacegb -Descending|select-object -first 1
$vmhost = $hosts| select -Index ((get-random)%$NumOfHosts)

#get vm to work with
$vm = get-vm $item.name -server $destvc
#blank out the nics variable and get all network adapters to reconfigure
$nics=""
$nics = $vm | get-networkadapter

    $exportedpgs=@()
    $allpgs=get-virtualportgroup -vmhost $vmhost -Server $destvc| where {$_.name -like "*Bkp-LAG" -or $_.name -like "dc1-Isolated-ge"}

    foreach($nic in $nics)
    {
       $exportedpgs+=$allpgs | where {$_.name -eq $nic.NetworkName + '-Lag'}
       $exportedpgs+=$allpgs | where {$_.name -eq "dc1-Isolated-Nge" -and $nic.NetworkName -notlike "*Bkp"}
    }

      move-vm -VM $vm -Destination $vmhost -Datastore $destDatastore -NetworkAdapter $nics -PortGroup $exportedpgs -confirm:$false
      
      get-vm $vm | get-networkadapter | where {$_.networkname -eq "dc1-Isolated-Nge"} | set-networkadapter -networkname "Nge_VM" -confirm:$false

}
  disconnect-viserver $vcenter -force -confirm:$false
