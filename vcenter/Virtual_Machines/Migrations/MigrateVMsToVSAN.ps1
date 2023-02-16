<#
.SYNOPSIS
  Script takes parameters and completes a migration to destination vsan cluster


.DESCRIPTION
  Enter vcenter, cluster and input vm list.csv and uses that to migrate the vm to the destination cluster

.PARAMETER <Parameter_Name>
    $vCenterName :  vcenter 
    $ClusterName : destination cluster
    $path: Path for input csv 

.NOTES
  Version:        1.0
  Author(s):         Daniel Kreatsoulas 
  Creation Date:  08/16/2018
  Purpose/Change: Initial script development
********************* Currently does not support cross-vCenter migration *********************

.EXAMPLE
./MigrateVMsToVSAN.ps1  -vCenterName (enter in vcenter) -ClusterName (enter in cluster that you're migrating to) -path C:\path\to\file.csv
#>



param(
[Parameter(Mandatory=$true)] [string] $vCenterName = $(Read-Host -prompt "vCenter server name needed"),
[Parameter(Mandatory=$true)] [string] $ClusterName = $(Read-Host -prompt "vCenter Cluster Object needed"),
[Parameter(Mandatory=$true)] [string] $path = $(Read-Host -prompt "Enter path of csv for input (C:\path\to\file.csv)")
)

$vcenter = connect-viserver $vCenterName
$vmnames = import-csv $path -header "name"
$hosts = get-cluster $ClusterName | get-vmhost 
$NumOfHosts = $hosts.count
###Modify $vmnames.ModifyMe if you have a different column header than name....
$VMsToMove = get-vm $vmnames.name -server $vcenter
$Datastore = get-cluster $ClusterName | Get-datastore | where {$_.name -match "VSAN"}
$StoragePolicy = Get-VsanClusterConfiguration -Cluster $ClusterName | select StoragePolicy

foreach ($vm in $VMsToMove)
{

$MoveToHosts = $hosts |select -Index ((get-random)%$NumOfHosts)
Move-VM -vm $vm.name -Destination $MoveToHosts -Datastore $Datastore -DiskStorageFormat Thin | set-spbmentityconfiguration -StoragePolicy $StoragePolicy.StoragePolicy.Name
get-vm $vm.name | get-harddisk  | set-spbmentityconfiguration -StoragePolicy $StoragePolicy.StoragePolicy.Name
}

##############################################
# HANDY FUNCTIONS (THAT WORK) FOR THE FUTURE!#
##############################################


Function get-GrantedMemory{
$output=@()
ForEach($vmhost in $vmhosts)
{
$stat=get-stat -entity $vmhost -stat mem* -realtime
$Objects = New-Object PSObject -Property ([ordered]@{
Name=$vmhost.name
GrantedGB=$granted=”{0:N2}” -f (($stat |Where-Object{$_.metricid -like  “mem.granted.average”}|select -expand value -first 1)/1MB)
})
$output+= $objects
}
$output
}


Function get-AllocatedCpus{
foreach ($vmhost in $vmhosts){
    $vms = $vmhost | Get-VM | where{$_.PowerState -eq 'PoweredOn'}
    $vmsVcpucount= ($vms | Measure-Object -Property numcpu -Sum).sum
    ""|Select @{N='Host';E={$vmhost.name}},@{N='Logical Processors Allocated (vCPUs)';E={$vmsVcpucount}}
    }
    }