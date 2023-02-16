
$vcenter = connect-viserver vcenter1

$vmnames = get-content vms07.txt
$vms = get-vm $vmnames -server $vcenter
$VmsToMove = $vms #| select -first 1

$cluster = get-cluster C07 -server $vcenter
$sqlhosts = $cluster |get-vmhost
$origsqlrp = $cluster |Get-ResourcePool
$sqlRP = $origsqlrp | Where-Object { $_.name -ne $origsqlrp[1] }

foreach ($vm in $VmsToMove)
{
	#$backupNic = ($vm.NetworkAdapters|?{$_.networkname -like "*Backup"})
	#$newBackupPg = Get-VDPortgroup -Name $(($vm.NetworkAdapters|?{$_.networkname -like "*Backup"}).networkname.split("Backup")[0] + "Bkp")
	#Set-NetworkAdapter -NetworkAdapter $backupNic -Portgroup $newBackupPg -confirm:$false
	
	$DataDatastores = Get-DatastoreCluster -server $vcenter "migration" |get-datastore|sort freespacegb -Descending|select -first 5
	$vmhost = $sqlhosts[(Get-Random)%9]
	$disks = get-harddisk $vm
	$OSDatastore = Get-DatastoreCluster -server $vcenter "migration" |get-datastore|sort freespacegb -Descending|select -Index ((get-random)%5)
	$OSDisk = $disks|select -first 1
	$DataDisks = $disks|select -skip 1
	$spec = New-Object VMware.Vim.VirtualMachineRelocateSpec
	$spec.datastore = $OSDatastore.extensiondata.moref
	$spec.host = $vmhost.extensiondata.moref
    $vmhost.extensiondata.moref
	$spec.pool = $sqlRP.extensiondata.moref
    $sqlRP.extensiondata.moref
    $spec.pool
     
	$diskObj = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
	$diskObj.diskId = $OSdisk|%{$_.id.split('/')[1]}
	$diskObj.datastore = $OSDatastore.extensiondata.moref
	$spec.disk += $diskObj

	$DSFreeSpace = @{}
	foreach ($ds in $DataDatastores)
	{
		$DSFreeSpace.add($ds.name,$ds.freespacegb)
	}
	foreach ($vmdk in $DataDisks)
	{
		$ValidDestinationDS = $DSFreeSpace.GetEnumerator() |? {$_.value * .8 -gt $vmdk.capacityGB}
		$DSName = $(($ValidDestinationDS.GetEnumerator()| select -Index ((get-random)%($ValidDestinationDS.count))).name)

		$DestDS = $DataDatastores| ?{$_.name -like $DSName}

		$DSFreeSpace.Set_Item($DSName,$DSFreeSpace[$DSName]- $vmdk.capacityGB)

		$diskObj = New-Object VMware.Vim.VirtualMachineRelocateSpecDiskLocator
		$diskObj.diskId = $vmdk|%{$_.id.split('/')[1]}
		$diskObj.datastore = $DestDS.extensiondata.moref

		$spec.disk += $diskObj
	}

$vm.extensionData.relocateVM($spec, "defaultPriority")


}
	

