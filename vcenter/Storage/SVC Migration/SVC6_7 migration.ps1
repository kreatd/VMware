param(
	[Parameter(Mandatory=$true)][string] $Cluster,
	[Parameter(Mandatory=$true)][string] $DSClusterName,
	[Parameter(Mandatory=$true)][int] $NumDatastores
)
#$cluster = "C01"
#$numDatastores = 27
#$DSClusterName = "C01"
$start = get-date
write-output "Start time: $start"

#--------------------------------------------------------------------------------------
# 

$dscluster = get-datastorecluster $DSClusterName
$datastores = $dscluster | get-datastore|sort name|?{$_.state -eq "Available"}|select -first $numDatastores

$i = 0
foreach ($ds in $datastores)
{
	$vms = $ds|get-vm

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
}

$end = get-date
$runtime = "{0:hh\:mm}" -f $($end - $start)
write-output "Run time: $runtime"
