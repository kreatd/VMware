param(
	[Parameter(Mandatory=$true)][string] $DSClusterName
)
$dscluster = get-datastorecluster $DSClusterName
$datastores = $dscluster | get-datastore|sort name|?{$_.state -eq "Maintenance"}|select
move-datastore $datastores -Destination "DS_Remove"
