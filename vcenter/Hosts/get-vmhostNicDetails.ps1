
$vcenter = connect-viserver "vcenter2"
$vmhosts = get-vmhost -server $vcenter
$nics = $vmhosts|Get-VMHostNetworkAdapter -Physical
$nic_data = @()
$esxclis = $vmhosts|get-esxcli

$i = 0
foreach ($vmhost in $vmhosts)
{
	write-progress -activity "Getting NIC details" -percent $($i/$vmhosts.count*100) -status "Collecting for host $($vmhost.name): $i of $($vmhosts.count)"
	$host_nics = $nics |? {$_.vmhost.name -eq $vmhost.name}
	$esxcli = $esxclis|?{$_.vmhost.name -eq $VMHost.name}
	$esxcliNics = $esxcli.network.nic.list()
	foreach ($nic in $host_nics)
	{
		$data = "" | Select VMHost, vmnic, Description, MAC, Speed
		$data.VMHost = $nic.VMHost
		$data.vmnic  = $nic.Name
		$data.Description = ($esxcliNics | where {$_.Name -match $nic.Name}).Description
		$data.MAC = $nic.Mac
		$data.Speed = $nic.BitRatePerSec
		$nic_data += $data
	}
	$i++
}

$nic_data|?{$_.speed -eq 10000}|group-object -property Description|select count, name|export-csv -notypeinformation "esxihostNICs.csv"
