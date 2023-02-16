<#
.SYNOPSIS
  Script takes parameters and completes a move-vm based off those parameters
  Currently setup to only work from a mclag configured cluster to a nonmclag configured cluster


.DESCRIPTION
  Script receives destination cluster and vm name based off input and uses that to migrate the vm.

.PARAMETER <Parameter_Name>
  $destvmcluster : destination cluster
  $path: enter path to vm input csv
  $venter: vCenter FQDN
  $destvmportgroup: Name of destination portgroup

.NOTES
  Version:        1.0
  Author:         Daniel Kreatsoulas
  Creation Date:  9/8/2020
  Purpose/Change: Initial script development


.EXAMPLE
  .\move-VMs_SDN_To_Non_SDN.ps1 -vcenter "vcenter2" -destvmcluster C16 -path "path/to/csv/file.csv" -destvmportgroup enternameofprodpg `

#>
Param(
  [Parameter(Mandatory=$true)]
  [string]$vcenter = $(throw "vCenter Required."),
  [Parameter(Mandatory=$true)]
  [string]$destvmcluster = $(throw "Destination cluster Required."),
  [Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)"),
  [string]$destvmportgroup = $(throw "destination production nic port group required.")

)   

$destvc = connect-viserver $vcenter
$vmnames = import-csv $path -header "name"
$VMsToMove = get-vm $vmnames.name -server $destvc

#source host where all vms will be migrated to
$destcluster = get-cluster -name $destvmcluster -server $destvc 

#source datastore where all vms will be migrated to
$hosts= $destcluster| get-vmhost 
$NumOfHosts = $hosts.count
function move-VMs_SDN_To_Non_SDN(){
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
    $allpgs=get-virtualportgroup -vmhost $vmhost -Server $destvc #| where {$_.name -like "*Bkp-LAG" -or $_.name -like "dc1-Isolated-Nuage"}

    foreach($nic in $nics)
    {
       $exportedpgs+=$allpgs | where {$_.name -eq ($nic.NetworkName -replace '-LAG')}
       $exportedpgs+=$allpgs | where {$_.name -eq $destvmportgroup -and ($nic.NetworkName -replace '-LAG') -notlike "*Bkp"}
    }

     move-vm -VM $vm -Destination $vmhost -Datastore $destDatastore -NetworkAdapter $nics -PortGroup $exportedpgs -confirm:$false

}

}

try {


    move-VMs_SDN_To_Non_SDN
}
catch{

    write-output $_.Exception.Message`n
}
disconnect-viserver $vcenter -force -confirm:$false