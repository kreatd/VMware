param(
	[Parameter(Mandatory=$true)][string] $Cluster,
	[Parameter(Mandatory=$true)][string] $SourceDSCluster,
	[Parameter(Mandatory=$true)][string] $DestinationDSCluster,
	[int] $NumDatastores = $NULL
)

function reset-sdrsaffinity ($dsc)
{
	$storMgr = Get-View StorageResourceManager
	$spec = New-Object VMware.Vim.StorageDrsConfigSpec
	$VMaffinity = $dsc.ExtensionData.PodStorageDrsEntry.StorageDrsConfig.PodConfig.DefaultIntraVmAffinity
	get-vm -Datastore $dsc |%{              
		$vmEntry = New-Object VMware.Vim.StorageDrsVmConfigSpec            
		$vmEntry.Operation = "add"            
		$vmEntry.Info = New-Object VMware.Vim.StorageDrsVmConfigInfo            
		$vmEntry.Info.Vm = $_.ExtensionData.MoRef
		$vmEntry.Info.IntraVmAffinity = $VMaffinity
		$spec.vmConfigSpec += $vmEntry
	}              
	$storMgr.ConfigureStorageDrsForPod($dsc.ExtensionData.MoRef,$spec,$true)
}
$start = get-date
write-output "Start time: $start"

#--------------------------------------------------------------------------------------

$olddscluster = get-datastorecluster $SourceDSCluster
$newdscluster = get-datastorecluster $DestinationDSCluster
$vmhosts = get-cluster $Cluster|get-vmhost|sort name|?{$_.connectionstate -eq "Connected"}|select -last 4
if ($numdatastores){
	$datastores = $olddscluster|get-datastore|sort name|?{$_.state -eq "Available"} | select -first $numdatastores
}
else{
	$datastores = $olddscluster|get-datastore|sort name|?{$_.state -eq "Available"}
}
$i = 0
foreach ($ds in $datastores)
{
	$ds|move-datastore -destination $newdscluster
	$vms = $ds|get-vm
#	move-vm -vm $vms -destination $vmhosts[$($i%$($vmhosts.count))] -confirm:$false
	reset-sdrsaffinity $newdscluster
	$ds|set-datastore -MaintenanceMode $TRUE -runasync
	while ($ds.state -ne "Maintenance")
	{
		$task = (get-task -status running|?{($_.name -like "Enter SDRS*") -and ($_.objectid -eq $ds.id)})
		if ($task){
			if ((get-task -status running|?{($_.name -eq "Apply recommendations for SDRS maintenance mode") -and ($_.objectid -eq $ds.extensiondata.parent.tostring())}))
			{Write-output "Waiting for $($ds.name) to enter maintenance mode..."}
			else{
				$task|stop-task -confirm:$false
				$ds|set-datastore -MaintenanceMode $TRUE -runasync}
		}
		else{$ds|set-datastore -MaintenanceMode $TRUE -runasync	}
		start-sleep 120
		$ds = get-datastore $ds
		$i++
	}
	$ds|move-datastore -destination $olddscluster
	
}

$end = get-date
$runtime = "{0:hh\:mm}" -f $($end - $start)
write-output "Run time: $runtime"

